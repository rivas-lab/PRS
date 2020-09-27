#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

source /oak/stanford/groups/mrivas/software/snpnet/snpnet_v.0.3.17/helpers/snpnet_misc.sh
results_sub_dir="1_fit_w_val"
project_dir="/scratch/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"

GBE_ID=$1

# here, old_d has the correct file path
old_d=$(find ${project_dir}/HC.1-400  ${project_dir}/HC.401-800  ${project_dir}/HC.801-1103  -mindepth 1 -maxdepth 1 -type d -name ${GBE_ID})
new_d=$(find ${project_dir}/patch_v.0.3.17.HC.1-400 ${project_dir}/patch_v.0.3.17.HC.401-671 -mindepth 1 -maxdepth 1 -type d -name ${GBE_ID})

mark_to_delete () {
    dir=$1
    mv ${dir} $(dirname ${dir})/__delete.$(basename ${dir})
}

use_old_d () {
    echo "old_d"
    if [ -d "${new_d}" ] ; then
        mark_to_delete ${new_d}
    fi
}

use_new_d () {
    echo "new_d"
    if [ -d "${old_d}" ] ; then
        mark_to_delete ${old_d}
    fi
    mv ${new_d} ${old_d}
}

echo ${GBE_ID} ${old_d} ${new_d}

if   [ "${new_d}" == "" ] || [ ! -d "${new_d}" ] ; then
    use_old_d

elif [ "${old_d}" == "" ] || [ ! -d "${old_d}" ] ; then
    use_new_d

elif [ -s ${old_d}/${results_sub_dir}/snpnet.tsv ] ; then
    use_old_d
    
elif [ -s ${new_d}/${results_sub_dir}/snpnet.tsv ] ; then
    use_new_d

elif [ -s ${old_d}/${results_sub_dir}/snpnet.RData ] ; then
    use_old_d

elif [ -s ${new_d}/${results_sub_dir}/snpnet.RData ] ; then
    use_new_d

else
    # let's compare how many iterations were performed
    prevIter_old="$(find_prevIter ${old_d}/${results_sub_dir})"
    prevIter_new="$(find_prevIter ${new_d}/${results_sub_dir})"
    
    if [ ${prevIter_old} -ge ${prevIter_new} ] ; then
        use_old_d
    else
        use_new_d
    fi
fi
