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

while getopts "i:f:c:kh" opt; do
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
      keepheader="Yes"
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

# test if minimal arguments were provided
if [ -z "${infile}" ]
then
   echo "# no input provided!"
   echo "${usage}"
   exit 1
fi

# comment char
comment_char="${comment:-"#"}"

# filter string or default
filter=${filterstring:-"-k 1V,1 -k 2n,2 -k 3n,3"}

if [ -n "${keepheader}" ]; then
grep ^["${comment_char}"] ${infile}; grep ^[^"${comment_char}"] ${infile} | sort ${filter}
else
grep ^[^"${comment_char}"] ${infile} | sort ${filter}
fi