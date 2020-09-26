#!/bin/bash
set -beEuo pipefail

####################
# configure parameters
GBE_ID=FH1019

refit="F"
if [ $# -gt 1 ] && [ $2 == "refit" ] ; then refit="T" ; fi

####################
# run script
echo "${GBE_ID} (refit: ${refit})"
bash snpnet.sh --mem 30000 -c 6 $([ "${refit}" == "T" ] && echo "--refit" || echo "") ${GBE_ID}
