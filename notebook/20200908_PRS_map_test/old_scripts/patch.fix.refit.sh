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

GBE_ID=$1

ml load R/3.6 gcc

Rscript patch.fix.refit.R ${GBE_ID}

bash snpnet.2_refit.sh ${GBE_ID} $(get_family_from_GBE_ID ${GBE_ID})
