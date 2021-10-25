#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

slurm_log_d=${SRCDIR}/logs
slurm_job_name=$(basename ${SRCNAME%.slurm.sh})
job_list_sh=${slurm_log_d}/${slurm_job_name}.jobs.sh
batch_size=1 # the number of jobs executed in an array task in SLURM.
memory=8000
cpus=1
sbatch_resources_str='-p mrivas --qos=high_p --nodes=1 --mem=8000 --cores=1 --time=30:00'

#############################
# generate a list of jobs
#############################

if [ ! -d "${slurm_log_d}" ] ; then mkdir -p "${slurm_log_d}" ; fi

cat /oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/data/traits_significant.tsv  | awk '(NR>1){print $2}' \
| while read -r trait ; do
    if [ ! -s /scratch/groups/mrivas/projects/PRS/private_output/20211025_sensitivity_analysis/output/${trait}.tsv ] ; then
        echo "bash ${SRCNAME%.slurm.sh}.sh ${trait}"
    fi
done > "${job_list_sh}"

#############################
# count the number of jobs and tasks (in array job)
#############################
n_jobs=$( cat "${job_list_sh}" | wc -l )
n_array_tasks=$(   perl -e "print(int(  (${batch_size} - 1 + ${n_jobs}) / ${batch_size} ))" )

#############################
# helper script for job submission
#############################
parasol_sbatch_sh="${HOME}/repos/yk-tanigawa/resbatch/parasol-sbatch.sh"
echo "## submission of ${n_jobs} jobs in ${n_array_tasks} tasks (each has up to ${batch_size} jobs) ##"
(
    # use sub-shell and print the executed command with set -x
    set -x
    sbatch ${sbatch_resources_str} \
        --job-name="${slurm_job_name}" \
        --output="${slurm_log_d}/${slurm_job_name}.%A.%a.out" \
        --error="${slurm_log_d}/${slurm_job_name}.%A.%a.err" \
        --array="1-${n_array_tasks}" \
        "${parasol_sbatch_sh}" \
        "${job_list_sh}" \
        "${batch_size}"
)
