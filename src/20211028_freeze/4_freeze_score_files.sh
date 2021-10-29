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

# copy biomarker PRS weights

cat ${biomarkers_mapping_f} | awk -v FS='\t' '(NR>1){print $1, $4}' \
| while read -r trait annotation ; do

echo $annotation $trait

done

exit 0

${PRS202110_d}/per_trait/${trait}.tsv