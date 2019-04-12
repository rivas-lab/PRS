#!/bin/bash
set -beEu -o pipefail

# pass the following paramters to your script
task_id=$1
memory=$2
threads=$3

job_tsv_file="jobs.tsv"

get_line_from_job_tsv () {
	local job_tsv=$1
	local task_id=$2
	
	cat $job_tsv | egrep -v '^#' | awk -v row=$task_id 'NR == row'
}

OAK="/oak/stanford/groups/mrivas"
app_id=24983 # use master phe file 
method="snpnet_biomarker_PRS"
script="$OAK/users/$USER/repos/rivas-lab/PRS/src/${method}.sh"
#dataset_name=$(basename $(dirname $(readlink -f $0)))
dataset_name="biomarkers_20190407"
output_dir="$OAK/projects/PRS/private_output/${method}/${dataset_name}"
#keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"
#keep="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/biomarkers_20190406/test.keep.phe"
keep="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/snpnet_biomarker_PRS/input_phe/ukb24983_white_british.and.full_table.phe"
nPCs=10


GBE_ID=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $1}' )
input_phe_dir="/oak/stanford/groups/mrivas/projects/PRS/private_data/snpnet_biomarker_PRS_input_phe"
#phe_file="$(dirname $(dirname $(readlink -f $0)))/input_phe/${GBE_ID}.phe"
phe_file="${input_phe_dir}/${GBE_ID}.phe"
phe_type=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $2}' )
use_full_covars=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $3}' )

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

