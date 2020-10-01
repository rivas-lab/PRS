#!/bin/bash
set -beEuo pipefail

covar_f=/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20200828/ukb24983_GWAS_covar.20200828.phe
out_d=/oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare/keep

cat ${covar_f}| awk -v OFS='\t'  '($4 == "test"){print $1, $2}' > ${out_d}/test.phe
cat ${covar_f}| awk -v OFS='\t'  '($4 == "train" || $4 == "val"){print $1, $2}' > ${out_d}/train_val.phe
