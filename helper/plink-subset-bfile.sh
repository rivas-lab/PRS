#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: Use PLINK to subset genotype data into individuals specified with keep file" >&2
    echo "usage: $0 individuals_keep out_bfile [memory] [threads] [app_id]" >&2
}

if [ $# -lt 2 ] ; then usage ; exit 1 ; fi

individuals_keep=$(readlink -f $1)
out_bfile=$2

if [ $# -gt 2 ] ; then memory=$3  ; else memory=32000 ; fi
if [ $# -gt 3 ] ; then threads=$4 ; else threads=4 ; fi
if [ $# -gt 4 ] ; then app_id=$5  ; else app_id="24983" ; fi

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) 
echo "tmp_dir = $tmp_dir" >&2
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

plink_bed_subset () {
    keep=$1
    out=$2

    # wrapper function of plink2 --score
    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"
    bed=${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2_pgen.pgen
    bim=${bed%.pgen}.bim
    fam=${bed%.pgen}.fam

    plink2 \
	--pgen $bed --bim $bim --fam $fam \
	--keep ${keep} \
	--threads ${threads} --memory ${memory} \
	--out ${out} \
	--make-bed
}


if [ ! -f ${out_bfile}.bed ] && [ ! -f ${out_bfile}.bim ] && [ ! -f ${out_bfile}.fam ] ; then
    tmp_out_bfile=${tmp_dir}/$(basename ${out_bfile})
	plink_bed_subset ${individuals_keep} ${tmp_out_bfile}
    for ext in "log" "bim" "fam" "bed" ; do
        cp ${tmp_out_bfile}.${ext} ${out_bfile}.${ext}
    done
fi

