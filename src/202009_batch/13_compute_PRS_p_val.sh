#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

GBE_ID=$1
src="13_compute_PRS_p_val.R"

source '0_parameters.sh'

out_f="${res_scratch_d}/tmp_glmfit/${GBE_ID}.tsv"

if [ ! -s ${out_f} ] ; then
    # run the R script if there is no output file
    ml load R/3.6 gcc
    Rscript ${src} ${GBE_ID}
fi
