suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

PRS_eval_f='/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch/snpnet.eval.2_refit.tsv'
covar_f='/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20200828/ukb24983_GWAS_covar.20200828.phe'
PRS_test_run_f='/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test/7_pfactor_v5/%s/2_refit/%s.sscore.zst'
# output
master_PRS_f='/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch/ukb24983_GWAS_covar.20200828.PRSs.phe'


###########
source('/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/helpers/snpnet_misc.R')

PRS_eval_f %>% fread() %>% rename('GBE_ID'='#GBE_ID') -> PRS_eval_df

PRS_eval_df %>% filter(split == 'test', n_variables>0) %>% pull(GBE_ID) -> GBE_IDs

PRS_file_df <- fread(
    cmd=paste(
        'find',
        '/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch/',
        '-maxdepth 4', '-mindepth 4', '-type f', '-name "*.sscore.zst"',
        '| grep 2_refit',
        "| awk -v FS='/' -v OFS='\t' '{print $(NF-2), $0}'"
    ),
    head=F
) %>%
rename('GBE_ID'=1, PRS_f=2)

covar_f %>% fread(colClasses = c('#FID'='character', 'IID'='character')) %>%
rename('FID'='#FID') -> covar_df

c('INI50', 'INI21001', 'HC269', 'HC382') %>%
lapply(function(gbeid){
    read_PRS(sprintf(PRS_test_run_f, gbeid, gbeid)) %>% rename(!!sprintf('PRS_%s', gbeid) := 'geno_score')
}) %>% reduce(function(x, y){inner_join(x, y, by=c('FID', 'IID'))}) -> PRS_test_run_df

message(format(Sys.time(), format="%Y%m%d-%H%M%S"))

PRS_file_df %>% filter(GBE_ID %in% GBE_IDs) %>%
arrange(GBE_ID) %>%
pull(PRS_f) %>%
lapply(function(PRS_f){
    gbeid = basename(dirname(dirname(PRS_f)))
    message(format(Sys.time(), format="%Y%m%d-%H%M%S"))
    message(gbeid)
    read_PRS(PRS_f) %>% rename(!!sprintf('PRS_%s', gbeid) := 'geno_score')
}) %>% reduce(function(x, y){inner_join(x, y, by=c('FID', 'IID'))}) -> PRS_df

covar_df %>% 
left_join(PRS_test_run_df, by=c('FID', 'IID')) %>%
left_join(PRS_df, by=c('FID', 'IID')) %>%
rename('#FID' = 'FID') %>%
fwrite(master_PRS_f, sep='\t', na = "NA", quote=F)
