#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

source paths.sh

cat_or_zcat () {
    local file=$1
    if [ "${file%.gz}.gz" == "${file}" ] || [ "${file%.bgz}.bgz" == "${file}" ] ; then 
        zcat "${file}"
    elif [ "${file%.zst}.zst" == "${file}" ] ; then 
        zstdcat "${file}"
    else
        cat "${file}"
    fi
}

if [ ! -d "${PRS202110_d}/per_trait" ] ; then mkdir -p "${PRS202110_d}/per_trait" ; fi

cat ${trait_list_f} | awk -v FS='\t' '((NR>1) && ($3 != "Biomarkers")){print $1}' \
| while read -r trait ; do
    src_f=$(echo ${PRS202009_BETA_f} | sed -e "s%__TRAIT__%${trait}%g")
    dst_f="${PRS202110_d}/per_trait/${trait}.snpnetBETAs.tsv"
    cat_or_zcat ${src_f} > ${dst_f}
done

# copy biomarker PRS weights
cat ${biomarkers_mapping_f} | awk -v FS='\t' '(NR>1){print $1, $4}' \
| while read -r trait annotation ; do
    src_f=$(echo ${biomarkers_BETA_f} | sed -e "s%__TRAIT__%${annotation}%g")
    dst_f="${PRS202110_d}/per_trait/${trait}.snpnetBETAs.tsv"
    cat_or_zcat ${src_f} > ${dst_f}
done
