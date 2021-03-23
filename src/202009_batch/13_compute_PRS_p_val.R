####################################################################
# compute_PRS_p_val.R
#   Yosuke Tanigawa
#
# This script reads the master phe file and the master PRS file
# and compute the p-value of PRS model (using the test set individuals in WB)
#
####################################################################

fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

####################################################################
source(file.path(dirname(script.name), '0_parameters.sh'))
source(snpnet_misc_R)
####################################################################
GBE_ID <- args[1] # the phenotype ID in GBE
####################################################################

# family in glm()
family <- ifelse(str_replace_all(GBE_ID, '[0-9]', '') %in% c('INI', 'QT_FC'), 'gaussian', 'binomial')

# covariates in the regression model
covariates <- str_split(covariates_str, ',')[[1]]

# read phenotype data from the master phe file
phe_df <- fread(
    cmd=paste('zstdcat', phe_scratch_f),
    colClasses = c('#FID'='character', 'IID'='character'),
    select=c('#FID', 'IID', 'population', 'split', covariates, GBE_ID)
) %>%
rename('FID'='#FID')

# read the PRS data from the master PRS file
prs_df <- fread(
    cmd=paste('zcat', file.path(res_scratch_d, prs_f)),
    colClasses = c('#FID'='character', 'IID'='character'),
    select=c('#FID', 'IID', paste0('PRS_', GBE_ID))
) %>%
rename('FID'='#FID')

# combine those data into one
inner_join(phe_df, prs_df, by=c('FID', 'IID')) -> df

# let's focus on the individuals (with non-missing values) in the test dataset
df %>% filter(population == 'white_british', split == 'test') %>%
select(-population, -split) %>%
rename(!!'phe' := all_of(GBE_ID)) %>%
rename(!!'PRS' := all_of(paste0('PRS_', GBE_ID))) %>%
drop_na(phe, PRS) %>%
mutate(phe = phe - ifelse(family=='binomial', 1, 0)) -> test_df

if(family == 'binomial'){
    # sometimes, missing values are coded as -9 in the master phe file
    test_df %>% filter(phe %in% c(0,1)) -> test_df
}

# fit a GLM, phe ~ 1 + covariates + PRS
stats::as.formula(sprintf('phe ~ 1 + %s + PRS', paste(covariates, collapse =' + '))) %>%
glm(family=family, data=test_df) -> glmfit

# save the results into a file
fit_to_df(glmfit) %>%
mutate(phe = GBE_ID, family = family, n_test=nrow(test_df)) %>%
select(phe, family, n_test, variable, estimate, SE, z_or_t_value, P) %>%
rename('#phe' = 'phe') %>%
fwrite(file.path(res_scratch_d, 'tmp_glmfit', paste0(GBE_ID, '.tsv')), sep='\t', na = "NA", quote=F)
