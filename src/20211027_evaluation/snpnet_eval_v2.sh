#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)
VERSION="2.0.0"
NUM_POS_ARGS="1"


GBE_ID=$1
GBE_CAT=$(echo ${GBE_ID} | sed -e 's/[0-9]\+//')

if [ "${GBE_CAT}" == "INI" ] || [ "${GBE_CAT}" == "QT_FC" ] ; then
    family='gaussian'
else
    family='binomial'
fi

source paths.sh

out_prefix="${project_d}/private_output/$(basename ${SRCDIR})/output/${GBE_ID}"

if [ ! -d $(dirname "${out_prefix}") ] ; then mkdir -p $(dirname "${out_prefix}") ; fi

if  [ ! -s "${out_prefix}.log"            ] ||
    [ ! -s "${out_prefix}.covarBETAs.tsv" ] ||
    [ ! -s "${out_prefix}.eval.tsv"       ] ||
    [ ! -s "${out_prefix}.percentile.tsv" ] ||
    [ ! -s "${out_prefix}.plot.pdf"       ] ||
    [ ! -s "${out_prefix}.plot.png"       ] ||
    [ ! -s "${out_prefix}.PRS_pval.tsv"   ] ; then

    run-simg.sh Rscript snpnet_eval_v2.R \
    ${out_prefix} \
    ${phe_f} \
    ${GBE_ID} \
    ${family} \
    'age,sex,Array,PC1,PC2,PC3,PC4,PC5,PC6,PC7,PC8,PC9,PC10' \
    'train_val=train_val,test=train_val,non_british_white=non_british_white,african=african,s_asian=s_asian,e_asian=e_asian' \
    ${project_d}/${PRS_f} > ${out_prefix}.log 2>&1

fi
