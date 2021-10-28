#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

out_d='/scratch/groups/mrivas/projects/PRS/private_output/20211025_sensitivity_analysis/output'

{
    cat ${out_d}/INI50.tsv | grep '#'
    cat /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/data/traits_significant.tsv  \
    | awk '((NR > 1) && (length($0) > 0)){print $2}' \
    | while read -r trait ; do
        f=${out_d}/${trait}.tsv
        if [ -s ${f} ] ; then
            cat ${f} | grep -v '#'
        fi
    done 
} > $(dirname ${out_d})/residual_regression.tsv
