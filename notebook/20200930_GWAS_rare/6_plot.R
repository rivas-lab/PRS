fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################
GBE_IDs <- c('INI50', 'INI21001', 'HC269', 'HC382')
####################################################################
get_file_name <- function(sub_d, GBE_ID){
    data_d <- '/oak/stanford/groups/mrivas/projects/PRS/private_output/20200930_GWAS_rare'
    filename <- sprintf('ukb24983_v2_hg19.%s.glm.%s.gz', GBE_ID, ifelse(str_replace_all(GBE_ID, '[0-9]', '') %in% c('INI', 'QT_FC'), 'linear', 'logistic.hybrid' ))
    file.path(data_d, sub_d, filename)
}
####################################################################

var_anno_f <- '/oak/stanford/groups/mrivas/private_data/ukbb/variant_filtering/variant_filter_table.20200701.tsv.gz'
p_thr <- -log10(1e-4)

sub_ds <- c(
    'a_default',
    'b_PRS_covar',
    'c_default_test',
    'c_default_train_val',
    'd_PRS_covar_test',
    'd_PRS_covar_train_val'
)

var_anno_f %>%
fread(select=c('#CHROM', 'POS', 'REF', 'ALT', 'ID', 'ld_indep', 'maf'), colClasses = c('#CHROM'='character')) %>%
rename('CHROM'='#CHROM') -> var_anno_df

var_anno_df %>% filter(1e-4 <= maf, maf <= 1e-2, ld_indep) %>% pull(ID) -> rare_vars

length(rare_vars) %>% print()

for(GBE_ID in GBE_IDs){
    message(GBE_ID)

    df1 <- get_file_name(sub_ds[1], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))
    df2 <- get_file_name(sub_ds[2], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))
    df3 <- get_file_name(sub_ds[3], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))
    df4 <- get_file_name(sub_ds[4], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))
    df5 <- get_file_name(sub_ds[5], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))
    df6 <- get_file_name(sub_ds[6], GBE_ID) %>% fread(colClasses = c('#CHROM'='character')) %>%
      rename('CHROM'='#CHROM') %>% filter(ID %in% rare_vars, ERRCODE=='.') %>% mutate(log10P = -log10(P))

    if(!(str_replace_all(GBE_ID, '[0-9]', '') %in% c('INI', 'QT_FC'))){
        df1 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df1
        df2 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df2
        df3 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df3
        df4 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df4
        df5 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df5
        df6 %>% rename('SE'='LOG(OR)_SE') %>% mutate(BETA = log(OR)) -> df6
    }

    inner_join(
        df1 %>% select(ID, log10P, BETA, SE),
        df2 %>% select(ID, log10P, BETA, SE),
        suffix = c("_1", "_2"), by='ID'
    ) %>% drop_na() -> df_12

    inner_join(
        df3 %>% select(ID, log10P, BETA, SE),
        df5 %>% select(ID, log10P, BETA, SE),
        suffix = c("_1", "_2"), by='ID'
    ) %>% drop_na() -> df_35

    inner_join(
        df4 %>% select(ID, log10P, BETA, SE),
        df6 %>% select(ID, log10P, BETA, SE),
        suffix = c("_1", "_2"), by='ID'
    ) %>% drop_na() -> df_46

    p_P_12 <- df_12 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = log10P_1, log10P_2)) + 
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    labs(title=sprintf('%s, full set', GBE_ID), x = '-log10(P) [default run]', y = '-log10(P) [w/ PRS in covariates]')

    p_P_35 <- df_35 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = log10P_1, log10P_2)) +
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    labs(title=sprintf('%s, test set', GBE_ID), x = '-log10(P) [default run]', y = '-log10(P) [w/ PRS in covariates]')

    p_P_46 <- df_46 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = log10P_1, log10P_2)) +
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    labs(title=sprintf('%s, training/validation set', GBE_ID), x = '-log10(P) [default run]', y = '-log10(P) [w/ PRS in covariates]')

    p_B_12 <- df_12 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = BETA_1, BETA_2)) + 
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    geom_errorbarh(aes(xmin = BETA_1 - SE_1, xmax = BETA_1 + SE_1), alpha=.1) +
    geom_errorbar( aes(ymin = BETA_2 - SE_2, ymax = BETA_2 + SE_2), alpha=.1) +
    labs(title=sprintf('%s, full set', GBE_ID), x = 'BETA [SE], default run', y = 'BETA [SE], w/ PRS in covariates')

    p_B_35 <- df_35 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = BETA_1, BETA_2)) + 
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    geom_errorbarh(aes(xmin = BETA_1 - SE_1, xmax = BETA_1 + SE_1), alpha=.1) +
    geom_errorbar( aes(ymin = BETA_2 - SE_2, ymax = BETA_2 + SE_2), alpha=.1) +
    labs(title=sprintf('%s, full set', GBE_ID), x = 'BETA [SE], default run', y = 'BETA [SE], w/ PRS in covariates')

    p_B_46 <- df_46 %>% filter(log10P_1 >= p_thr | log10P_2 >= p_thr ) %>% ggplot(aes(x = BETA_1, BETA_2)) + 
    theme_bw() + geom_abline(slope=1, intercept=0, color='red') + geom_point() +
    geom_errorbarh(aes(xmin = BETA_1 - SE_1, xmax = BETA_1 + SE_1), alpha=.1) +
    geom_errorbar( aes(ymin = BETA_2 - SE_2, ymax = BETA_2 + SE_2), alpha=.1) +
    labs(title=sprintf('%s, full set', GBE_ID), x = 'BETA [SE], default run', y = 'BETA [SE], w/ PRS in covariates')

    ggsave(
        sprintf('%s.png', GBE_ID),
        gridExtra::arrangeGrob(p_P_12, p_B_12, p_P_35, p_B_35, p_P_46, p_B_46, ncol=2),
        width=12,height=18
    )
}
