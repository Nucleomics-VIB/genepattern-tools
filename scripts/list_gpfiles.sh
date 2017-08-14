#!/bin/bash

# script echo_env.sh
# will return the value of the variable to stdout
#
# Stephane Plaisance (VIB-NC) 2017/08/08; v1.0

read -d '' usage <<- EOF
Usage: list_gpfiles.sh -f <folder>
# will return the list of files in different key GP folders
EOF

while getopts "f:" opt; do
  case $opt in
    f)
      folder=${OPTARG}
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

gphome="/opt/tools/GenePatternServer"

echo "# content of ${gphome}/resources/wrapper_scripts"
ls -lah "${gphome}/resources/wrapper_scripts/"
echo
echo "# content of ${gphome}/patches"
ls -lah "${gphome}/patches/"
echo
if [ -d "${gphome}/${folder}" ]; then
echo "# content of ${gphome}/${folder}"
ls -lah "${gphome}/${folder}"
fi
echo
echo "# content of ${gphome}/resources/custom.properties"
cat ${gphome}/resources/custom.properties
