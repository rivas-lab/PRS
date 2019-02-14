#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: apply LD clumping with PLINK 1.9." >&2
    echo "usage: $0 in_sumstats individuals_keep out_sumstats" >&2
    echo "  in_sumstats is a GWAS summary statistics of array-genotyped variants" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$1
individuals_keep=$2
out_sumstats=$3

if [ $# -gt 3 ] ; then memory=$4 ; else memory=32000 ; fi
if [ $# -gt 4 ] ; then threads=$5 ; else threads=4 ; fi
if [ $# -gt 5 ] ; then app_id=$6 ; else app_id="24983" ; fi


plink_clump () {
    in_sumstats=$1
    individuals_keep=$2
    out_sumstats=$3

    # wrapper function of plink --clump

    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"

    plink \
	--bfile ${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2 \
	--keep ${individuals_keep} \
	--threads ${threads} --memory ${memory} \
	--clump-snp-field ID \
	--clump ${in_sumstats} \
	--out ${out_sumstats}
}

plink_clump ${in_sumstats} ${individuals_keep} ${out_sumstats}

