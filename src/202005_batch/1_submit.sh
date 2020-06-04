#!/bin/bash
set -beEuo pipefail

ml load resbatch

if [ $# -gt 0 ] ; then
    cat $1 
else
    cat highconfidenceqc_gbe_map.tsv \
        | egrep -v 'AD_|TTE_' \
        | awk '{print $1}' \
        | awk 'NR > 3'
fi | while read GBE_ID ; do

echo $GBE_ID
#resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet --output=logs/snpnet.%A.out --error=logs/snpnet.%A.err --time=2-0:00:00' --mem 30000 -c 4 --mem_mult 2 --try_n 1 --log logs/snpnet.${GBE_ID}.log --src snpnet.sh - ${GBE_ID} binomial

# re-submission
resbatch.sh --job_cmd 'sbatch -p mrivas --qos=high_p --job-name=snpnet --output=logs/snpnet.%A.out --error=logs/snpnet.%A.err --time=2-0:00:00' --mem 600000 -c 4 --mem_mult 1.5 --try_n 1 --log logs/snpnet.${GBE_ID}.log --src snpnet.sh - ${GBE_ID} binomial

done

