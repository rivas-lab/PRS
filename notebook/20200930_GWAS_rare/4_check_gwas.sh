#!/bin/bash
set -beEuo pipefail

GBE_IDs=(INI50 INI21001 HC269 HC382)
sub_ds=(
a_default
b_PRS_covar
c_default_test
c_default_train_val
d_PRS_covar_test
d_PRS_covar_train_val
)

src=/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/04_gwas/extras/20200930_gwas_parallel/2_check_results.sh
out_d=/oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare

for GBE_ID in ${GBE_IDs[@]} ; do
for sub_d in ${sub_ds[@]} ; do

echo "# ${GBE_ID} ${sub_d}"
bash ${src} --GBE_ID ${GBE_ID} ${out_d}/${sub_d} | tr '\n' ','

done
done

