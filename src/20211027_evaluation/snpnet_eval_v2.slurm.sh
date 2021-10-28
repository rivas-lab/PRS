#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

slurm_log_d=${SRCDIR}/slurm_logs
slurm_job_name=$(basename ${SRCNAME%.slurm.sh})
job_list_sh=${slurm_log_d}/${slurm_job_name}.jobs.sh
batch_size=1 # the number of jobs executed in an array task in SLURM.
sbatch_resources_str='-p mrivas --qos=high_p --nodes=1 --mem=12000 --cores=1 --time=2-00:00'

#############################
# generate a list of jobs
#############################

source paths.sh

cat_or_zcat () {
    local file=$1
    if [ "${file%.gz}.gz" == "${file}" ] || [ "${file%.bgz}.bgz" == "${file}" ] ; then
        zcat "${file}"
    elif [ "${file%.zst}.zst" == "${file}" ] ; then
        zstdcat "${file}"
    else
        cat "${file}"
    fi
}

if [ ! -d "${slurm_log_d}" ] ; then mkdir -p "${slurm_log_d}" ; fi

out_dir="${project_d}/private_output/$(basename ${SRCDIR})/output"

if [ ! -d "${out_dir}" ] ; then mkdir -p "${out_dir}" ; fi

find "${out_dir}"  -type f | sort > "${slurm_log_d}/output_files.txt"

# cat_or_zcat ${project_d}/${PRS_f} | awk 'NR==1' | tr '\t' '\n' | awk 'NR>94' \
! cat_or_zcat "${project_d}/${PRS_f}" | head -n1 | tr '\t' '\n' \
| awk 'NR>94' | sed -e 's/^PRS_//' \
| while read -r GBE_ID ; do

    out_prefix="${out_dir}/${GBE_ID}"

    # we will check the resulting files
    grep_pattern="${out_prefix}.log|${out_prefix}.covarBETAs.tsv|${out_prefix}.eval.tsv|${out_prefix}.percentile.tsv|${out_prefix}.plot.pdf|${out_prefix}.plot.png|${out_prefix}.PRS_pval.tsv"

    grep_wc_l=$(grep -E "${grep_pattern}" "${slurm_log_d}/output_files.txt" | wc -l)

    if [ "${grep_wc_l}" -ne 7 ] ; then
        echo "bash ${SRCNAME%.slurm.sh}.sh ${GBE_ID}"
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

(
    # use sub-shell and print the executed command with set -x
    set -x
    sbatch ${sbatch_resources_str} \
        --job-name="${slurm_job_name}" \
        --output="${slurm_log_d}/${slurm_job_name}.%A.%a.out" \
        --error="${slurm_log_d}/${slurm_job_name}.%A.%a.err" \
        --array="1-${n_array_tasks}%100" \
        "${parasol_sbatch_sh}" \
        "${job_list_sh}" \
        "${batch_size}"
)