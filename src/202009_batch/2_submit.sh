#!/bin/bash
set -beEuo pipefail

####################
# parse input

GBE_list_f=$1

####################
# configure parameters
run_name="$(basename ${GBE_list_f} .lst)"

####################
# parse optional cmdargs
refit="F"
if [ $# -gt 1 ] && [ $2 == "refit" ] ; then refit="T" ; fi

####################
# load module and mkdir log dir
ml load resbatch
if [ ! -d logs_${run_name} ] ; then mkdir logs_${run_name} ; fi

####################
# list GBE IDs
cat ${GBE_list_f} | egrep -v '^#' | awk 'length($0)>0' | while read GBE_ID ; do

####################
# submit jobs

    echo "${GBE_ID} (refit: ${refit})"
    jobname=snpnet$([ "${refit}" == "T" ] && echo ".refit" || echo "").${GBE_ID}

    resbatch.sh \
    --job_cmd_p      mrivas,normal,owners \
    --job_cmd_name   ${jobname} \
    --job_cmd_output logs_${run_name}/${jobname}.%A.out \
    --job_cmd_error  logs_${run_name}/${jobname}.%A.err \
    --job_cmd_time   2-0:00:00 \
    --mem 30000 -c 4 --mem_mult 2 --try_n 1 \
    --try_total 5 \
    --log logs_${run_name}/${jobname}.log \
    --src snpnet.sh - $([ "${refit}" == "T" ] && echo "--refit" || echo "") --run_name ${run_name} ${GBE_ID}

#     --job_cmd_p      mrivas \
#     --job_cmd_qos    high_p \

done
