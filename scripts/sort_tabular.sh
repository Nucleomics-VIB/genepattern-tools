#!/bin/bash

# script sort_tabular.sh
# sort tabular files
# accept any GNU sort options passed from -f between quotes
# by default removes all lines starting with '#' unless -h is provided
#
# Stephane Plaisance (VIB-NC) 2017/07/28; v1.0

read -d '' usage <<- EOF
Usage: sort_tabular.sh -i <input.file>
# -f <filter expression>
# -c <comment character (default to #)>
# -k <keep header (default remove #-lines)>
EOF

while getopts "i:f:c:k:P:h" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    f)
      filterstring=${OPTARG}
      ;;
    c)
      comment=${OPTARG}
      ;;
    k)
      keepheader=${OPTARG}
      ;;
    P)
      exepath=${OPTARG}
      ;;
    h)
      echo "${usage}"
      exit 0
      ;;
    \?)
      echo "${usage}"
      exit 1
      ;;
    *)
      echo "${usage}" >&2
      exit 1
      ;;
  esac
done

bgzip="${exepath}"

# check if executable runs
$( hash "${bgzip}" 2>/dev/null ) || ( echo "## ERROR! bgzip executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]
then
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

# comment char
comment_char="${comment:-"#"}"

# filter string or default
filter=${filterstring:-"-k 1V,1 -k 2n,2 -k 3n,3"}

# test if input is compressed
if [[ ${infile} = *.gz ]]; then
# compressed
if [[ ${keepheader} = "Yes" ]]; then
( zgrep ^["${comment_char}"] ${infile}; zgrep ^[^"${comment_char}"] ${infile} | sort ${filter} ) | ${bgzip} -c
else
zgrep ^[^"${comment_char}"] ${infile} | sort ${filter} | ${bgzip} -c
fi
else
# not compressed
if [[ ${keepheader} = "Yes" ]]; then
grep ^["${comment_char}"] ${infile}; grep ^[^"${comment_char}"] ${infile} | sort ${filter}
else
grep ^[^"${comment_char}"] ${infile} | sort ${filter}
fi
fi