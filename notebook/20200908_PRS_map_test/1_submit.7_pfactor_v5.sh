#!/bin/bash
set -beEuo pipefail

####################
# configure parameters
run_name="7_pfactor_v5"

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
if [ $# -gt 0 ] ; then
    cat $1 |  awk 'length($0)>0'
else
    cat highconfidenceqc_gbe_map.tsv \
        | egrep -v 'AD_|TTE_' \
        | awk '{print $1}' \
        | awk 'NR > 3'
fi | while read GBE_ID ; do

####################
# submit jobs

    echo "${GBE_ID} (refit: ${refit})"
    jobname=snpnet$([ "${refit}" == "T" ] && echo ".refit" || echo "").${GBE_ID}

    resbatch.sh \
    --job_cmd_p      mrivas \
    --job_cmd_qos    high_p \
    --job_cmd_name   ${jobname} \
    --job_cmd_output logs_${run_name}/${jobname}.%A.out \
    --job_cmd_error  logs_${run_name}/${jobname}.%A.err \
    --job_cmd_time   2-0:00:00 \
    --mem 60000 -c 10 --mem_mult 2 --try_n 1 \
    --log logs_${run_name}/${jobname}.log \
    --src snpnet.sh - $([ "${refit}" == "T" ] && echo "--refit" || echo "") --run_name ${run_name} ${GBE_ID}

done

