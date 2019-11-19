#!/bin/bash
set -beEuo pipefail

test_id=21_cox

#cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )
#mem=$(   cat $0 | egrep '^#SBATCH --mem='    | awk -v FS='=' '{print $NF}' )

cores=4
mem=30000

ml load snpnet_yt

wrapper=${snpnet_wrapper}
# "/oak/stanford/groups/mrivas/users/$USER/repos/rivas-lab/PRS/helper/snpnet_wrapper.sh"

## required args

genotype_pfile="/oak/stanford/groups/mrivas/users/$USER/repos/rivas-lab/snpnet/inst/extdata/sample"
phe_file="/oak/stanford/groups/mrivas/users/$USER/repos/rivas-lab/snpnet/inst/extdata/sample.phe"
phenotype_name="CoxPhe" #"QPHE"
family="cox" # gaussian
results_dir="/oak/stanford/groups/mrivas/users/$USER/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/${test_id}/${phenotype_name}"

## options
snpnet_dir="/oak/stanford/groups/mrivas/users/$USER/repos/rivas-lab/snpnet" 
covariates="age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
split_col="split"
status_col="CoxStatus"

#echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2
bash ${wrapper} \
--snpnet_dir ${snpnet_dir} \
--nCores ${cores} --memory ${mem} \
--covariates ${covariates} \
--split_col ${split_col} \
--status_col ${status_col} \
--verbose \
--no_save \
--glmnetPlus \
${genotype_pfile} \
${phe_file} \
${phenotype_name} \
${family} \
${results_dir}

#echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2
