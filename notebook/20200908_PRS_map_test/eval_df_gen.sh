#!/bin/bash
set -beEuo pipefail


ml load R/3.6 gcc


Rscript /dev/stdin << EOF

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

data_d <- '/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test'

run_name <- c('1_p_factor_v1', '2_p_factor_v2', '3_p_factor_v3', '4_regDoms_pfactor', '5_regDoms_pfactor_v4', '6_pfactor_v4', '7_pfactor_v5')
GBE_IDs <- c('HC269', 'HC382', 'INI50', 'INI21001')
fit_or_refit <- c('1_fit_w_val', '2_refit')

run_name %>% lapply(function(rn){
GBE_IDs %>% lapply(function(GBEID){
fit_or_refit %>% lapply(function(fr){
    f <- file.path(data_d, rn, GBEID, fr, 'snpnet.eval.tsv')
    
    if(file.exists(f)){
        fread(f) %>%
        rename('phenotype_name'='#phenotype_name') %>%
        mutate(run_name = rn, fit_or_refit=fr)        
    }
    
}) %>% bind_rows()
}) %>% bind_rows()
}) %>% bind_rows() %>%
select(
    phenotype_name, run_name, fit_or_refit,
    split, geno, covar, geno_covar, geno_delta, 
    n_variables, n, case_n, control_n
)-> df

df %>%
rename('#phenotype_name' = 'phenotype_name') %>%
fwrite('eval_df.tsv', sep='\t', na = "NA", quote=F)
EOF
