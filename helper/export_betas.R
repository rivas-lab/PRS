#!/usr/bin/env Rscript
####################################################################
# export BETAs from RData file
# usage: Rscript export_betas.R <path_to_RData_file> <covariates>
# 
# This script selects the lambda index with the maximum 
# performance metric on the validation set.
# For the selected index, it extracts BETAs and save it to
# two files:
# - `${RData%.RData}.tsv`: The non-zero BETAs for genotypes
# - `${RData%.RData}.covars.tsv`: The BETAs for covariates.
####################################################################

fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

source(file.path(dirname(script.name), 'snpnet_misc.R'))

####################################################################
rdata_f    <- args[1]
covariates <- parse_covariates(args[2])

####################################################################
load(rdata_f)

lambda_idx <- which.max(metric.val)

print(sprintf('The selected lambda idx: %d', lambda_idx))

df_all<-snpnet_fit_to_df(beta, lambda_idx, covariates) %>% filter(BETA != 0)
df_all$BETA <- format(df_all$BETA, scientific = T)

df_all %>% filter(! ID %in% covariates) %>%
separate( ID, into=c('ID', 'A1'), sep='_') %>% 
drop_na() %>% 
fwrite(str_replace(rdata_f, '.RData$', '.tsv'), sep='\t')

df_all %>% filter(ID %in% covariates) %>%
fwrite(str_replace(rdata_f, '.RData$', '.covars.tsv'), sep='\t')

