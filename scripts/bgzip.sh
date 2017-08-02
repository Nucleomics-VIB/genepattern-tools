#!/bin/bash

# script bgzip.sh
# sort and compress tabular data
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

read -d '' usage <<- EOF
Usage: bgzip.sh -i <tabular.file>
# -f <sorting filter (default to chr, start, end)>
# -c <comment character (default to #)
# -P <full path to the bgzip executable>
EOF

while getopts "i:f:c:P:h" opt; do
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

bgzip="${exepath}"

# check if executable runs
$( hash "${bgzip}" 2>/dev/null ) || ( echo "## ERROR! bgzip executable not found in PATH"; exit 1 )

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

# default filter to BED standard
if [ -z "${filter}" ]; then
filter="-k 1V,1 -k 2n,2 -k 3n,3"
fi

# default comment character
comment_char=${comment:-"#"}

( grep ^["${comment_char}"] ${infile}; grep ^[^"${comment_char}"] ${infile} | sort ${filter} ) | \
	${bgzip} -c