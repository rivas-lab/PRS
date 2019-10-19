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

script="/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/src/snpnet_prediction_adhock.sh"
in_file=$( get_line_from_job_tsv  $job_tsv_file $task_id )

bash $script $in_file "qt" $memory $threads

