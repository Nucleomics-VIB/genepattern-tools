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
						"c",
						"gd=s",
						"gff=s",
						"hm=i",
						"ip",
						"nr=i",
						"nt=i",
						"nw=i",
						"oc=s",
						"os",
						"outdir=s",
						"outfile=s",
						"outformat=s",
						"p=s",
						"sd",
						"sm=i"
										);

# usage: qualimap bamqc -bam <arg> [-c] [-gd <arg>] [-gff <arg>] 
#		[-hm <arg>] [-nr <arg>] [-nt <arg>] [-nw <arg>] 
#		[-oc <arg>] [-os] [-outdir <arg>]
#		[-outfile <arg>] [-outformat <arg>] [-p <arg>]
# -bam <arg>                           Input mapping file in BAM format
# -c,--paint-chromosome-limits         Paint chromosome limits inside charts
# -gd,--genome-gc-distr <arg>          Species to compare with genome GC
#                                   distribution. Possible values: HUMAN or
#                                   MOUSE.
# -gff,--feature-file <arg>            Feature file with regions of interest in
#                                   GFF/GTF or BED format
# -hm <arg>                            Minimum size for a homopolymer to be
#                                   considered in indel analysis (default is
#                                   3)
# -ip,--collect-overlap-pairs          Activate this option to collect statistics
#                                   of overlapping paired-end reads
# -nr <arg>                            Number of reads analyzed in a chunk
#                                   (default is 1000)
# -nt <arg>                            Number of threads (default is 8)
# -nw <arg>                            Number of windows (default is 400)
# -oc,--output-genome-coverage <arg>   File to save per base non-zero coverage.
#                                   Warning: large files are  expected for large
#                                   genomes
# -os,--outside-stats                  Report information for the regions outside
#                                   those defined by feature-file  (ignored
#                                   when -gff option is not set)
# -outdir <arg>                        Output folder for HTML report and raw
#                                   data.
# -outfile <arg>                       Output file for PDF report (default value
#                                   is report.pdf).
# -outformat <arg>                     Format of the ouput report (PDF or HTML,
#                                   default is HTML).
# -p,--sequencing-protocol <arg>       Sequencing library protocol:
#                                   strand-specific-forward,
#                                   strand-specific-reverse or
#                                   non-strand-specific (default)
# -sd,--skip-duplicated             Activate this option to skip duplicate
#                                   alignments from the analysis. If the
#                                   duplicates are not flagged in BAM file,
#                                   then they will be detected by Qualimap
#                                   and can be selected for skipping.
# -sdmode,--skip-dup-mode <arg>        Specific type of duplicated alignments to
#                                   skip (if this option is activated).
#                                   0 : only flagged duplicates (default)
#                                   1 : only estimated by Qualimap
#                                   2 : both flagged and estimated

# define executable with path
$qualimap_exec=$options{progDir}."/qualimap bamqc";

if($options{bam} eq "")
{
	print STDERR "A BAM file must be provided";
	exit(1);
}

#copy input file to current directory if not already there
$tempfile = "./".(basename($options{bam}));
unless(-e $tempfile){
	copy($options{bam}, $tempfile) or die "BAM copy failed: $!";
}
$bam_file = $tempfile;

if (defined($options{gff})){
	$gfffile = "./".(basename($options{gff})); 
	unless(-e $gfffile){
	copy($options{gff}, $gfffile) or die "GFF copy failed: $!";
	}
	$gffval = " -gff ".$gfffile;
} else {
	$gffval = "";	
}

# defaults
$cval=defined($options{c})?" -c ":"";
$hmval=" -hm ".(defined($options{hm})?$options{hm}:3);
$ipval=defined($options{ip})?" -ip ":"";
$nrval=" -nr ".(defined($options{nr})?$options{nr}:1000);
$ntval=" -nt ".(defined($options{nt})?$options{nt}:8);
$nwval=" -nw ".(defined($options{nw})?$options{nw}:400);
$osval=defined($options{os})?" -os ":"";
$outdirval=defined($options{outdir})?" -outdir ".$options{outdir}:" -outdir ".$options{libdir};
$outfileval=" -outfile qualimap-report_".(basename($bam_file, ".bam"));
$outformatval=defined($options{outformat})?" -outformat ".$options{outformat}:" -outformat HTML";
$pval=defined($options{p})?" -p ".$options{p}:" -p non-strand-specific";

# skipping duplicates mapped reads?
if (defined $options{sd}) {
	$sdval=" -sd ";
	$sdmodeval=" -sdmode ".(defined($options{sm})?$options{sm}:0);
	#$sdmodeval=" --skip-dup-mode ".(defined($options{sm})?$options{sm}:0);
} else {
	$sdval="";
	$sdmodeval="";
}

# use presets for HUMAN and MOUSE
if (defined $options{gd} && $options{gd} ne '""') {
	$gdval=" -gd ".$options{gd};
} else {
	$gdval="";
}

if (defined $options{oc}) {
	$ocval=" -oc ".$options{oc}.".txt";
} else {
	$ocval="";
}

# build qualimap command
$cmd = $qualimap_exec." -bam ".$bam_file.$gffval;
$cmd .= $cval.$hmval.$ipval.$nrval.$ntval.$nwval;
$cmd .= $ocval.$osval;
$cmd .= $outdirval.$outfileval.$outformatval;
$cmd .= $pval.$sdval.$sdmodeval;
$cmd .= $gdval;

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
