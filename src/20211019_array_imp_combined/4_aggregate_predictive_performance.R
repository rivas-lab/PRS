fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

####################################################################
source(file.path(dirname(script.name), 'paths.sh'))
####################################################################

snpnet_res_d<-"/scratch/groups/mrivas/projects/PRS/private_output/20211019_array_imp_combined/snpnet.imp/__GBE_ID__/2_refit"

out_f <- 'predictive_performance.tsv'

GBE_IDs <- c('INI50', 'INI21001', 'HC269', 'HC382')


GBE_IDs %>% lapply(function(GBE_ID){
    file.path(snpnet_res_d, 'snpnet.tsv') %>%
    str_replace_all('__GBE_ID__', GBE_ID) %>%
    fread() %>%
    rename_with(function(x){str_replace(x, '#', '')}, starts_with("#")) %>%
    mutate(trait = GBE_ID)
}) %>%
bind_rows %>%
count(trait, name='n_variables') -> n_vars_df

GBE_IDs %>% lapply(function(GBE_ID){
    file.path(snpnet_res_d, '__GBE_ID__.eval.tsv.gz') %>%
    str_replace_all('__GBE_ID__', GBE_ID) %>%
    fread() %>%
    rename_with(function(x){str_replace(x, '#', '')}, starts_with("#"))
}) %>%
bind_rows %>%
separate(predictors, c('model', 'trait'), remove=FALSE, sep='_') -> eval_df

eval_df %>%
left_join(n_vars_df, by=c('trait')) -> full_df

full_df %>%
rename('#response' = 'response') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
