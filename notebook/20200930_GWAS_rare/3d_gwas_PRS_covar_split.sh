#!/bin/bash
set -beEuo pipefail

idx=$1
GBE_ID=$2
split=$3

bash /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/04_gwas/extras/20200930_gwas_parallel/1_plink.gwas.sh \
--GBE_ID ${GBE_ID} \
--keep /oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare/keep/${split}.phe \
--covar_names_add PRS_${GBE_ID} \
--covar /oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare/ukb24983_GWAS_covar.20200828.PRSs.phe.zst \
${idx} /oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare/d_PRS_covar_${split}
