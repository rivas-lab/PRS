#!/bin/bash
set -beEu -o pipefail

# pass the following paramters to your script
task_id=$1
memory=$2
threads=$3

app_id=24983 # use master phe file 
method="clumped_snpnet_PRS"
script="$OAK/users/$USER/repos/rivas-lab/PRS/src/${method}.sh"
dataset_name=$(basename $(dirname $(readlink -f $0)))
output_dir="$OAK/projects/PRS/private_output/${method}/${dataset_name}"
keep="/oak/stanford/groups/mrivas/private_data/ukbb/${app_id}/sqc/population_stratification/ukb${app_id}_white_british.phe"
nPCs=10
phe_type="bin"

GBE_ID="HC${task_id}"
bash $script \
	${GBE_ID} ${phe_type} ${keep} ${output_dir} \
        ${memory} ${threads} ${app_id} ${nPCs}

