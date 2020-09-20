#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

rdata=$1
results_dir=$(dirname ${rdata})
refit_dirname=$(dirname ${results_dir})
phenotype_name=$(basename $(dirname ${results_dir}))

if  [ -s ${results_dir}/snpnet.eval.tsv ] ; then
    # check if we have the evaluation table
    exit 0
fi

source /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/helpers/snpnet_misc.sh

if  [ $(cat ${results_dir}/snpnet.tsv | wc -l) -gt 1 ] &&
    [ ! -f ${results_dir}/${phenotype_name}.sscore.zst ] &&
    [ ! -f ${results_dir}/${phenotype_name}.sscore.log ] ; then

    plink_score ${results_dir} ${phenotype_name} ${genotype_pfile} ${nCores} ${mem}
fi

run-simg.sh Rscript ${SRCDIR}/snpnet.eval.dev.R ${phenotype_name} ${results_dir} $([ "${refit_dirname}" == "2_refit" ] && echo "refit" || echo "")
