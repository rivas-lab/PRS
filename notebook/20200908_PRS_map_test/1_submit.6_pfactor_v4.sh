#!/bin/bash
set -beEuo pipefail

####################
# configure parameters
run_name="6_pfactor_v4"

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
if [ "${refit}" == "T" ] ; then

    echo "${GBE_ID} (refit)"
    resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet.refit --output=logs_6_pfactor_v4/snpnet.refit.%A.out --error=logs_6_pfactor_v4/snpnet.refit.%A.err --time=2-0:00:00' --mem 120000 -c 10 --mem_mult 2 --try_n 1 --log logs_${run_name}/snpnet.refit.${GBE_ID}.log --src snpnet.sh - --refit --run_name ${run_name} ${GBE_ID}

else

    echo "${GBE_ID} (fit_w_val)"
    resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet --output=logs_6_pfactor_v4/snpnet.%A.out --error=logs_6_pfactor_v4/snpnet.%A.err --time=2-0:00:00' --mem 120000 -c 10 --mem_mult 2 --try_n 1 --log logs_${run_name}/snpnet.${GBE_ID}.log --src snpnet.sh - --run_name ${run_name} ${GBE_ID}

fi

done
