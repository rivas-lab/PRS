#!/bin/bash
#SBATCH --job-name=snpnet
#SBATCH --output=logs/snpnet.%A_%a.out
#SBATCH  --error=logs/snpnet.%A_%a.err
#SBATCH --nodes=1
#SBATCH --mem=60000
#SBATCH --cores=4
#SBATCH --time=2-0:00:00
#SBATCH -p owners

set -beEuo pipefail

############################################################
# config params
############################################################

# ml load snpnet_yt

_SLURM_JOBID=${SLURM_JOBID:=0} # use 0 for default value (for debugging purpose)
_SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID:=1}
mem=$( cat $0 | egrep '^#SBATCH --mem='  | awk -v FS='=' '{print $NF}' )
cores=$( cat $0 | egrep '^#SBATCH --cores='  | awk -v FS='=' '{print $NF}' )

script="/oak/stanford/groups/mrivas/users/${USER}/repos/rivas-lab/PRS/src/201912_batch/snpnet_batch.INI.sh"

if [ $# -gt 0 ] ; then offset=$1 ; else offset=0 ; fi
# if [ $# -gt 1 ] ; then pop=$2 ; else pop="white_british" ; fi

batch_idx=$(perl -e "print(${offset} + ${_SLURM_ARRAY_TASK_ID})")

############################################################
# job start
############################################################

echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-start] hostname=$(hostname); SLURM_JOBID=${_SLURM_JOBID}; SLURM_ARRAY_TASK_ID=${_SLURM_ARRAY_TASK_ID}" >&2

############################################################
# body
############################################################

bash ${script} --nCores ${cores} --mem ${mem} ${batch_idx}

############################################################
# job finish footer (for use with array-job module)
############################################################
echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-end] hostname=$(hostname); SLURM_JOBID=${_SLURM_JOBID}; SLURM_ARRAY_TASK_ID=${_SLURM_ARRAY_TASK_ID}" >&2
