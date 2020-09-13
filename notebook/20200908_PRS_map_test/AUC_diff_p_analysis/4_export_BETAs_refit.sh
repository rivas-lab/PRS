#!/bin/bash
set -beEuo pipefail

GBE_ID=$1
lambda_idx=$2
run_name='1_p_factor_v1'

ml load R/3.6 gcc plink2

my_plink_score () {
    local filename_prefix=$1
    local pfile=$2
    local threads=$3
    local memory=$4

    if [ -f ${pfile}.pvar.zst ] ; then
        pfile_str="--pfile ${pfile} vzs" # pvar file is zstd compressed
    else
        pfile_str="--pfile ${pfile}"
    fi

    cat ${filename_prefix}.tsv \
    | awk -v FS='\t' '(NR>1){print $3}' \
    | plink2 --threads ${threads} --memory ${memory} \
        ${pfile_str} \
        --extract /dev/stdin \
        --out ${filename_prefix} \
        --score ${filename_prefix}.tsv 3 5 6 header zs \
        cols=maybefid,maybesid,phenos,dosagesum,scoreavgs,denom,scoresums

    mv ${filename_prefix}.log ${filename_prefix}.sscore.log
}

genotype_pfile="/scratch/groups/mrivas/ukbb24983/array_combined/pgen/ukb24983_cal_hla_cnv"

results_dir="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test/${run_name}/${GBE_ID}/2_refit"

# export BETAs
Rscript export_BETAs.R ${GBE_ID} ${results_dir} ${lambda_idx}

# compute --score
find ${results_dir}/results -name "snpnet.lambda*.tsv" | grep -v covars.tsv | sort -V | while read f ; do
    if [ ! -f ${f%.tsv}.sscore.zst ] && [ ! -f ${f%.tsv}.sscore.log ] && [ $(cat $f | wc -l ) -gt 1 ] ; then
        my_plink_score ${f%.tsv} ${genotype_pfile} 6 30000
    fi
done
