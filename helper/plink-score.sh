#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: apply PLINK 2 --score" >&2
    echo "usage: $0 in_sumstats individuals_keep out_score" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

in_sumstats=$1
individuals_keep=$2
out_score=$3
phe_type=$4

if [ $# -gt 4 ] ; then memory=$5  ; else memory=32000 ; fi
if [ $# -gt 5 ] ; then threads=$6 ; else threads=4 ; fi
if [ $# -gt 6 ] ; then app_id=$7  ; else app_id="24983" ; fi

if [ $phe_type == "bin" ] || [ $phe_type == "logistic" ] ; then 
	score_col="10"
elif [ $phe_type == "qt" ] || [ $phe_type == "linear" ] ; then
	score_col="9"
fi 

plink_score () {
    in_sumstats=$1
    individuals_keep=$2
    out_score=$3
    score_col=$4

    # wrapper function of plink2 --score

    UKBB_data_dir="$OAK/private_data/ukbb/${app_id}"
    bed=${UKBB_data_dir}/cal/pgen/ukb${app_id}_cal_cALL_v2_pgen.pgen
    bim=${bed%.pgen}.bim
    fam=${bed%.pgen}.fam

    plink2 \
	--pgen $bed --bim $bim --fam $fam \
	--keep ${individuals_keep} \
	--threads ${threads} --memory ${memory} \
	--out ${out_score%.sscore} \
	--score ${in_sumstats} 3 5 ${score_col} header
}

if [ ! -f ${out_score} ] ; then
	plink_score ${in_sumstats} ${individuals_keep} ${out_score} ${score_col}
fi

