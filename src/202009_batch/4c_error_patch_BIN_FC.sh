#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

source /oak/stanford/groups/mrivas/software/snpnet/snpnet_v.0.3.17/helpers/snpnet_misc.sh
results_sub_dir="1_fit_w_val"
project_dir="/scratch/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"

GBE_ID=$1

BIN_FC_d=$(find ${project_dir}/BIN_FC.1-400 ${project_dir}/BIN_FC.401-515 -mindepth 1 -maxdepth 1 -type d -name ${GBE_ID})
BIN_d=$(find ${project_dir}/BIN.1-400 ${project_dir}/BIN.401-737 -mindepth 1 -maxdepth 1 -type d -name ${GBE_ID})

mark_to_delete () {
    dir=$1
    mv ${dir} $(dirname ${dir})/__delete.$(basename ${dir})
}

use_BIN () {
    echo "BIN"
    if [ -d "${BIN_FC_d}" ] ; then
        mark_to_delete ${BIN_FC_d}
    fi
}

use_BIN_FC () {
    echo "BIN_FC"
    if [ -d "${BIN_d}" ] ; then
        mark_to_delete ${BIN_d}
    fi
    mv ${BIN_FC_d} ${BIN_d}
}

echo ${GBE_ID} ${BIN_d} ${BIN_FC_d}

if   [ "${BIN_FC_d}" == "" ] || [ ! -d "${BIN_FC_d}" ] ; then
    use_BIN

elif [ "${BIN_d}" == "" ] || [ ! -d "${BIN_d}" ] ; then
    use_BIN_FC

elif [ -s ${BIN_d}/${results_sub_dir}/snpnet.tsv ] ; then
    use_BIN
    
elif [ -s ${BIN_FC_d}/${results_sub_dir}/snpnet.tsv ] ; then
    use_BIN_FC

elif [ -s ${BIN_d}/${results_sub_dir}/snpnet.RData ] ; then
    use_BIN

elif [ -s ${BIN_FC_d}/${results_sub_dir}/snpnet.RData ] ; then
    use_BIN_FC

else
    # let's compare how many iterations were performed
    prevIter_BIN_FC="$(find_prevIter ${BIN_FC_d}/${results_sub_dir})"
    prevIter_BIN="$(find_prevIter ${BIN_d}/${results_sub_dir})"
    
    if [ ${prevIter_BIN} -ge ${prevIter_BIN_FC} ] ; then
        use_BIN
    else
        use_BIN_FC
    fi
fi
