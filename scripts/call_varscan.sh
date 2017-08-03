#!/bin/bash

# script call_varscan.sh
# use samtools, bcftools, vcftools, and varscan to call variants
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

# redirect terminal outputs to file
exec >run_logfile.txt 2>&1

read -d '' usage <<- EOF
Usage: call_varscan.sh -i <SAM|BAM.file>
#   -x <bai index>
#   -r <reference fasta>
#   -p <max pvalue (0.01)>
#   -s <path to samtools_1.5>
#   -v <path to varscan2>

# call variants from pileup, filter and convert calls to VCF format
# varscan 1.4.3 call SNV and InDels variants from samtools mpileup
EOF

while getopts "i:x:r:p:s:v:" opt; do
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
    p)
      maxpval=${OPTARG}
      ;;
    s)
      samtoolspath=${OPTARG}
      ;;    
    v)
      varscanpath=${OPTARG}
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
max_pval=${maxpval:-0.01}

###############
# REQUIREMENTS
###############

# path to executable
samtools="${samtoolspath}/samtools"
varscan="${varscanpath}/varscan.jar"

# check if resuired dexecutables do runs
$( hash "${samtools}" 2>/dev/null ) || ( echo "## ERROR! samtools executable not found in PATH"; exit 1 )
$( hash "java -jar ${varscan}" 2>/dev/null ) || ( echo "## ERROR! varscan.jar executable not found in PATH"; exit 1 )

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

(${samtools} mpileup -f ${reference} ${infile} | \
	java -jar ${varscan} mpileup2cns \
	--variants --output-vcf 1 --p-value ${max_pval} \
	> ${prefix}_mpileup2cns.vcf) 

exit 0