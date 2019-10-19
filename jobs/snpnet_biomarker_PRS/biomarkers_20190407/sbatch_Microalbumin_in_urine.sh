#!/bin/bash

#SBATCH --job-name=snpnet_Microalbumin_in_urine
#SBATCH   --output=snpnet_Microalbumin_in_urine.%A.out
#SBATCH    --error=snpnet_Microalbumin_in_urine.%A.err
#SBATCH --time=0:45:00
#SBATCH --qos=normal
#SBATCH -p owners,normal,mrivas
#SBATCH --nodes=1
#SBATCH --cores=5
#SBATCH --mem=60000
#SBATCH --constraint="CPU_GEN:HSW|CPU_GEN:BDW|CPU_GEN:SKX"
#SBATCH --mail-type=END,FAIL
#################
# Usage: $ sbatch --array=1-2,4%1 sbatch.sh
#
set -beEu -o pipefail

# automatically get cores and mem settings from the above
threads=$( cat $0 | egrep '^#SBATCH --cores=' | awk -v FS='=' '{print $NF}' )
memory=$(  cat $0 | egrep '^#SBATCH --mem='   | awk -v FS='=' '{print $NF}' )

#echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-start] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}; SLURM_ARRAY_TASK_ID = ${SLURM_ARRAY_TASK_ID}" >&2

#echo "[$0 $(date +%Y%m%d-%H%M%S)] [array-end] hostname = $(hostname) SLURM_JOBID = ${SLURM_JOBID}; SLURM_ARRAY_TASK_ID = ${SLURM_ARRAY_TASK_ID}" >&2

#!/bin/bash
set -beEu -o pipefail
task_id=57
job_tsv_file="jobs.tsv"

get_line_from_job_tsv () {
	job_tsv=$1
	task_id=$2
	
	cat $job_tsv | egrep -v '^#' | awk -v row=$task_id 'NR == row'
}

app_id=24983 # use master phe file 
method="snpnet_biomarker_PRS"
script="$OAK/users/$USER/repos/rivas-lab/PRS/src/${method}.sh"
dataset_name=$(basename $(dirname $(readlink -f $0)))
output_dir="$OAK/projects/PRS/private_output/${method}/${dataset_name}"
#keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"
#keep="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/biomarkers_20190406/test.keep.phe"
keep="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/input_phe/ukb24983_white_british.and.full_table.phe"
nPCs=10


GBE_ID=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $1}' )
phe_file="$(dirname $(dirname $(readlink -f $0)))/input_phe/${GBE_ID}.phe"
phe_type=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $2}' )
use_full_covars=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $3}' )

    
file_covar="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.tsv"
#covar_list_f="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.colnames"
covar_list_f="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/biomarkers_20190407/Microalbumin_in_urine.covars"
covar_str="${file_covar} ${covar_list_f}"

cat $covar_list_f | tr "\n" " "
echo ""

bash $script \
	${phe_file} ${phe_type} ${keep} ${output_dir} \
    ${memory} ${threads} ${app_id} ${nPCs} ${covar_str}

