#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: Use PLINK to subset genotype data into variants specified with extract file" >&2
    echo "usage: $0 in_bfile extract out_bfile [memory] [threads] [app_id]" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_bfile=$1
variants_extract=$(readlink -f $2)
out_bfile=$3

if [ $# -gt 3 ] ; then memory=$4  ; else memory=32000 ; fi
if [ $# -gt 4 ] ; then threads=$5 ; else threads=4 ; fi
if [ $# -gt 5 ] ; then app_id=$6  ; else app_id="24983" ; fi


plink_extract () {
    in=$1
    extract=$2
    out=$3

    # wrapper function of plink2 --score
    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"
    bed=${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2_pgen.pgen
    bim=${bed%.pgen}.bim
    fam=${bed%.pgen}.fam

    plink2 \
        --bfile $in \
	--extract ${extract} \
	--threads ${threads} --memory ${memory} \
	--out ${out} \
	--make-bed
}

if [ ! -f ${out_bfile}.bed ] && [ ! -f ${out_bfile}.bim ] && [ ! -f ${out_bfile}.fam ] ; then
	plink_extract ${in_bfile} ${variants_extract} ${out_bfile}
fi

