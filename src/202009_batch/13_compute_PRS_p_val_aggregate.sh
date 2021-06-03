#!/bin/bash
set -beEuo pipefail

source '0_parameters.sh'

out_d="${res_scratch_d}/tmp_glmfit"

{
    cat ${out_d}/INI50.tsv | egrep '^#'

    find ${out_d} -type f -name "*.tsv" | sort -V | while read f ; do cat $f | egrep -v '^#' ; done
} | bgzip -l9 -@6 > ${res_d}/${PRS_pval_f}

echo ${res_d}/${PRS_pval_f}
