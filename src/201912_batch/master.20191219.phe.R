suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

df <- fread(
    '/oak/stanford/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20190509.phe', 
    sep='\t', data.table=F,
    colClasses=list(character=c("FID", "IID"))
)

phenotypes <- colnames(df)[46:ncol(df)]

covar_df <- fread(
    '/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20190809/ukb24983_GWAS_covar.20190809.phe',
    sep='\t', data.table=F,
    colClasses=list(character=c("FID", "IID"))
) 

wb_split_df <- bind_rows(lapply(c('train', 'test', 'valid'), function(s){
    df <- fread(file.path(
        '/oak/stanford/groups/mrivas/projects/degas-risk/population-split', 
        paste0('ukb24983_white_british_', s, '.phe')
    ), sep='\t', colClasses='character')
    colnames(df) <- c('FID', 'IID')
    df %>% mutate(
        split = str_replace(s, 'valid', 'val')
    )
})) %>%
mutate(
    FID = as.numeric(FID),
    FID = as.character(FID),
    IID = as.numeric(IID),
    IID = as.character(IID)    
)

covar_df %>% dim() %>% print()
wb_split_df %>% dim() %>% print()
df %>% dim() %>% print()

cols <- c('FID', 'IID', 'population', 'split', colnames(covar_df)[3:(ncol(covar_df) - 1)], phenotypes)

length(cols)

master_df <- df %>% 
filter(!IID %in% c('3e+06')) %>%
select(c('FID', 'IID', phenotypes)) %>%
left_join(covar_df, by=c('FID', 'IID')) %>%
left_join(wb_split_df, by=c('FID', 'IID')) %>%
select(cols)

master_df %>% dim() %>% print()

master_df %>% 
mutate(
    FID = as.character(FID),
    IID = as.character(IID)
) %>%
fwrite(
    '/oak/stanford/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20191219.phe', 
    sep='\t', na="NA", quote=F
)
