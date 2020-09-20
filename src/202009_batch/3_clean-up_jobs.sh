#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

project_dir="/scratch/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"

find ${project_dir} -name "snpnet.RData" \
| while read f ; do echo $(basename $(dirname $(dirname $f))) ; done \
| while read GBE_ID ; do 
    echo $GBE_ID
    resbatch_log=logs_$(echo ${GBE_ID} | sed -e 's/[0-9]*//g')/snpnet.${GBE_ID}.log
    if [ -f ${resbatch_log} ] ; then
        cancel-resbatch-jobs.sh ${resbatch_log}
    fi
done
