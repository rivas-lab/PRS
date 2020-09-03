#!/bin/bash
#SBATCH --job-name=snpnet2
#SBATCH --output=logs/snpnet.%A.out
#SBATCH  --error=logs/snpnet.%A.err
#SBATCH --nodes=1
#SBATCH --cores=6
#SBATCH --mem=60000
#SBATCH --time=1-00:00:00
#SBATCH -p mrivas
set -beEuo pipefail

ml load snpnet_yt

cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )
mem=$(   cat $0 | egrep '^#SBATCH --mem='    | awk -v FS='=' '{print $NF}' )

# snpnet_dir="/oak/stanford/groups/mrivas/software/snpnet"
snpnet_dir="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet"
snpnet_wrapper='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/helper/snpnet_wrapper.sh'

genotype_pfile="/scratch/users/ytanigaw/tmp/snpnet/geno/array_combined/ukb24983_cal_hla_cnv"
phe_file="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/biomarkers/snpnet/disease_outcome_v2.1/phe/phe.tsv"

test_id=$1
phenotype_name="HC326"
covariates="age,sex,Array,PC1,PC2,PC3,PC4"
#covariates="None"
split_col="split"

family="binomial"
results_dir="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191121_snpnet/MI_test/${phenotype_name}_${test_id}"

echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

if [ ! -d ${results_dir} ] ; then mkdir -p ${results_dir} ; fi

bash ${snpnet_wrapper} \
    --snpnet_dir ${snpnet_dir} \
    --nCores ${cores} \
    --memory ${mem} \
    --covariates ${covariates} \
    --split_col ${split_col} \
    --verbose \
    --save_computeProduct \
    ${genotype_pfile} \
    ${phe_file} \
    ${phenotype_name} \
    ${family} \
    ${results_dir} 2>&1 | tee ${results_dir}/snpnet.log

echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

