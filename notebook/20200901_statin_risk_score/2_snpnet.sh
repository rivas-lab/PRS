#!/bin/bash
set -beEuo pipefail

ml load snpnet_yt/dev

phenotype_name=$1
cpus=6
mem=60000

genotype_pfile="/scratch/groups/mrivas/ukbb24983/cal/pgen/ukb24983_cal_cALL_v2_hg19"
project_dir="/oak/stanford/groups/mrivas/users/gmcinnes/statin_risk_score"
results_dir="${project_dir}/${phenotype_name}"
phe_file="${project_dir}/statin_PRS_snpnet.phe"
family='binomial'

bash ${snpnet_wrapper} \
    --nCores ${cpus} --memory ${mem} \
    --covariates "age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10" \
    --verbose \
    --save_computeProduct \
    --glmnetPlus \
    ${genotype_pfile} \
    ${phe_file} \
    ${phenotype_name} \
    ${family} \
    ${results_dir}

exit 0

bash 2_snpnet.sh atorvastatin_v_hc_and_Ostatin
bash 2_snpnet.sh simvastatin_v_hc_and_Ostatin
