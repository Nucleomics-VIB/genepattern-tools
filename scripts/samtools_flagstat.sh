#!/bin/bash

# script samtools_flagstat.sh
# get flag stats from BAM file
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

read -d '' usage <<- EOF
Usage: samtools_flagstat.sh -i <SAM|BAM.file>
#   -h <display help>
EOF

while getopts "i:P:h" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    P)
      exepath=${OPTARG}
      ;;
    h)
      echo ${usage}
      exit 0
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

# path to executable
samtools="${exepath}"

# check if executable runs
$( hash "${samtools}" 2>/dev/null ) || ( echo "## ERROR! samtools executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
fi

# if file was uploaded, copy it to current folder
if [[ ${infile} =~ "/uploads/tmp/" ]]; then
filecp=$(basename ${infile})
cp ${infile} ./${filecp}
infile="./${filecp}"
fi

echo "# samtools flagstat results"
echo "# input: "$(basename ${infile})
echo "# "$(${samtools} --version | tr '\n' '\t')
echo ""
${samtools} flagstat -@ 4 ${infile}