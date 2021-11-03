fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

####################################################################
GBE_ID <- args[1]
####################################################################
source(file.path(dirname(script.name), 'paths.sh'))
####################################################################

out_f <- file.path(out_d, 'output2', sprintf('%s.tsv', GBE_ID))
covariates <- c('age','sex','Array',paste0('PC',1:10))

cat_or_zcat <- function(f){
    ifelse(endsWith(f, '.zst'), 'zstdcat', ifelse(endsWith(f, '.gz'), 'zcat', 'cat'))
}

fam <- ifelse(
    str_replace(GBE_ID, '[0-9]+$', '') %in% c('INI', 'QT_FC'),
    'gaussian', 'binomial'
)

# covariate-only model BETAs
covar_model_BETAs_f %>%
str_replace_all('__TRAIT__', GBE_ID) %>%
fread() %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) -> covar_model_BETAs_df

# analysis center
centers_f %>%
fread(colClasses = c('#FID'='character', 'IID'='character')) %>%
rename_with(function(x){str_replace(x, '#', '')}, starts_with("#")) %>%
drop_na(f.54.0.0) %>%
mutate(center_id = relevel(as.factor(f.54.0.0), ref = "11010")) -> centers_df
# the ref class: 11010 denotes "Leeds", which is the most common assessment center

# phenotype file
fread(
    cmd=paste(cat_or_zcat(phe_f), phe_f),
    colClasses = c('#FID'='character', 'IID'='character'),
    select=c('#FID', 'IID', 'population', 'split', covariates, GBE_ID)
) %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) %>% 
na_if(list(GBE_ID = -9)) -> phe_df

# PRS
fread(
    cmd=paste(cat_or_zcat(PRS202110_f), PRS202110_f),
    colClasses = c('#FID'='character', 'IID'='character'),
    select=c('#FID', 'IID', paste0('PRS_', GBE_ID))
) %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) -> PRS_df

# join dfs
phe_df %>% 
inner_join(PRS_df, by=c('FID', 'IID')) %>%
inner_join(centers_df, by=c('FID', 'IID')) %>%
drop_na(all_of(c(GBE_ID, paste0('PRS_', GBE_ID)))) -> full_df

# focus on the test set
full_df %>% 
filter(population == 'white_british', split == 'test') -> test_df

# compute the covariate-only score
test_df %>%
column_to_rownames('IID') %>%
select(all_of(covariates)) %>% 
as.matrix %*% (
    covar_model_BETAs_df %>%
    filter(split == 'train_val') %>%
    filter(variable %in% covariates) %>%
    select(variable, estimate) %>%
    rename('covar_score' = 'estimate') %>%
    column_to_rownames('variable') %>%
    as.matrix
) %>%
as.data.frame %>%
rownames_to_column('IID') -> covar_score_df

test_df %>%
left_join(covar_score_df, by='IID') -> test_df

glmfit_center <- glm(
    stats::as.formula(
        sprintf('(%s - 1) ~ 1 + (1 * covar_score) + %s + %s', GBE_ID, 'center_id', paste0('PRS_', GBE_ID))
    ),
    family=fam,
    data=test_df
)

summary(glmfit_center)$coefficients %>%
as.data.frame() %>% rownames_to_column('variable') %>%
rename('variable' = 1, 'estimate' = 2, 'SE' =3, 'z_or_t_value' =4, 'P' = 5) %>%
mutate(trait = GBE_ID) %>%
select(trait, variable, estimate, SE, z_or_t_value, P) -> results_df

results_df %>%
rename('#trait' = 'trait') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
