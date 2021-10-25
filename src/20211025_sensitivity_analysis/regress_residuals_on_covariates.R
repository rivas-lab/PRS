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

out_f <- file.path(out_d, 'output', sprintf('%s.tsv', GBE_ID))

cat_or_zcat <- function(f){
    ifelse(endsWith(f, '.zst'), 'zstdcat', ifelse(endsWith(f, '.gz'), 'zcat', 'cat'))
}

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
    select=c('#FID', 'IID', 'population', 'split', GBE_ID, 'Array')
) %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) -> phe_df

# PRS
fread(
    cmd=paste(cat_or_zcat(PRS_f), PRS_f),
    colClasses = c('#FID'='character', 'IID'='character'),
    select=c('#FID', 'IID', paste0('PRS_', GBE_ID))
) %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) -> PRS_df

phe_df %>% 
inner_join(PRS_df, by=c('FID', 'IID')) %>%
inner_join(centers_df, by=c('FID', 'IID')) %>%
drop_na(all_of(c(GBE_ID, paste0('PRS_', GBE_ID)))) -> full_df

full_df %>% 
filter(population == 'white_british', split == 'test') -> test_df

fam <- ifelse(
    str_replace(GBE_ID, '[0-9]+$', '') %in% c('INI', 'QT_FC'),
    'gaussian', 'binomial'
)

glmfit_array <- glm(
    stats::as.formula(
        sprintf('(%s - 1) ~ 1 + (1 * %s) + %s', GBE_ID, paste0('PRS_', GBE_ID), 'Array')
    ),
    family=fam,
    data=test_df
)


glmfit_center <- glm(
    stats::as.formula(
        sprintf('(%s - 1) ~ 1 + (1 * %s) + %s', GBE_ID, paste0('PRS_', GBE_ID), 'center_id')
    ),
    family=fam,
    data=test_df
)

bind_rows(
    summary(glmfit_array)$coefficients %>%
    as.data.frame() %>% rownames_to_column('variable') %>%
    rename('variable' = 1, 'estimate' = 2, 'SE' =3, 'z_or_t_value' =4, 'P' = 5) %>%
    mutate(model='array', phenotype = GBE_ID) %>%
    select(model, phenotype, variable, estimate, SE, z_or_t_value, P),

    summary(glmfit_center)$coefficients %>%
    as.data.frame() %>% rownames_to_column('variable') %>%
    rename('variable' = 1, 'estimate' = 2, 'SE' =3, 'z_or_t_value' =4, 'P' = 5) %>%
    mutate(model='center', phenotype = GBE_ID) %>%
    select(model, phenotype, variable, estimate, SE, z_or_t_value, P)
) -> results_df

results_df %>%
rename('#model' = 'model') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
