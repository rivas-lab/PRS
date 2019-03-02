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

app_id=16698
script="$OAK/users/$USER/repos/rivas-lab/PRS/src/vanilla_PRS.sh"
dataset_name=$(basename $(dirname $(readlink -f $0)))
output_dir="$OAK/projects/PRS/private_output/vanilla_PRS/${dataset_name}"
keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"
nPCs=4
phe_type="bin"

phe_file=$( get_line_from_job_tsv  $job_tsv_file $task_id )
bash $script \
	${phe_file} ${phe_type} ${keep} ${output_dir} \
        ${memory} ${threads} ${app_id} ${nPCs}

