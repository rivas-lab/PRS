#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: apply LD clumping with PLINK 1.9." >&2
    echo "usage: $0 in_sumstats individuals_keep out_sumstats [clump_p1] [memory (default: 32000)] [threads (default: 4)] [application ID (default 24983)]" >&2
    echo "  in_sumstats is a GWAS summary statistics of array-genotyped variants" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$(readlink -f $1)
individuals_keep=$(readlink -f $2)
out_sumstats=$3
if [ $# -gt 3 ] ; then clump_p1=$4 ;  else clump_p1="1e-4" ; fi
if [ $# -gt 4 ] ; then memory=$5 ;    else memory=32000 ; fi
if [ $# -gt 5 ] ; then threads=$6 ;   else threads=4 ; fi
if [ $# -gt 6 ] ; then app_id=$7 ;    else app_id="24983" ; fi

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir"
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

copy_with_check () {
        src=$(readlink -f $1)
        dst=$2
	echo "[copy_with_check] $src $dst"
        if [ -f $src ] || [ -d $src ] ; then
                if [ ! -d $(dirname $dst) ] ; then mkdir -p $(dirname $dst) ; fi
        fi
        if [ -f $src ] && [ ! -f $dst ] ; then cp -a  $src $dst ; fi
        if [ -d $src ] && [ ! -d $dst ] ; then cp -ar $src $dst ; fi
}

plink_clump () {
    clump_in_sumstats=$(readlink -f $1)
    clump_individuals_keep=$(readlink -f $2)
    clump_out_sumstats=${3%.clumped.gz}
    clump_p1=$4

    # wrapper function of plink --clump

    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"

    plink \
	--bfile ${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2 \
	--keep ${clump_individuals_keep} \
	--threads ${threads} --memory ${memory} \
	--clump-snp-field ID \
	--clump ${clump_in_sumstats} \
	--clump-p1 ${clump_p1} \
	--out ${clump_out_sumstats}

    bgzip ${clump_out_sumstats}.clumped
}

echo ${out_sumstats}

if [ ! -f ${out_sumstats} ]  ; then
	tmp_out_sumstats=${tmp_dir}/$(basename $out_sumstats)
	echo ${tmp_out_sumstats} ${out_sumstats}
	plink_clump ${in_sumstats} ${individuals_keep} ${tmp_out_sumstats} ${clump_p1}
	copy_with_check ${tmp_out_sumstats} ${out_sumstats}
fi

