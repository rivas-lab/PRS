#!/bin/bash
set -beEuo pipefail

####################
# configure parameters
run_name="4_regDoms_pfactor"

####################
# parse optional cmdargs
refit="F"
if [ $# -gt 1 ] && [ $2 == "refit" ] ; then refit="T" ; fi

####################
# load module and mkdir log dir
ml load resbatch
if [ ! -d logs_4_regDoms_pfactor ] ; then mkdir logs_4_regDoms_pfactor ; fi

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

p_factor_file=/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test/4_regDoms_pfactor/penalty.v3.${GBE_ID}.rds

if [ -f ${p_factor_file} ] ; then

####################
# submit jobs
if [ "${refit}" == "T" ] ; then

    echo "${GBE_ID} (refit)"
    resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet.refit --output=logs_4_regDoms_pfactor/snpnet.refit.%A.out --error=logs_4_regDoms_pfactor/snpnet.refit.%A.err --time=2-0:00:00' --mem 120000 -c 10 --mem_mult 2 --try_n 1 --log logs_4_regDoms_pfactor/snpnet.refit.${GBE_ID}.log --src snpnet.sh - --p_factor_file ${p_factor_file} --refit --run_name ${run_name} ${GBE_ID}

else

    echo "${GBE_ID} (fit_w_val)"
    resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet --output=logs_4_regDoms_pfactor/snpnet.%A.out --error=logs_4_regDoms_pfactor/snpnet.%A.err --time=2-0:00:00' --mem 120000 -c 10 --mem_mult 2 --try_n 1 --log logs_4_regDoms_pfactor/snpnet.${GBE_ID}.log --src snpnet.sh - --p_factor_file ${p_factor_file} --run_name ${run_name} ${GBE_ID}

fi

fi

done
