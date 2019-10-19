#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0 <betas> <phe_type>"
}

if [ $# -lt 2 ] ; then usage >&2 ; exit 1 ; fi

in_betas="$1"
phe_type="$2"
if [ $# -gt 2 ] ; then memory=$3 ;  else memory=25600 ; fi
if [ $# -gt 3 ] ; then threads=$4 ; else threads=4 ; fi
if [ $# -gt 4 ] ; then app_id=$5 ;  else app_id="24983" ; fi

phe_name=$(basename ${in_betas} | sed -e 's/.tsv.gz$//g')
helper_dir="$(dirname $(dirname $(readlink -f $0)))/helper"
src4score="${helper_dir}/plink-score.sh"

keep_file_dir="/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20190411"
pops=( "non_british_white" "african" "e_asian" "s_asian" )

file3snpnet_geno=${in_betas}

for pop in ${pops[@]} ; do
    keep="${keep_file_dir}/ukb24983_${pop}.phe"
    file4score="$(dirname $(dirname ${file3snpnet_geno}))/6_score_multi_ethnic/${pop}/${phe_name}.sscore"

    # step 4 : PLINK --score
    echo bash ${src4score} ${file3snpnet_geno} ${keep} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}
    bash ${src4score}      ${file3snpnet_geno} ${keep} ${file4score} ${phe_type} ${memory} ${threads} ${app_id}
done

