#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

####################
# parse optional cmdargs
refit="F"
if [ $# -gt 0 ] && [ $1 == "refit" ] ; then refit="T" ; fi

####################
project_dir="/scratch/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"
results_sub_dir=$([ "${refit}" == "T" ] && echo "2_refit" || echo "1_fit_w_val")
test_run_f="/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test/7_pfactor_v5/__GBE_ID__/${results_sub_dir}/snpnet.eval.tsv"
out_eval_f="${project_dir}/snpnet.eval.${results_sub_dir}.tsv"
out_gdrive=gdrive://rivas-lab$(echo ${project_dir} | sed -e 's%/scratch%%g' | sed -e 's%/oak/stanford%%g' | sed -e 's%/groups/mrivas%%g' | sed -e 's%private_output/%%g')

header_common="#phenotype_name:split:geno:covar:geno_covar:geno_delta:n_variables"
header_binomial="${header_common}:case_n:control_n"
header_gaussian="${header_common}:n"

ml load R/3.6 gcc rclone

{
    echo ${header_gaussian} | tr ':' '\t'

    for GBE_ID in INI50 INI21001 ; do
        cat $(echo ${test_run_f} | sed -e "s/__GBE_ID__/${GBE_ID}/g") | egrep -v '^#' | awk -v FS='\t' 'NF==8'
    done

    ! find ${project_dir} -mindepth 4 -maxdepth 4 -type f -name "snpnet.eval.tsv" | egrep    "${project_dir}/INI|${project_dir}/QT" | grep ${results_sub_dir} | parallel -k 'cat {}' | egrep -v '^#' | awk -v FS='\t' 'NF==8'

} >  ${out_eval_f%.tsv}.gaussian.tsv 

echo ${out_eval_f%.tsv}.gaussian.tsv

{
    echo ${header_binomial} | tr ':' '\t'

    for GBE_ID in HC269 HC382 ; do
        cat $(echo ${test_run_f} | sed -e "s/__GBE_ID__/${GBE_ID}/g") | egrep -v '^#' | awk -v FS='\t' 'NF==9'
    done

    ! find ${project_dir} -mindepth 4 -maxdepth 4 -type f -name "snpnet.eval.tsv" | egrep -v "${project_dir}/INI|${project_dir}/QT" | grep ${results_sub_dir} | parallel -k 'cat {}' | egrep -v '^#' | awk -v FS='\t' 'NF==9'
} >  ${out_eval_f%.tsv}.binomial.tsv

echo ${out_eval_f%.tsv}.binomial.tsv

Rscript /dev/stdin ${out_eval_f} << EOF
####################################################################
args <- commandArgs(trailingOnly=TRUE)
suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(googlesheets)
}))

suppressWarnings(suppressMessages({
    gs_auth(token = "/home/users/ytanigaw/.googlesheets_token.rds")
    
    'https://docs.google.com/spreadsheets/d/1gwzS0SVZBSKkkHgsoqB5vHo5JpUeYYz8PK2RWrHEq3A' %>%
    gs_url() %>%  gs_read(
        ws = 'GBE_names', 
        col_types = cols('Units_of_measurement' = col_character())
    ) -> GBE_names_df    
}))

'/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/05_gbe/extras/20200812_GBE_category/GBE_category.20200812.tsv' %>%
fread() %>% rename('GBE_category'='#GBE_category') -> category_df

####################################################################
out_eval_f <- args[1]

c('gaussian', 'binomial') %>%
lapply(function(f){
    str_replace(out_eval_f, '.tsv$', sprintf('.%s.tsv', f)) %>% fread() %>%
    rename('GBE_ID'='#phenotype_name') %>% mutate(family = f)    
}) %>% bind_rows() %>% left_join(
    GBE_names_df %>% select(-GBE_short_name_len), by='GBE_ID'
) %>% rename('GBE_ID_prefix'='GBE_category') %>% left_join(
    category_df %>% select(GBE_category, GBE_ID), by='GBE_ID'
) %>% select(
    GBE_ID, GBE_category, GBE_ID_prefix, split, geno, covar, geno_covar, geno_delta,
    n_variables, family, n, case_n, control_n, GBE_N,
    GBE_NAME, GBE_short_name, Units_of_measurement
) -> eval_unsorted_df

eval_unsorted_df %>% filter(split == 'test') %>%
select(GBE_ID, geno_delta, n_variables, family) %>%
unique() %>% group_by(family) %>%
arrange(-geno_delta, -n_variables) %>%
mutate(rank_geno_delta_per_family=1:n()) %>%
ungroup() -> sort_order_df

eval_unsorted_df %>%
left_join(sort_order_df %>% select(GBE_ID, rank_geno_delta_per_family), by='GBE_ID') %>%
arrange(family, rank_geno_delta_per_family) -> eval_df

eval_df %>% rename('#GBE_ID' = 'GBE_ID') %>%
fwrite(out_eval_f, sep='\t', na = "NA", quote=F)
EOF

rm ${out_eval_f%.tsv}.gaussian.tsv
rm ${out_eval_f%.tsv}.binomial.tsv

echo ${out_eval_f}

echo rclone copy ${out_eval_f} ${out_gdrive} 
rclone copy ${out_eval_f} ${out_gdrive} 

