#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

ml load resbatch

cancelled_GBE_IDs=$(basename ${SRCNAME} .sh).lst

grep "only 0's may be mixed with negative subscripts" logs_*/snpnet*.out \
| awk -v FS='.' '{print $2}' \
| sort -uV > ${cancelled_GBE_IDs}

cat ${cancelled_GBE_IDs} \
| awk 'length($0)>0' \
| while read GBE_ID ; do 
    echo $GBE_ID
    resbatch_log=logs_$(echo ${GBE_ID} | sed -e 's/[0-9]*//g')/snpnet.${GBE_ID}.log
    if [ -f ${resbatch_log} ] ; then
        cancel-resbatch-jobs.sh ${resbatch_log}
    fi
done

