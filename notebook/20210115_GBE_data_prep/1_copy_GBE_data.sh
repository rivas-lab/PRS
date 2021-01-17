#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

##########
# dirs
##########

data_d=/scratch/groups/mrivas/projects/PRS
idx_f=${data_d}/private_output/202009_batch/snpnet.sscore.2_refit.tsv
out_d=${data_d}/GBE_data

##########
# constants
##########

GBE_IDs_f="${SRCDIR}/GBE_ID.lst"
exts=(tsv eval.tsv plot.png plot.pdf)

##########
# functions
##########

get_refit_d () {
    local GBE_ID=$1
    
    if  [ "${GBE_ID}" == "INI50" ] || 
        [ "${GBE_ID}" == "INI21001" ] || 
        [ "${GBE_ID}" == "HC269" ] || 
        [ "${GBE_ID}" == "HC382" ] ; then

        # we tested the pipeline with those 4 phenotypes
        # their results sit in a different directory

        echo /oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test/7_pfactor_v5/${GBE_ID}/2_refit
    else

        # the rest of the results from the batch run

        cat ${idx_f} | awk -v GBE_ID=${GBE_ID} '($1 == GBE_ID){print $3}' | rev | cut -d '/' -f2- | rev
    fi
}

cat ${GBE_IDs_f} | awk 'length($0)>0' | while read GBE_ID ; do
    refit_d=$(get_refit_d ${GBE_ID})
    for ext in ${exts[@]} ; do
        ! cp -a ${refit_d}/snpnet.${ext} ${out_d}/${GBE_ID}.${ext}
    done
done

