#!/usr/bin/perl

use Config;
use File::Basename;
use File::Path;
use IPC::Open3;
use IO::Select;
use IO::Handle;
use Getopt::Long;
use File::Copy;

GetOptions (\%options,  "libdir=s",
                        "progDir=s",
                        "progName=s", # eg "samtools faidx"
                        "input=s",
                        "output=s"
                                          );

$prog_exec=$options{progDir}.$options{progName};

if($options{input} eq "")
{
    print STDERR "An input file must be provided";
    exit(1);
}

#copy input file to current directory if not already there
$ext = ($options{input} =~ m/([^.]+)$/)[0];
# create output file name and add same extension as input
$tempfile = "./".$options{output}.".".$ext;

unless(-e $tempfile){
copy($options{input}, $tempfile) or die "Copy failed: $!";
}

$input_file = $tempfile;

#Execute progName and capture stderr.
$cmd = "${prog_exec} ${input_file}";

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
