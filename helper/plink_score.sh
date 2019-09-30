#!/bin/bash
set -beEuo pipefail
####################################################################
# compute PRS (beta times X)
# usage: bash plink_score.sh <path_to_data_dir> <phenotype name> <pfile>
# 
####################################################################

############################################################
# input args
############################################################
data_dir_root=$1
phenotype_name=$2
pfile=$3

############################################################
# functions
############################################################
source "$(dirname $(readlink -f $0))/snpnet_misc.sh"

############################################################
res_dir="$(get_results_dir ${data_dir_root} ${phenotype_name})"

if [ ! -d ${res_dir}/score ] ; then mkdir -p ${res_dir}/score ; fi

betas="${res_dir}/betas.tsv"
if [ ! -f ${res_dir}/score/${phenotype_name}.sscore.log ] && [ -f ${betas} ] ; then

    plink_opts="--threads 6 --memory 60000"

    cat $betas | awk '(NR>1){print $1}' \
        | plink2 ${plink_opts} \
        --pfile ${pfile} \
        --extract /dev/stdin \
        --out ${res_dir}/score/${phenotype_name} \
        --score $(readlink -f ${betas}) 1 2 3 header cols=maybefid,maybesid,phenos,nmissallele,dosagesum,scoreavgs,denom,scoresums

    mv ${res_dir}/score/${phenotype_name}.log ${res_dir}/score/${phenotype_name}.sscore.log
fi

