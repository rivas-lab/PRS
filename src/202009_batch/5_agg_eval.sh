#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})
PROGNAME=$(basename $SRCNAME)

project_dir="/scratch/groups/mrivas/projects/PRS/private_output/$(basename ${SRCDIR})"

header_common="#phenotype_name:split:geno:covar:geno_covar:geno_delta:n_variables"
header_binomial="${header_common}:case_n:control_n"
header_gaussian="${header_common}:n"

ml load R/3.6 gcc

{
    echo ${header_gaussian} | tr ':' '\t'

    ! find ${project_dir} -name "snpnet.eval.tsv" | egrep -v BIN_FC | egrep    "${project_dir}/INI|${project_dir}/QT" | parallel -k 'cat {}' | egrep -v '#' | awk -v FS='\t' 'NF==8'
} > ${project_dir}/snpnet.eval.gaussian.tsv

echo ${project_dir}/snpnet.eval.gaussian.tsv

{
    echo ${header_binomial} | tr ':' '\t'
    ! find ${project_dir} -name "snpnet.eval.tsv" | egrep -v BIN_FC | egrep -v "${project_dir}/INI|${project_dir}/QT" | parallel -k 'cat {}' | egrep -v '#' | awk -v FS='\t' 'NF==9'
} > ${project_dir}/snpnet.eval.binomial.tsv

echo ${project_dir}/snpnet.eval.binomial.tsv

Rscript /dev/stdin ${project_dir} << EOF
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

####################################################################
project_dir <- args[1]

c('gaussian', 'binomial') %>%
lapply(function(f){
    file.path(project_dir, sprintf('snpnet.eval.%s.tsv', f)) %>% fread() %>%
    rename('GBE_ID'='#phenotype_name') %>% mutate(family = f)    
}) %>% bind_rows() %>%
left_join(
    GBE_names_df %>% select(-GBE_short_name_len), by='GBE_ID'
) %>% 
select(
    GBE_ID, GBE_category, split, geno, covar, geno_covar, geno_delta,
    n_variables, family, n, case_n, control_n, GBE_N,
    GBE_NAME, GBE_short_name, Units_of_measurement
) -> eval_unsorted_df

eval_unsorted_df %>%
filter(split == 'test') %>%
select(GBE_ID, geno_delta, n_variables, family) %>%
unique() %>% group_by(family) %>%
arrange(-geno_delta, -n_variables) %>%
mutate(rank_geno_delta_per_family=1:n()) %>%
ungroup() -> sort_order_df

eval_unsorted_df %>%
left_join(sort_order_df %>% select(GBE_ID, rank_geno_delta_per_family), by='GBE_ID') %>%
arrange(family, rank_geno_delta_per_family) -> eval_df

eval_df %>%
rename('#GBE_ID' = 'GBE_ID') %>%
fwrite(file.path(project_dir, 'snpnet.eval.tsv'), sep='\t', na = "NA", quote=F)
EOF

rm ${project_dir}/snpnet.eval.gaussian.tsv
rm ${project_dir}/snpnet.eval.binomial.tsv

echo ${project_dir}/snpnet.eval.tsv

echo rclone copy \
  ${project_dir}/snpnet.eval.tsv \
  gdrive://rivas-lab$(echo ${project_dir} | sed -e 's%/scratch%%g' | sed -e 's%/oak/stanford%%g' | sed -e 's%/groups/mrivas%%g' | sed -e 's%private_output/%%g')/

rclone copy \
  ${project_dir}/snpnet.eval.tsv \
  gdrive://rivas-lab$(echo ${project_dir} | sed -e 's%/scratch%%g' | sed -e 's%/oak/stanford%%g' | sed -e 's%/groups/mrivas%%g' | sed -e 's%private_output/%%g')/
