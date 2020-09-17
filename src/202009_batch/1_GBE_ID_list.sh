#!/bin/bash
set -beEuo pipefail

GBE_CATs=(
FH
cancer
HC
BIN
BIN_FC
INI
QT_FC
)

# List the GBE IDs in master phe info files
# We don't run the pipe for the 4 phenotypes that were used in the test runs

for GBE_CAT in ${GBE_CATs[@]} ; do
    {
        echo "#GBE_ID"
        cat /oak/stanford/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200828.phe.info.tsv \
        | cut -f1 | egrep "^${GBE_CAT}" \
        | awk '$1 != "INI50" && $1 != "INI21001" && $1 != "HC269" && $1 != "HC382"' \
        | sort -V
    } > GBE_IDs/${GBE_CAT}.lst
done
