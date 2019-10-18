#!/bin/bash
#SBATCH --job-name=kkt-d6
#SBATCH --output=logs-debug6/kkt-d6.%A.out
#SBATCH  --error=logs-debug6/kkt-d6.%A.err
#SBATCH --nodes=1
#SBATCH --time=1-00:00:00
#SBATCH -p mrivas,normal

set -beEuo pipefail

cpu=$1
mem=$2

echo "[$0 $(date +%Y%m%d-%H%M%S)] [start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}" >&2
#################

Rscript debug-part6.R $cpu $mem

#################
echo "[$0 $(date +%Y%m%d-%H%M%S)] [end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID:=0}" >&2

