#!/bin/bash
#SBATCH --job-name=srrr
#SBATCH --output=logs/srrr.%A.out
#SBATCH  --error=logs/srrr.%A.err
#SBATCH --nodes=1
#SBATCH --mem=400000
#SBATCH --cores=32
#SBATCH --time=7-0:00:00
#SBATCH -p mrivas
#SBATCH --qos=high_p

set -beEuo pipefail

############################################################
# config params
############################################################

rank=$1
if [ $# -gt 1 ] ; then prev_iter=$2 ; else prev_iter=0 ; fi

ml load R/3.6 gcc

mem=$(   cat $0 | egrep '^#SBATCH --mem='   | awk -v FS='=' '{print $NF}' )
cores=$( cat $0 | egrep '^#SBATCH --cores=' | awk -v FS='=' '{print $NF}' )

############################################################
# job start
############################################################

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-start] hostname=$(hostname); SLURM_JOBID=${SLURM_JOBID:=0}; SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID:=1}" >&2

############################################################
# body
############################################################

Rscript srrr_fit.R ${rank} ${prev_iter} ${mem} ${cores}

############################################################
# job finish footer (for use with array-job module)
############################################################
echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-end] hostname=$(hostname); SLURM_JOBID=${SLURM_JOBID}; SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}" >&2
