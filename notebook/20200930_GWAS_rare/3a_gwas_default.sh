#!/bin/bash
set -beEuo pipefail

idx=$1
GBE_ID=$2

bash /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/04_gwas/extras/20200930_gwas_parallel/1_plink.gwas.sh \
--GBE_ID ${GBE_ID} \
--covar /oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20200828/ukb24983_GWAS_covar.20200828.phe \
${idx} /oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare/a_default
