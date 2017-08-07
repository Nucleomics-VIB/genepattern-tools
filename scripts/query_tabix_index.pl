#!/usr/bin/perl

use Config;
use File::Basename;
use File::Path;
use IPC::Open3;
use IO::Select;
use IO::Handle;
use Getopt::Long;
use File::Copy;

GetOptions (\%options,	"libdir=s",
						"samtoolsDir=s",
						"input=s",
						"index=s",
						"header=i",
						"headeronly=i",
						"listchr=i",
						"reheader=s",
						"regions=s",
						"targets=s",
						"query=s"
										);

# tabix Querying and other options:
#    -h, --print-header         print also the header lines
#    -H, --only-header          print only the header lines
#    -l, --list-chroms          list chromosome names
#    -r, --reheader FILE        replace the header with the content of FILE
#    -R, --regions FILE         restrict to regions listed in the file
#    -T, --targets FILE         similar to -R but streams rather than index-jumps

# define executable with path
$tabix_exec=$options{samtoolsDir}."/tabix";

if($options{input} eq "")
{
	print STDERR "A input file must be provided";
	exit(1);
}

# index file uploaded of set name from input
$index=(defined($options{index}) ? $options{index} : $options{input}.".tbi");

# check if tabix index exists
unless(-e $index){
	die "Could not load .tbi index: $!";
}

# copy input file to current directory if not already there
$tempfile = "./".(basename($options{input}));
$indexfile = "./".(basename($options{input})).".tbi";

unless(-e $tempfile){
	copy($options{input}, $tempfile) or die "Input file copy failed: $!";
	# look for index
	copy($options{input}.".tbi", $indexfile) or die "Index file copy failed: $!";
}

unless(-e $indexfile){
	copy($options{index}, $indexfile) or die "Index file copy failed: $!";
}

$input_file = $tempfile;

#Execute tabix and capture stderr.
$cmd = $tabix_exec ;

# specify input now
$cmd .= " ".${input_file};

#######################
# start test arguments

# header only or only chr list
if ($options{headeronly} == 1) {
	$cmd .= " -H";
	$outfile .= "./".(basename($options{input}))."_header.txt";

} elsif ($options{listchr} == 1) {
	# only list chromosomes
	$cmd .= " -l";
	$outfile = "./query_results_chromosome-list.txt";

} elsif (defined($options{reheader})) {
	# replace header?
	$cmd .= " -r $options{reheader}";
	$outfile = "./reheader_".(basename($options{input}));
	$outfile =~ s/.gz$//;

} else {
	# also output content

	# define output name
	$outfile = "./query_results_".(basename($options{input}));
	$outfile =~ s/.gz$//;
	
	# output header?
	if ($options{header} == 1) {
		$cmd .= " -h";
	}
	

	############################
	# start test provided query

	if (defined($options{regions})) {
		$regionfile = "./".(basename($options{regions}));
		unless(-e $regionfile){
			copy($options{regions}, $regionfile) or die "Region file copy failed: $!";
		}
		$cmd .= " -R $regionfile";
		$querystring = basename($regionfile, ".bed");
		chomp($querystring);
		$outfile = "./".$querystring."_".(basename($options{input}));
		$outfile =~ s/.gz$//;

	} elsif (defined($options{targets})) {
		$targetfile = "./".(basename($options{targets}));
		unless(-e $targetfile){
			copy($options{targets}, $targetfile) or die "Target file copy failed: $!";
		}
		$cmd .= " -T $targetfile";
		$querystring = basename($targetfile, ".bed");
		chomp($querystring);
		$outfile = "./".$querystring."_".(basename($options{input}));
		$outfile =~ s/.gz$//;

	} elsif (defined($options{query})) {
		$cmd .= " $options{query}";
		( $querystring = $options{query} ) =~ s/[^\p{PosixAlnum}-]/_/g;;
		$outfile = "./".$querystring."_".(basename($options{input}));
		$outfile =~ s/.gz$//;

	} else {
		die "\nNo query or BED input was specified";
	}
	##########################
	# end test provided query

}
#####################
# end test arguments

# add input file and output
$cmd .= " > ".$outfile ;

print "\nCommand: $cmd\n";
runCmd($cmd);

sub runCmd
{
    $cmd = shift;
    $Pin  = new IO::Handle;       $Pin->fdopen(10, "w");
    $Pout = new IO::Handle;       $Pout->fdopen(11, "r");
    $Perr = new IO::Handle;       $Perr->fdopen(12, "r");
    $Proc = open3($Pin, $Pout, $Perr, $cmd);

    my $sel = IO::Select->new();
    $sel->add($Perr, $Pout);

    while (my @ready = $sel->can_read)
    {
        foreach my $handle (@ready)
        {
            if (fileno($handle) == fileno($Perr))
            {
                # process has printed something on standard error
                my ($count, $data);
                $count = sysread($handle, $data, 1024);
                if ($count == 0)
                {
                    $sel->remove($handle);
                    next;
                }

                if($data =~ m/different line length in sequence/i)
                {
                    print STDERR $data;
                    print STDERR "\nPlease check that there are no blank lines in the input file";
                }
                elsif ($data =~ m/\[.+\].+/i || $data =~ m/Usage/i)  #if stderr output looks like an error message, write to stderr
                {
                    print STDERR $data;
                }
                else
                {
                    print STDOUT $data;
                }
            }
            else
            {
                # process has printed something on standard out
                my ($count, $data);
                $count = sysread($handle, $data, 1024);
                if ($count == 0)
                {
                    $sel->remove($handle);
                    next;
                }
                print STDOUT $data;
            }
        }
    }

    close($Perr);
    close($Pout);

    waitpid($pid, 0);
}
