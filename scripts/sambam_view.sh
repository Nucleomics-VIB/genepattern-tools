#!/bin/bash

# script sambam_view.sh
# view [top N-lines (default to 50)] or full SAM or BAM data
# query user-defined region
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

read -d '' usage <<- EOF
Usage: sambam_view.sh -i <SAM|BAM.file>
#   -q <query region>
#   -t <only first N lines (default to 50; 0 for full data)>
#   -h <include header>
#   -H <show only header>
EOF

while getopts "i:x:q:t:o:h:H:P:" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    x)
      index=${OPTARG}
      ;;
    h)
      showheader=${OPTARG}
      ;;    
    H)
      headeronly=${OPTARG}
      ;;  
    q)
      query=${OPTARG}
      ;;
    t)
      topn=${OPTARG}
      ;;
    o)
      optargs=${OPTARG}
      ;;
    P)
      exepath=${OPTARG}
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

# show header?
if [[ $showheader = "Yes" ]]; then
header=" -h"
fi

# overseeds -h
if [[ ${headeronly} = "Yes" ]]; then
header=" -H"
fi

# set default to to 50 rows
top=${topn:-50}

if [ ${top} == 0 ]; then
${samtools} view ${header} ${optargs} ${infile} ${query} 
else
${samtools} view ${header} ${optargs} ${infile} ${query} | head -${top}
fi