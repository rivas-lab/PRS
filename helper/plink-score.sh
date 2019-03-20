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
	score_col="OR"
elif [ $phe_type == "qt" ] || [ $phe_type == "linear" ] ; then
	score_col="BETA"
fi 

get_col_idx () {
    in_file=$(readlink -f $1)
    col_key=$2

    if [ ${in_file%.gz}.gz == ${in_file} ] ; then 
        zcat $in_file 
    else 
        cat $in_file 
    fi | awk 'NR==1' | tr "\t" "\n" \
    | awk -v key=${col_key} '($0 == key){print NR}'
}

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
	--score ${in_sumstats} $( get_col_idx ${in_sumstats} ID ) $( get_col_idx ${in_sumstats} A1 ) $( get_col_idx ${in_sumstats} ${score_col} ) header cols=maybefid,maybesid,phenos,nmissallele,dosagesum,scoreavgs,denom,scoresums
}

#if [ ! -f ${out_score} ] ; then
	plink_score ${in_sumstats} ${individuals_keep} ${out_score} ${score_col}
#fi

