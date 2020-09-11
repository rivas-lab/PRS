suppressWarnings(suppressPackageStartupMessages({ library(tidyverse); library(data.table) }))

args <- commandArgs(trailingOnly=TRUE)
GBE_ID <- args[1]
results_dir <- args[2]
lambda_idxs <- NULL

if(length(args)>2){
    lambda_idxs <- c(as.integer(args[3]))
}

snpnet_dir <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet'
####################################################################
devtools::load_all(snpnet_dir)
source(file.path(snpnet_dir, 'helpers', 'snpnet_misc.R'))
####################################################################

export_BETAs <- function(beta, lambda_idx, configs){
    # extract BETAs
    snpnet_fit_to_df(
        beta, lambda_idx, configs[['covariates']], configs[['verbose']]
    ) %>%
    save_BETA(
        file.path(configs[['results.dir']], 'results', paste0("snpnet.lambda", lambda_idx)),
        paste0(
            configs[['genotype.pfile']],
            '.pvar', ifelse(configs[['vzs']], '.zst', '')
        ),
        configs[['covariates']], configs[['verbose']]
    )
}

####################################################################
configs <- list(
    covariates = c('age', 'sex', paste0('PC', 1:10)),
    verbose=T,
    results.dir=results_dir,
    vzs='T',
    genotype.pfile='/scratch/groups/mrivas/ukbb24983/array_combined/pgen/ukb24983_cal_hla_cnv'
)

load(file.path(configs[['results.dir']], 'snpnet.RData'))

if(is.null(lambda_idxs)){
    lambda_idxs <- 1:(length((fit$metric.train)[!is.na(fit$metric.train)]))
}

for(lambda_idx in lambda_idxs){
    # extract BETAs
    export_BETAs(fit$beta, lambda_idx, configs)
}
