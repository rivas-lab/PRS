suppressWarnings(suppressPackageStartupMessages({ library(tidyverse); library(data.table) }))

args <- commandArgs(trailingOnly=TRUE)
GBE_ID <- args[1]

snpnet_dir <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet'
####################################################################
devtools::load_all(snpnet_dir)
source(file.path(snpnet_dir, 'helpers', 'snpnet_misc.R'))
####################################################################
configs <- list(
    covariates = c('age', 'sex', paste0('PC', 1:10)),
    verbose=T,
    results.dir=file.path('/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test', GBE_ID, '2_refit'),
    vzs='T',
    genotype.pfile='/scratch/groups/mrivas/ukbb24983/array_combined/pgen/ukb24983_cal_hla_cnv'
)

load(file.path(configs[['results.dir']], 'snpnet.RData'))

# extract BETAs
df <- snpnet_fit_to_df(
    fit$beta,
    ifelse(all(is.na(fit$metric.val)), length(fit$metric.train), which.max(fit$metric.val)),
    configs[['covariates']],
    configs[['verbose']]
)

save_BETA(
    df, file.path(configs[['results.dir']], paste0("snpnet")),
    paste0(
        configs[['genotype.pfile']],
        '.pvar', ifelse(configs[['vzs']], '.zst', '')
    ),
    configs[['vzs']], configs[['covariates']], configs[['verbose']]
)
