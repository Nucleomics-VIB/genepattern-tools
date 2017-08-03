#!/bin/bash

# script call_varscan.sh
# use samtools, bcftools, vcftools, and varscan to call variants
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

# redirect terminal outputs to file
exec >run_logfile.txt 2>&1

read -d '' usage <<- EOF
Usage: call_bcftools.sh -i <SAM|BAM.file>
#   -x <bai index>
#   -r <reference fasta>
#   -D <max-depth (default 1000)>
#   -s <path to samtools_1.5>
#   -b <path to bcftools_1.5>

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

while getopts "i:x:r:D:s:b:" opt; do
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

# basename
prefix=$(basename ${infile})

((${samtools} mpileup -uf ${reference} ${infile} | \
	${bcftools} call -vc -O u > ./${prefix}.raw.bcf) && \
(bcftools view ./${prefix}.raw.bcf | \
	${vcfutils} varFilter -D${maxdepth} > \
	./${prefix}_var_bcftools.flt-D${maxdepth}.vcf)) && \
	rm ./${prefix}.raw.bcf

exit 0