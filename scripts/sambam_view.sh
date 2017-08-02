#!/bin/bash

# script sambam_view.sh
# view [top N-lines (default to 50)] or full SAM or BAM data 
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

usage="Usage: sambam_view.sh -i <SAM¬BAM.file>
 -t <only first N lines (default to 50; 0 for full data)>
 -h <include header>
 -H <show only header>"

while getopts "i:t:h:H:" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    h)
      showheader=${OPTARG}
      ;;    
    H)
      headeronly=${OPTARG}
      ;;  
    t)
      topn=${OPTARG}
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
samtools="<samtools_1.5>/samtools"

# check if executable runs
$( hash "${samtools}" 2>/dev/null ) || ( echo "## ERROR! samtools executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
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
${samtools} view ${header} ${infile}
else
${samtools} view ${header} ${infile} | head -${top}
fi