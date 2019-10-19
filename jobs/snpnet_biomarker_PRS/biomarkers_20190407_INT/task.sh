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
nPCs=10


GBE_ID=$( get_line_from_job_tsv  $job_tsv_file $task_id | awk '{print $1}' )
phe_file="$(dirname $(dirname $(readlink -f $0)))/input_phe/INT/${GBE_ID}.phe"
phe_type=qt

file_covar="${OAK}/private_data/ukbb/${app_id}/sqc/ukb${app_id}_GWAS_covar.phe"
covar_list_f="/oak/stanford/groups/mrivas/projects/PRS/private_data/snpnet_biomarker_PRS_input_phe/INT/covar.lst"    
covar_list_f="None"
covar_str="${file_covar} ${covar_list_f}"

bash $script \
	${phe_file} ${phe_type} ${keep} ${output_dir} \
    ${memory} ${threads} ${app_id} ${nPCs} ${covar_str}

