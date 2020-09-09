suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

read_phe_df_for_eval <- function(phe_f, GBE_ID, covars){
    phe_df <- fread(
        phe_f,
        colClasses=c('#FID'='character', 'IID'='character'),
        select=c('#FID','IID','split', 'population', GBE_ID, covars)
    ) %>%
    rename('FID'='#FID') %>%
    drop_na(population) %>%
    filter(!str_detect(population, 'outlier')) %>%
    mutate(
        split = if_else(is.na(split), population, paste(population, split, sep=':'))
    ) %>%
    mutate(ID = paste(FID, IID, sep='_')) %>%
    column_to_rownames('ID')
    
}

read_PRS <- function(GBE_ID, data_dir=data_d){
    sscore_f <- file.path(data_dir, GBE_ID, sprintf('%s.sscore.zst', GBE_ID))
    
    fread(
        cmd=paste('zstdcat', sscore_f),
        select=c('#FID', 'IID', 'SCORE1_SUM'),
        colClasses=c('#FID'='character', 'IID'='character')
    ) %>%
    rename('FID'='#FID', 'geno_score'='SCORE1_SUM')
}

read_covars <- function(GBE_ID, data_dir=data_d){
    file.path(data_dir, GBE_ID, 'snpnet.covars.tsv') %>%
    fread(colClasses=c('ID'='character')) %>%
    column_to_rownames('ID')
}

read_BETAs <- function(GBE_ID, data_dir=data_d){
    file.path(data_dir, GBE_ID, 'snpnet.tsv') %>%
    fread(colClasses=c('ID'='character'))
}

read_predicted_scores <- function(phe_df, GBE_ID, covariates=covars){
    covar_df <- read_covars(GBE_ID)
    as.matrix(
        phe_df %>% select(all_of(covariates))
    ) %*% as.matrix(covar_df) %>%
    as.data.frame() %>%
    rownames_to_column('ID') %>%
    separate(ID, c('FID', 'IID'), sep='_') %>% 
    rename('covar_score'='BETA') %>%
    left_join(
        phe_df %>% select(FID, IID, split, all_of(GBE_ID)),
        by=c('FID', 'IID')
    ) %>%
    left_join(
        read_PRS(GBE_ID),
        by=c('FID', 'IID')
    ) %>%
    mutate(
        geno_covar_score = geno_score + covar_score
    )
}

perform_eval <- function(response, pred, metric.type){
    if(metric.type == 'r2'){
        summary(lm(response ~ 1 + pred))$r.squared
    }else{
#         pROC::auc(pROC::roc(response, pred))        
        pred.obj <- ROCR::prediction(pred, factor(response - 1))
        auc.obj <- ROCR::performance(pred.obj, measure = 'auc')
        auc.obj@y.values[[1]]
    }
}

build_eval_df_line <- function(phe_df, GBE_ID, split_string, metric.type){
    score_test_df <- phe_df %>%
    read_predicted_scores(GBE_ID) %>%
    filter(split == split_string) %>%
    drop_na(all_of(GBE_ID)) %>%
    filter(GBE_ID != -9)

    data.frame(
        GBE_ID     = GBE_ID,
        n_variables = read_BETAs(GBE_ID) %>% nrow(),
        geno       = perform_eval(
            score_test_df[[GBE_ID]],
            score_test_df$geno_score,
            metric.type
        ),
        covar      = perform_eval(
            score_test_df[[GBE_ID]],
            score_test_df$covar_score,
            metric.type
        ),
        geno_covar = perform_eval(
            score_test_df[[GBE_ID]],
            score_test_df$geno_covar_score,
            metric.type
        ),
        stringsAsFactors = F
    )    
}

build_eval_df <- function(phe_df, GBE_ID, split_strings){
    lapply(split_strings, function(s){tryCatch({ 
        build_eval_df_line(phe_df, GBE_ID, s, 'auc') %>% mutate(split = s)
    }, error=function(e){})}) %>%
    bind_rows() %>%
    mutate(
        covar      = if_else(str_detect(split, 'white_british'), covar, 0),
        geno_covar = if_else(str_detect(split, 'white_british'), geno_covar, 0)
    )  %>%
    mutate(
        covar = na_if(covar, 0),
        geno_covar = na_if(geno_covar, 0),
        geno_delta = geno_covar - covar
    ) %>%
    select(GBE_ID, n_variables, split, geno, covar, geno_covar, geno_delta)
}
