#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

slurm_log_d=${SRCDIR}/slurm_logs
slurm_job_name=$(basename ${SRCNAME%.slurm.sh})
job_list_sh=${slurm_log_d}/${slurm_job_name}.jobs.sh
batch_size=1 # the number of jobs executed in an array task in SLURM.
sbatch_resources_str='-p mrivas --qos=high_p --nodes=1 --mem=16000 --cores=1 --time=6:00:00'


if [ $# -ge 1 ] && [ "$1" == "dry-run" ] ; then dry_run="TRUE" ; else dry_run="FALSE" ; fi

#############################
# generate a list of jobs
#############################

source paths.sh

if [ ! -d "${slurm_log_d}" ] ; then mkdir -p "${slurm_log_d}" ; fi

cat ${traits_w_metrics_f}  | awk '(NR>1){print $1}' \
| while read -r trait ; do
    if [ ! -s /scratch/groups/mrivas/projects/PRS/private_output/20211025_sensitivity_analysis/output2/${trait}.tsv ] ; then
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

echo "## ${job_list_sh} ##"

if [ ${dry_run} != "TRUE" ] ; then

(
    # use sub-shell and print the executed command with set -x
    set -x
    sbatch ${sbatch_resources_str} \
        --job-name="${slurm_job_name}" \
        --output="${slurm_log_d}/${slurm_job_name}.%A.%a.out" \
        --error="${slurm_log_d}/${slurm_job_name}.%A.%a.err" \
        --array="1-${n_array_tasks}%10" \
        "${parasol_sbatch_sh}" \
        "${job_list_sh}" \
        "${batch_size}"
)

fi
