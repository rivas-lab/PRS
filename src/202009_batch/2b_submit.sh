#!/bin/bash
set -beEuo pipefail

####################
# parse input

GBE_tsv_f=$1

####################
# configure parameters
#run_name="$(basename ${GBE_list_f} .lst)"

####################
# parse optional cmdargs
refit="F"
if [ $# -gt 1 ] && [ $2 == "refit" ] ; then refit="T" ; fi

####################
# load module and mkdir log dir
ml load resbatch

####################
# list GBE IDs
for mem in 120000 240000 480000 960000 ; do
    new_mem=$(perl -e "print(${mem} * 5 / 4)")
    cat ${GBE_tsv_f} | awk -v mem=${mem} '(NR>1 && $3>1 && $4 == mem){print $1, $2}' \
        | while read GBE_ID run_name; do 

    if [ ! -d logs_${run_name} ] ; then mkdir logs_${run_name} ; fi
####################
# submit jobs

    echo "${GBE_ID} (refit: ${refit}) ${run_name} mem=${new_mem}"
    jobname=snpnet$([ "${refit}" == "T" ] && echo ".refit" || echo "").${GBE_ID}

    resbatch.sh \
    --job_cmd_p      mrivas,normal,owners \
    --job_cmd_name   ${jobname} \
    --job_cmd_output logs_${run_name}/${jobname}.%A.out \
    --job_cmd_error  logs_${run_name}/${jobname}.%A.err \
    --job_cmd_time   1-0:00:00 \
    --mem ${new_mem} -c 4 --mem_mult 2 --try_n 1 \
    --try_total 3 \
    --log logs_${run_name}/${jobname}.log \
    --src snpnet.sh - $([ "${refit}" == "T" ] && echo "--refit" || echo "") --run_name ${run_name} ${GBE_ID}

#     --job_cmd_p      mrivas \
#     --job_cmd_qos    high_p \

done
done

