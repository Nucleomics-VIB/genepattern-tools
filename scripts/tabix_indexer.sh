#!/bin/bash

# script tabix_indexer.sh
# create tabix index from a bgzip compressed tabular file
#
# Stephane Plaisance (VIB-NC) 2017/07/29; v1.0

read -d '' usage <<- EOF
Usage: tabix_indexer.sh -i <tabular.file.gz (if not compressed, a bgzip version is created)> 
#	-p <preset (gff|bed|sam|vcf|custom>
# additional fields for 'custom'
#	-s <sequence name (1 for most file types)
#	-b <begin-coordinate (2 for BED|GFF, 4 for SAM)>
#	-e <end coordinate (3 for BED)>
#	-c <comment char (#)>
#	-z <start-coordinate is 0-based (default OFF for 1-based)>
EOF

while getopts "i:p:s:b:e:c:zh" opt; do
  case $opt in
    i)
      infile=${OPTARG}
      ;;
    p)
      preset=${OPTARG}
      ;;
    s)
      seqc=${OPTARG}
      ;;
    b)
      beginc=${OPTARG}
      ;;
    e)
      endc=${OPTARG}
      ;;    
    c)
      comment_char=${OPTARG}
      ;;
    z)
      zerob=1
      ;;
    h)
      echo "${usage}"
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

tabix="<samtools_1.5>/tabix"

# check if executable runs
$( hash "${tabix}" 2>/dev/null ) || ( echo "## ERROR! tabix executable not found in PATH"; exit 1 )

# test if minimal arguments were provided
if [ -z "${infile}" ]; then
echo "# no input provided!"
echo "${usage}"
exit 1
fi

if [[ ! ${infile} = *.gz ]]; then
echo "The input file needs first be sorted and compressed with bgzip!"
echo "You can use the bgzip module to do so"
exit 1
fi

# handle -0
if [ -n "${zerob}" ]; then
zerobased=" -0"
else
zerobased=''
fi

# handle -c
if [ -n "${comment_char}" ]; then
comment=" -c \""${comment_char}"\""
else
comment=''
fi

##################
# run with preset
##################

if [[ "${preset}" =~ ^(gff|sam|bed|vcf)$ ]]; then
cmd="${tabix} -f -p ${preset} ${infile}"
echo "${cmd}"
eval ${cmd}
# end run with preset

# run custom instead
else

# minimal arguments required
if [ -z "${seqc}" ] || [ -z "${beginc}" ]; then
echo "Both sequence name and begin coordinate columns are required!" 
exit 1
fi

# run with all available details
cmd="${tabix} -f ${zerobased} ${comment} -s ${seqc} -b ${beginc}"

# add end coordinate if endc has a value
if [ -n "${endc}" ]; then
cmd=${cmd}" -e ${endc}"
fi

# add infile for complete command
cmd=${cmd}" "${infile}
echo "${cmd}"
eval ${cmd}
fi
# end run custom
