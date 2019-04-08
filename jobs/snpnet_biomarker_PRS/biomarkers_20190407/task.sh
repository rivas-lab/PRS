#!/bin/bash
set -beEu -o pipefail

# pass the following paramters to your script
task_id=$1
memory=$2
threads=$3

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
keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"
#keep="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/biomarkers_20190406/test.keep.phe"
nPCs=10


GBE_ID=$( get_line_from_job_tsv  $job_tsv_file $task_id | cut -f1 )
phe_file="$(dirname $(dirname $(readlink -f $0)))/input_phe/${GBE_ID}.phe"
phe_type=$( get_line_from_job_tsv  $job_tsv_file $task_id | cut -f2 )
use_full_covars=$( get_line_from_job_tsv  $job_tsv_file $task_id | cut -f3 )

if [ ${use_full_covars} == "Y" ] ; then
    file_covar="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.tsv"
    covar_list_f="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20190406_biomarker_covar/biomarker_covar.colnames"
    covar_str="${file_covar} ${covar_list_f}"
else
    covar_str=""
fi

bash $script \
	${phe_file} ${phe_type} ${keep} ${output_dir} \
    ${memory} ${threads} ${app_id} ${nPCs} ${covar_str}

