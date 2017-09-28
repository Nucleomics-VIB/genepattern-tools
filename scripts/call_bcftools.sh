#!/bin/bash

# script call_varscan.sh
# use samtools, bcftools, vcftools, and varscan to call variants
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0
# piping directly without saving .bcf. 2017/09/26; v1.1

# redirect terminal outputs to file
exec >run_logfile.txt 2>&1

read -d '' usage <<- EOF
Usage: call_bcftools.sh -i <SAM|BAM.file>
#   -x <bai index>
#   -r <reference fasta>
#   -D <max-depth (default 1000)>
#   -s <path to samtools_1.5>
#   -b <path to bcftools_1.5>
#   -p <ploidy default to 'undef' (diploid)>

# call variants from pileup, filter and convert calls to VCF format
# samtools mpileup arguments
#  -u generate uncompress BCF output (to feed a pipe)
#  -f reference genome in fasta format related to the BWA index
# bcftools call arguments
#  -v output potential variant sites only (force -c)
#  -c SNP calling (force -e)
#  -O u for bcf-uncompressed output
# exclude calls where more than 1000 reads support a variation
EOF

while getopts "i:x:r:D:s:b:p:t:" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    x)
      index=${OPTARG}
      ;;
    r)
      reference=${OPTARG}
      ;;
    D)
      maxdepth=${OPTARG}
      ;;
    s)
      samtoolspath=${OPTARG}
      ;;    
    b)
      bcftoolspath=${OPTARG}
      ;;
    p)
      ploidy=${OPTARG}
      ;;
    t)
      compthr=${OPTARG}
      ;; 
    \?)
      echo ${usage}
      exit 1
      ;;
    *)
      echo ${usage} >&2
      exit 1
      ;;
  esac
done

# defaults
max_depth=${maxdepth:-1000}

###############
# REQUIREMENTS
###############

# path to executable
samtools="${samtoolspath}/samtools"
bcftools="${bcftoolspath}/bcftools"
vcfutils="${bcftoolspath}/vcfutils.pl"

# check if resuired dexecutables do runs
$( hash "${samtools}" 2>/dev/null ) || ( echo "## ERROR! samtools executable not found in PATH"; exit 1 )
$( hash "${bcftools}" 2>/dev/null ) || ( echo "## ERROR! bcftools executable not found in PATH"; exit 1 )
$( hash "${vcfutils}" 2>/dev/null ) || ( echo "## ERROR! vcfutils.pl executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
fi

# if file was uploaded, copy it to current folder
if [[ $infile =~ "/uploads/tmp/" ]]; then
filecp=$(basename $infile)
cp $infile ./${filecp}
infile="./${filecp}"
fi

# add tabix index if present
if [ -n "${index}" ] && [[ ${index} =~ "/uploads/tmp/" ]]; then
indexcp=$(basename ${index})
cp $index ./${indexcp}
fi

# handle -p
if [ ! "${ploidy}" == "\"\"" ]; then
ploidyval="--ploidy \""${ploidy}"\""
else
ploidyval=''
fi

# compression threads
thr=${compthr:-4}

# basename
prefix=$(basename ${infile})

read -d '' cmd << EOF
${samtools} mpileup -uf ${reference} ${infile} | \
	${bcftools} call --threads ${thr} ${ploidyval} -vc -O u | \
	bcftools view - | \
	${vcfutils} varFilter -D${maxdepth} > \
	./${prefix}_var_bcftools.flt-D${maxdepth}.vcf
EOF

echo "# ${cmd}"
eval ${cmd}

exit 0

# bcftools call --ploidy ?
# 
# PRE-DEFINED PLOIDY FILES
# 
#  * Columns are: CHROM,FROM,TO,SEX,PLOIDY
#  * Coordinates are 1-based inclusive.
#  * A '*' means any value not otherwise defined.
# 
# GRCh37
#    .. Human Genome reference assembly GRCh37 / hg19
# 
# X 1 60000 M 1
# X 2699521 154931043 M 1
# Y 1 59373566 M 1
# Y 1 59373566 F 0
# MT 1 16569 M 1
# MT 1 16569 F 1
# chrX 1 60000 M 1
# chrX 2699521 154931043 M 1
# chrY 1 59373566 M 1
# chrY 1 59373566 F 0
# chrM 1 16569 M 1
# chrM 1 16569 F 1
# *  * *     M 2
# *  * *     F 2
# 
# GRCh38
#    .. Human Genome reference assembly GRCh38 / hg38
# 
# X 1 9999 M 1
# X 2781480 155701381 M 1
# Y 1 57227415 M 1
# Y 1 57227415 F 0
# MT 1 16569 M 1
# MT 1 16569 F 1
# chrX 1 9999 M 1
# chrX 2781480 155701381 M 1
# chrY 1 57227415 M 1
# chrY 1 57227415 F 0
# chrM 1 16569 M 1
# chrM 1 16569 F 1
# *  * *     M 2
# *  * *     F 2
# 
# X
#    .. Treat male samples as haploid and female as diploid regardless of the chromosome name
# 
# *  * *     M 1
# *  * *     F 2
# 
# Y
#    .. Treat male samples as haploid and female as no-copy, regardless of the chromosome name
# 
# *  * *     M 1
# *  * *     F 0
# 
# 1
#    .. Treat all samples as haploid
# 
# *  * *     * 1
# 
# Run as --ploidy <alias> (e.g. --ploidy GRCh37).
# To see the detailed ploidy definition, append a question mark (e.g. --ploidy GRCh37?).