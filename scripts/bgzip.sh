#!/bin/bash

# script bgzip.sh
# sort and compress tabular data
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

usage="Usage: bgzip.sh -i <tabular.file>
# -f <sorting filter (default to chr, start, end)>
# -c <comment character (default to #)"

while getopts "i:f:c:h" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    f)
      filter=${OPTARG}
      ;;
    c)
      comment=${OPTARG}
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

bgzip="<samtools_1.5>/bgzip"

# check if executable runs
$( hash "${bgzip}" 2>/dev/null ) || ( echo "## ERROR! bgzip executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
fi

# default filter to BED standard
if [ -z "${filter}" ]; then
filter="-k 1V,1 -k 2n,2 -k 3n,3"
fi

# default comment character
comment_char=${comment:-"#"}

( grep ^["${comment_char}"] ${infile}; grep ^[^"${comment_char}"] ${infile} | sort ${filter} ) | \
	${bgzip} -c