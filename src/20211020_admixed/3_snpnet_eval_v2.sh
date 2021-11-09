#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)
VERSION="2.1.0"
NUM_POS_ARGS="1"


GBE_ID=$1
GBE_CAT=$(echo ${GBE_ID} | sed -e 's/[0-9]\+//')

if [ "${GBE_CAT}" == "INI" ] || [ "${GBE_CAT}" == "QT_FC" ] ; then
    family='gaussian'
else
    family='binomial'
fi

phe_f="/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20211020.phe.zst"
snpnet_res_d="/scratch/groups/mrivas/projects/PRS/private_output/20211020_admixed/snpnet.admixed/${GBE_ID}/2_refit"

out_prefix="${snpnet_res_d}/${GBE_ID}"
PRS_f="${snpnet_res_d}/${GBE_ID}.sscore.zst"

if [ ! -d $(dirname "${out_prefix}") ] ; then mkdir -p $(dirname "${out_prefix}") ; fi

if  [ ! -s "${out_prefix}.eval.log.gz"       ] ||
    [ ! -s "${out_prefix}.covarBETAs.tsv.gz" ] ||
    [ ! -s "${out_prefix}.eval.tsv.gz"       ] ||
    [ ! -s "${out_prefix}.percentile.tsv.gz" ] ||
    [ ! -s "${out_prefix}.plot.pdf"          ] ||
    [ ! -s "${out_prefix}.plot.png"          ] ||
    [ ! -s "${out_prefix}.PRS_pval.tsv.gz"   ] ; then

    run-simg.sh Rscript snpnet_eval_v2.R \
    ${out_prefix} \
    ${phe_f} \
    ${GBE_ID} \
    ${family} \
    'age,sex,Array,Global_PC1,Global_PC2,Global_PC3,Global_PC4,Global_PC5,Global_PC6,Global_PC7,Global_PC8,Global_PC9,Global_PC10,Global_PC11,Global_PC12,Global_PC13,Global_PC14,Global_PC15,Global_PC16,Global_PC17,Global_PC18' \
    'white_british=white_british,non_british_white=non_british_white,african=african,s_asian=s_asian,e_asian=e_asian,related=related,others:train_val=others:train_val,others:test=others:train_val' \
    ${PRS_f} > ${out_prefix}.eval.log 2>&1
    gzip -f -9 ${out_prefix}.eval.log
fi
