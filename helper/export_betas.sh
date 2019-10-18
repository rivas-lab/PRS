#!/bin/bash
set -beEuo pipefail
####################################################################
# export BETAs from the latest RData file
# usage: bash export_betas.sh <path_to_data_dir> <phenotype name> <covariates>
# 
# This script identifies prevIter and extracts BETAs 
# from the corresponding RData file.
####################################################################

############################################################
# input args
############################################################
data_dir_root=$1
phenotype_name=$2
covariates=$3

############################################################
# functions
############################################################
source "$(dirname $(readlink -f $0))/snpnet_misc.sh"

############################################################
prevIter="$(find_prevIter ${data_dir_root} ${phenotype_name})"
res_dir="$(get_results_dir ${data_dir_root} ${phenotype_name})"
RData_file="${res_dir}/results/output_iter_${prevIter}.RData"

src="$(dirname $(readlink -f $0))/export_betas.R"

#if [ ! -f ${RData_file%.RData}.tsv ] && [ ! -f ${RData_file%.RData}.covars.tsv ] ; then
    Rscript ${src} ${RData_file} ${covariates}
#fi
echo ${RData_file%.RData}.tsv
echo ${RData_file%.RData}.covars.tsv

for ext in "tsv" "covars.tsv" ; do
    ln -sf ${RData_file%.RData}.${ext} ${res_dir}/betas.${ext}
    echo ${res_dir}/betas.${ext}
done

