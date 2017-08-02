#!/bin/bash

# script tabix_search.sh
# search interval from a tabix indexed bgzip-compressed filebordercolor=0 .5 .5
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

read -d '' usage <<- EOF
Usage: tabix_search.sh -i <tabular.file.gz> 
#   -q <query interval (chr:start-end)>
#   -t <tabix index>
#   -P <full path to the bgzip executable>
EOF

while getopts "i:q:t:P:h" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    q)
      query=${OPTARG}
      ;;
    t)
      index=${OPTARG}
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

tabix="${exepath}"

# check if executable runs
$( hash "${tabix}" 2>/dev/null ) || ( echo "## ERROR! tabix executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
fi

if [[ ! ${infile} = *.gz ]]; then
echo "Error: input file should be compressed with bgzip!"
exit 1
fi

# if file was uploaded, copy it to current folder
if [[ $infile =~ "/uploads/tmp/" ]]; then
filecp=$(basename ${infile})
cp $infile ./${filecp}
infile="./${filecp}"
fi

# add tabix index if present
if [ -n "${index}" ] && [[ ${index} =~ "/uploads/tmp/" ]]; then
indexcp=$(basename ${index})
cp $index ./${indexcp}
fi

if [ -z "${infile}.tbi" ]; then
echo "# no tabix index found!"
echo "${usage}"
exit 1
fi

if [ -z "${query}" ]; then
echo "# no query interval provided!"
echo "${usage}"
exit 1
fi

${tabix} ${infile} ${query}