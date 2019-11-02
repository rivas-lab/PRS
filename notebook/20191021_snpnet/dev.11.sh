#!/bin/bash
set -beEuo pipefail

test_id=10

#cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )
#mem=$(   cat $0 | egrep '^#SBATCH --mem='    | awk -v FS='=' '{print $NF}' )

cores=4
mem=30000


ml load snpnet anaconda/Anaconda3-5.3.0-Linux-x86_64_20181113 zstd

phenotype_name="QPHE"
split_col="split"
# snpnet_dir="/oak/stanford/groups/mrivas/software/snpnet"
snpnet_dir="/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/snpnet"
family="gaussian"
geno_dir="/oak/stanford/groups/mrivas/projects/snpnet/sample_data"
out_dir_root="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/${test_id}"
#out_dir_root="/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/snpnet/dev/out/${test_id}"
phe_file="${geno_dir}/sample.phe"
covariates="age,sex,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10"

wrapper="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/helper/snpnet_wrapper.v2.1.sh"

#echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2
bash ${wrapper} ${snpnet_dir} ${phenotype_name} ${family} ${split_col} ${geno_dir} ${out_dir_root} ${phe_file} ${covariates} ${cores} ${mem}
#echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}; phenotype = ${phenotype_name}" >&2

