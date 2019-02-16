#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: apply PLINK 2 --score" >&2
    echo "usage: $0 in_sumstats individuals_keep out_score" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$1
individuals_keep=$2
out_sumstats=$3

if [ $# -gt 3 ] ; then memory=$4 ; else memory=32000 ; fi
if [ $# -gt 4 ] ; then threads=$5 ; else threads=4 ; fi
if [ $# -gt 5 ] ; then app_id=$6 ; else app_id="24983" ; fi

plink_score () {
    in_sumstats=$1
    individuals_keep=$2
    out_score=$3

    # wrapper function of plink2 --score

    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"

    echo plink2 \
	--bfile ${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2 \
	--keep ${individuals_keep} \
	--threads ${threads} --memory ${memory} \
	--out ${out_score} \
	--score ${in_sumstats} 3 5 8 header
}

plink_score ${in_sumstats} ${individuals_keep} ${out_score}

