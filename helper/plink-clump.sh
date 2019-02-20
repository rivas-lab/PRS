#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: apply LD clumping with PLINK 1.9." >&2
    echo "usage: $0 in_sumstats individuals_keep out_sumstats [clump_p1] [memory (default: 32000)] [threads (default: 4)] [application ID (default 24983)]" >&2
    echo "  in_sumstats is a GWAS summary statistics of array-genotyped variants" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$1
individuals_keep=$2
out_sumstats=$3
if [ $# -gt 3 ] ; then clump_p1=$4 ;  else clump_p1="1e-4" ; fi
if [ $# -gt 4 ] ; then memory=$5 ;    else memory=32000 ; fi
if [ $# -gt 5 ] ; then threads=$6 ;   else threads=4 ; fi
if [ $# -gt 6 ] ; then app_id=$7 ;    else app_id="24983" ; fi

plink_clump () {
    in_sumstats=$1
    individuals_keep=$2
    out_sumstats=$3
    clump_p1=$4

    # wrapper function of plink --clump

    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"

    plink \
	--bfile ${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2 \
	--keep ${individuals_keep} \
	--threads ${threads} --memory ${memory} \
	--clump-snp-field ID \
	--clump ${in_sumstats} \
	--clump-p1 ${clump_p1} \
	--out ${out_sumstats}
}

plink_clump ${in_sumstats} ${individuals_keep} ${out_sumstats} ${clump_p1}

