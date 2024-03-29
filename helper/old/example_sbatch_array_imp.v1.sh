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

cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )
mem=$(   cat $0 | egrep '^#SBATCH --mem='    | awk -v FS='=' '{print $NF}' )

phenotype_name=$1
snpnet_dir="/oak/stanford/groups/mrivas/software/snpnet"
family="gaussian"
#geno_dir="/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification/split"
geno_dir="/scratch/users/ytanigaw/tmp/snpnet/geno/array_imp_combined"
out_dir_root="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/public-resources/uk_biobank/biomarkers/snpnet/data_array_imp"
phe_file="${out_dir_root}/biomarkers_covar.phe"
covariates="None"

echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2
bash snpnet_wrapper.sh ${snpnet_dir} ${phenotype_name} ${family} ${geno_dir} ${out_dir_root} ${phe_file} ${covariates} ${cores} ${mem}
echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

