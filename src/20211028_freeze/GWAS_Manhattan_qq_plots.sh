#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f "${0}")
SRCDIR=$(dirname "${SRCNAME}")

source paths.sh

traits=(
BIN_FC2001747
BIN_FC1001747
BIN_FC4001747
BIN_FC5001747
HC702
INI30790
INI30840
)

for trait in "${traits[@]}" ; do

GBE_CAT=$(echo ${trait} | sed -e "s/[0-9]//g")

if  [ "${GBE_CAT}" == "INI" ] ||
    [ "${GBE_CAT}" == "QT_FC" ] ; then
    suffix="glm.linear.gz"
else
    suffix="glm.logistic.hybrid.gz"
fi

if [ ! -f "${SRCDIR}/plots/ukb24983.wb.${trait}.png" ] ; then

    run-simg.sh Rscript \
    "${HOME}/repos/rivas-lab/ukbb-tools/04_gwas/check_gwas/plots/gwas_plot_manhattan.R" \
    "${ukb24983_cal_gwas_d}/white_british/ukb24983_v2_hg19.${trait}.array-combined.${suffix}" \
    "${ukb24983_var_annot_f}" \
    "${SRCDIR}/plots/ukb24983.wb.${trait}.png"

fi

if [ ! -f "${SRCDIR}/plots/ukb24983.wb.${trait}.qq.png" ] ; then

    run-simg.sh Rscript \
    "${HOME}/repos/rivas-lab/ukbb-tools/04_gwas/check_gwas/plots/gwas_plot_qq.R" \
    "${ukb24983_cal_gwas_d}/white_british/ukb24983_v2_hg19.${trait}.array-combined.${suffix}" \
    "${SRCDIR}/plots/ukb24983.wb.${trait}.qq.png"

fi

done
