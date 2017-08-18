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
						"progDir=s",
						"bam=s",
						"gtf=s",
						"id=s",
						"out=s",
						"p=s",
						"pe",
						"so",
						"type=s"
										);

# usage: qualimap comp-counts [-a <arg>] -bam <arg> -gtf <arg> [-id <arg>] [-out
#        <arg>] [-p <arg>] [-pe] [-s] [-type <arg>]
#  -a,--algorithm <arg>             Counting algorithm:
#                                   uniquely-mapped-reads(default) or proportional
#  -bam <arg>                       Mapping file in BAM format
#  -gtf <arg>                       Region file in GTF, GFF or BED format. If GTF
#                                   format is provided, counting is based on
#                                   attributes, otherwise based on feature name
#  -id <arg>                        GTF-specific. Attribute of the GTF to be used
#                                   as feature ID. Regions with the same ID will
#                                   be aggregated as part of the same feature.
#                                   Default: gene_id.
#  -out <arg>                       Output file of coverage report.
#  -p,--sequencing-protocol <arg>   Sequencing library protocol:
#                                   strand-specific-forward,
#                                   strand-specific-reverse or non-strand-specific
#                                   (default)
#  -pe,--paired                     Setting this flag for paired-end experiments
#                                   will result in counting fragments instead of
#                                   reads
#  -s,--sorted                      This flag indicates that the input file is
#                                   already sorted by name. If not set, additional
#                                   sorting by name will be performed. Only
#                                   required for paired-end analysis.
#  -type <arg>                      GTF-specific. Value of the third column of the
#                                   GTF considered for counting. Other types will
#                                   be ignored. Default: exon

# define executable with path
$qualimap_exec=$options{progDir}."/qualimap comp-counts";

if($options{bam} eq "")
{
	print STDERR "A BAM file must be provided";
	exit(1);
}

#copy input files to current directory if not already there
$tempbam = "./".(basename($options{bam}));
unless(-e $tempbam){
	copy($options{bam}, $tempbam) or die "BAM copy failed: $!";
}
$bam_file = $tempbam;

$tempgtf = "./".(basename($options{gtf}));
unless(-e $tempgtf){
	copy($options{gtf}, $tempgtf) or die "GTF copy failed: $!";
}
$gtf_file = $tempgtf;

# defaults
$idval=" -id ".$options{id};
$outfileval=" -out ".$options{out};
$pval=defined($options{p})?" -p ".$options{p}:" -p non-strand-specific";
$peval=defined($options{pe})?" -pe ":"";
$sval=defined($options{so})?" -s ":"";
$peval=defined($options{pe})?" -pe ":"";
$typeval=defined($options{type})?" -type ".$options{type}:" -type exon";

# build qualimap command
$cmd = $qualimap_exec." -bam ".$bam_file." -gtf ".$gtf_file;
$cmd .= $idval.$outfileval.$pval.$sval.$peval.$typeval;

print "\nCommand: $cmd\n";

# execute command and capture errors
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
