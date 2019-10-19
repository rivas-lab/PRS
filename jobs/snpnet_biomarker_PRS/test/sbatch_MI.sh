#!/bin/bash

#SBATCH --job-name=snpnet
#SBATCH   --output=snpnet.%A.out
#SBATCH    --error=snpnet.%A.err
#SBATCH --time=12:00:00
#SBATCH --qos=normal
#SBATCH -p owners,normal,mrivas
#SBATCH --nodes=1
#SBATCH --cores=10
#SBATCH --mem=100000
#SBATCH --constraint="CPU_GEN:HSW|CPU_GEN:BDW|CPU_GEN:SKX"
#SBATCH --mail-type=END,FAIL
#################
# Usage: $ sbatch --array=1-2,4%1 sbatch.sh
#
set -beEu -o pipefail

# automatically get cores and mem settings from the above
cores=$( cat $0 | egrep '^#SBATCH --cores=' | awk -v FS='=' '{print $NF}' )
mem=$(   cat $0 | egrep '^#SBATCH --mem='   | awk -v FS='=' '{print $NF}' )

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}" >&2

app_id=24983 # use master phe file 
method="snpnet_biomarker_PRS"
script="$OAK/users/$USER/repos/rivas-lab/PRS/src/${method}.sh"

# cat <(echo "#FID IID T2D" | tr " " "\t" )  /oak/stanford/groups/mrivas/users/nasa/MR_results/type_2_diabetes.phe > T2D.phe

phe=/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/test/T2D.phe
phe_type='bin'
keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"

bash $script \
        ${phe} \
        ${phe_type} \
        ${keep} \
        /oak/stanford/groups/mrivas/projects/PRS/private_output/snpnet_PRS/test \
        ${memory} \
        ${threads} \
        24983 \
        10

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}" >&2

