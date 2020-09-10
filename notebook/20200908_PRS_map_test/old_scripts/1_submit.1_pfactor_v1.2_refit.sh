#!/bin/bash
set -beEuo pipefail

get_family_from_GBE_ID () {
    local GBE_ID=$1

    GBE_CAT=$(echo $GBE_ID | sed -e "s/[0-9]//g")

    if [ "${GBE_CAT}" == "QT_FC" ] || [ "${GBE_CAT}" == "INI" ] ; then
        echo "gaussian"
    else
        echo "binomial"
    fi
}

####################

ml load resbatch

if [ ! -d logs ] ; then mkdir logs ; fi

if [ $# -gt 0 ] ; then
    cat $1 |  awk 'length($0)>0'
else
    cat highconfidenceqc_gbe_map.tsv \
        | egrep -v 'AD_|TTE_' \
        | awk '{print $1}' \
        | awk 'NR > 3'
fi | while read GBE_ID ; do

echo $GBE_ID
resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet.refit --output=logs/snpnet.refit.%A.out --error=logs/snpnet.refit.%A.err --time=2-0:00:00' --mem 60000 -c 10 --mem_mult 2 --try_n 1 --log logs/snpnet.${GBE_ID}.log --src snpnet.2_refit.sh - ${GBE_ID} $(get_family_from_GBE_ID ${GBE_ID})

# re-submission
#resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet --output=logs/snpnet.%A.out --error=logs/snpnet.%A.err --time=2-0:00:00' --mem 600000 -c 10 --mem_mult 1.5 --try_n 1 --log logs/snpnet.${GBE_ID}.log --src snpnet.sh - ${GBE_ID} $(get_family_from_GBE_ID ${GBE_ID})

done
