#!/bin/bash
set -beEuo pipefail

ml load snpnet_yt

genotype_pfile="/scratch/groups/mrivas/ukbb24983/array_combined/pgen/ukb24983_cal_hla_cnv"
phenotype_name=$1
project_dir="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch"
results_dir="${project_dir}/${phenotype_name}"

bash $snpnet_dir/helpers/export_intermediate_results.sh \
    ${genotype_pfile} ${phenotype_name} ${results_dir}

