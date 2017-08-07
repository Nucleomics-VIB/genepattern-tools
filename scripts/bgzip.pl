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
						"decompress=i",
						"filter=s",
						"commentc=s",
						"force=i"
										);

# bgzip Version: 1.5
# Usage:   bgzip [OPTIONS] [FILE] ...
# Options:
#    -b, --offset INT        decompress at virtual file pointer (0-based uncompressed offset)
#    -c, --stdout            write on standard output, keep original files unchanged
#*   -d, --decompress        decompress
#*   -f, --force             overwrite files without asking
#    -h, --help              give this help
#    -i, --index             compress and create BGZF index
#    -I, --index-name FILE   name of BGZF index file [file.gz.gzi]
#    -r, --reindex           (re)index compressed file
#    -g, --rebgzip           use an index file to bgzip a file
#    -s, --size INT          decompress INT bytes (uncompressed size)
#    -@, --threads INT       number of compression threads to use [1]

# requires a working copy of grep and GNU sort (supporting natural sort order V)
# requires tabix for creating the index

# define executable with path
$bgzip_exec=$options{samtoolsDir}."/bgzip";

if($options{input} eq "")
{
	print STDERR "A input file must be provided";
	exit(1);
}

# copy input file to current directory if not already there
$tempfile = "./".(basename($options{input}));

unless(-e $tempfile){
copy($options{input}, $tempfile) or die "Copy failed: $!";
}

$input_file = $tempfile;

# decompress or compress
if ($options{decompress}==1) {

	# decompress
	$cmd=$bgzip_exec." -d -c $input_file";
	( $outfile = $tempfile ) =~ s/\.gz$//;

} else {

	# compress
	$outfile = $tempfile.".gz";
	
	defined($options{filter}) || die "Please define the sort order string (for BED data: '-k 1V,1 -k 2n,2 -k 3n,3' )";
	
	# comment character was specified?
	$comment_char = (defined($options{commentc}) ? $options{commentc} : "#");

	# sort and compress
	$cmd="( grep \^\[$comment_char\] $input_file; grep \^\[\^$comment_char\] $input_file \| sort $options{filter} ) \| $bgzip_exec -c ";
}

# force mode?
if ($options{force}==1){
	$cmd .= " -f ";
}
	
# add input file and output
$cmd .= " > ".$outfile;

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
