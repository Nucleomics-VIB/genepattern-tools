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
						"preset=s",
						"namec=i",
						"startc=i",
						"endc=i",
						"commentc=s",
						"skip=i",
						"zerob",
						"force"
										);

# define executable with path
$tabix_exec=$options{samtoolsDir}."/tabix";

if($options{input} eq "")
{
	print STDERR "A input file must be provided";
	exit(1);
}

#copy input file to current directory if not already there
$tempfile = "./".$options{input};

unless(-e $tempfile){
copy($options{input}, $tempfile) or die "Copy failed: $!";
}

$input_file = $tempfile;

#Execute tabix and capture stderr.
$cmd = $tabix_exec ;

# add more depending on inputs
if (defined($options{preset})) {
	# check if valid
	( map { /$options{preset}/ } ['bed', 'gff', 'sam', 'vcf'] ) ||
		print STDERR "preset can be of [bed,gff,sam,vcf]"; exit(1);
	$cmd .= " -p ".$options{preset};
} else {
	# build not-preset run

	# start is zero-based?
	if (defined $options{zerob}) {
		$cmd .= " -0";
	}

	# comment character was specified?
	if (defined $options{commentc}){
		$cmd .= " -c \"".$options{commentc}."\"";
	}

	# skip first N lines of input?
	if (defined $options{skip}){
		$cmd .= " -S ".$options{skip};
	}

	# custom run require at least $namec & $startc
	(defined($options{namec}) && defined($options{startc})) ||
		print STDERR "-namec and -startc must be provided"; exit(1);

	# build custom run
	$cmd .= "-s ".$options{namec}." -b ".$options{startc};

	# endc also provided
	if (defined($options{endc})){
		$cmd .= " -e ".$options{endc};
	}
}

# force mode?
if (defined($options{force})){
	$cmd .= " -f ";
}

# add input file and output
$cmd .= " ".${input_file};

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
