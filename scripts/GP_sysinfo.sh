#!/bin/bash

# script echo_env.sh
# will return the value of the variable to stdout
#
# Stephane Plaisance (VIB-NC) 2017/08/08; v1.0

read -d '' usage <<- EOF
Usage: GP_sysinfo.sh -f <extra folder>
# will return the list of files in different key GP folders
# one additional folder can be provided (within the GP tree)
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

# redirect all to sysinfo.txt in this script
exec > "sysinfo.txt" 2>&1

echo "# GP_sysinfo result; "$(date)
echo
echo "# system variables within GP"
echo "# R environment"
R --version
which Rscript 
echo $(Rscript --version)
echo "# R_HOME= "$R_HOME
echo "# R_LIBS= "$R_LIBS
echo
echo "# GP server runtime environment"
env | sort
echo
echo "# PATH is set to: "
echo $PATH | tr ":" "\n" | sort
echo
echo "# DISPLAY is set to: "$DISPLAY
echo
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
echo