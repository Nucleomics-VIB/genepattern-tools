#!/bin/bash

# script echo_env.sh
# will return the value of the variable to stdout
#
# Stephane Plaisance (VIB-NC) 2017/08/08; v1.0

read -d '' usage <<- EOF
Usage: echo_env.sh -v <variable name>
# will return the value of the variable to stdout
EOF

while getopts "v:" opt; do
  case $opt in
    v)
      variable=${OPTARG}
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

echo "########################################"
echo "# content of env"
echo "########################################"
echo ""
env
echo ""
echo "########################################"
echo "# value of the variable "${variable}
echo "########################################"
echo ""
/bin/echo ${!variable}
