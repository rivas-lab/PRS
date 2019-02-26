#!/bin/bash

#SBATCH --job-name=PRS_cancer
#SBATCH   --output=PRS_cancer.%A_%a.out
#SBATCH    --error=PRS_cancer.%A_%a.err
#SBATCH --time=1-0:00:00
#SBATCH --qos=normal
#SBATCH -p owners,normal,mrivas
#SBATCH --nodes=1
#SBATCH --cores=4
#SBATCH --mem=32000
#SBATCH --mail-type=END,FAIL
#################
# Usage: $ sbatch --array=1-2,4%1 sbatch.sh
#
set -beEu -o pipefail

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}; SLURM_ARRAY_TASK_ID = ${SLURM_ARRAY_TASK_ID}" >&2

task_id=$SLURM_ARRAY_TASK_ID
cores=4
mem=32000
bash task.sh $task_id $mem $cores

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}; SLURM_ARRAY_TASK_ID = ${SLURM_ARRAY_TASK_ID}" >&2

