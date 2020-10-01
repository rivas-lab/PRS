#!/bin/bash
set -beEuo pipefail

GBE_IDs=(INI50 INI21001 HC269 HC382)
src=(3a_gwas_default.sh 3b_gwas_PRS_covar.sh)
src_split=(3c_gwas_default_split.sh 3d_gwas_PRS_covar_split.sh)
splits=(train_val test)

ml load resbatch
if [ ! -d logs ] ; then mkdir -p logs ; fi

for GBE_ID in ${GBE_IDs[@]} ; do

for s in ${src[@]} ; do

jn=gwas.$(basename ${s} .sh | sed -e "s/_gwas//g").${GBE_ID}

sbatch -p mrivas --qos=high_p --time=1:0:00 --mem=8000 --nodes=1 --cores=2 \
--job-name=${jn} --output=logs/${jn}.%A_%a.out --error=logs/${jn}.%A_%a.err \
--array=1-100 ${parallel_sbatch_sh} ${s} ${parallel_idx} 1 ${GBE_ID}

done

for s in ${src_split[@]} ; do
for ss in ${splits[@]} ; do

jn=gwas.$(basename ${s} .sh | sed -e "s/_gwas//g").${ss}.${GBE_ID}

sbatch -p mrivas --qos=high_p --time=1:0:00 --mem=8000 --nodes=1 --cores=2 \
--job-name=${jn} --output=logs/${jn}.%A_%a.out --error=logs/${jn}.%A_%a.err \
--array=1-100 ${parallel_sbatch_sh} ${s} ${parallel_idx} 1 ${GBE_ID} ${ss}

done
done

done
