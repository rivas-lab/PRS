#!/bin/bash
#SBATCH --job-name=snpnet
#SBATCH --output=logs/snpnet.%A.out
#SBATCH  --error=logs/snpnet.%A.err
#SBATCH --nodes=1
#SBATCH --cores=10
#SBATCH --mem=200000
#SBATCH --time=2-00:00:00
#SBATCH -p mrivas
set -beEuo pipefail

ml load snpnet anaconda/Anaconda3-5.3.0-Linux-x86_64_20181113 zstd
wrapper="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/helper/snpnet_wrapper.v2.2.sh"

cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )
mem=$(   cat $0 | egrep '^#SBATCH --mem='    | awk -v FS='=' '{print $NF}' )

## required args

genotype_pfile="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/inst/extdata/sample"
phe_file="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/inst/extdata/sample.phe"
phenotype_name="QPHE"
family="gaussian"
out_dir_root="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/19"

### another example from Biomarker project
# genotype_pfile="/scratch/users/ytanigaw/tmp/snpnet/geno/array_combined/ukb24983_cal_hla_cnv"
# phe_file="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/public-resources/uk_biobank/biomarkers/snpnet/data/biomarkers_covar.phe"
# phenotype_name=$1
# family="gaussian"
# out_dir_root="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/public-resources/uk_biobank/biomarkers/snpnet/data"

## options
snpnet_dir="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet"
covariates="age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"
split_col="split"
status_col="CoxStatus"

echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

bash ${wrapper} \
--snpnet_dir ${snpnet_dir} \
--nCores ${cores} --memory ${mem} \
--covariates ${covariates} \
--split_col ${split_col} \
--status_col ${status_col} \
--no_save --verbose \
${genotype_pfile} \
${phe_file} \
${phenotype_name} \
${family} \
${out_dir_root}

echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2
