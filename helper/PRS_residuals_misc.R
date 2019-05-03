suppressMessages(require(tidyverse))
suppressMessages(require(data.table))
suppressMessages(require(gridExtra))
suppressMessages(require(hexbin))

read_data <- function(phe_f, score_f, keep_f = NULL){
    phe_df <- fread(phe_f)    
    colnames(phe_df) <- c('FID', 'IID', 'Observed')
    score_df <- fread(score_f)
    
    df_joined <- phe_df %>% select(-FID) %>%
    inner_join(score_df %>% select(IID, SCORE1_SUM), by='IID') %>%
    rename(Predicted = SCORE1_SUM) %>% 
    mutate(Residuals = Observed - Predicted)
    
    if(!is.null(keep_f)){
        keep_df <- fread(keep_f)
        colnames(keep_df) <- c('FID', 'IID')
        
        res <- df_joined %>% inner_join(keep_df %>% select(IID), by='IID')
    }else{
        res <- df_joined
    }
    cor_measure <- cor(
        res %>% select(Observed) %>% pull(),
        res %>% select(Predicted) %>% pull()
    )
    print(paste0('correlation: ', cor_measure))
    res
}

plot_scatter <- function(df, n_geom_hex_bins = 500, val_range_quantile=.01){
    lm1 <- df %>% lm(Predicted ~ Observed, data = .)

    max_val <- df %>% select(Predicted, Observed) %>% pull() %>% 
    quantile(1 - val_range_quantile) %>% first() %>% ceiling()
    min_val <- df %>% select(Predicted, Observed) %>% pull() %>% 
    quantile(val_range_quantile)     %>% first() %>% ceiling()    
    
    df %>% ggplot(aes(x=Predicted, y=Observed))+     
#     geom_point(stat = 'identity', alpha=.01) +        
    geom_hex(bins = n_geom_hex_bins) +
    scale_fill_gradientn("", colours = rev(rainbow(10, end = 4/6))) +
    
    geom_abline(intercept=0, slope=1, color='red') + 
    geom_abline(intercept=lm1$coefficients[1], slope=lm1$coefficients[2], 
                color='gray', size=.5, linetype = "dashed") + 
    
    theme_bw() + xlim(min_val, max_val) + ylim(min_val, max_val)+ 
    labs(x = 'Predicted phenotype', y = 'Observed phenotype')     
}

plot_residuals <- function(df){
    df %>% ggplot(aes(x = Residuals))+ 
    geom_histogram(bins=50) + theme_bw() + 
    labs(x = 'Residuals (Predicted phenotype - Observed phenotype)')     
}

compute_covar_score <- function(covar_df, covar_beta_df){
    covar_score <- covar_df %>% select(
        covar_beta_df %>% select(ID) %>% pull()
    ) %>%
    as.matrix() %*% (covar_beta_df %>% select(BETA) %>% pull())    
    covar_df %>%
    select(IID) %>% mutate(
        covar_score = covar_score
    )
}

read_data_with_covars <- function(phe_f, score_f, rda_file, covar_df, covar_beta_f, keep_f = NULL){
    fit <- readRDS(rda_file)
    intercept <- fit$a0[which.max(fit$metric.val)] %>% first()    
    
    covar_beta_df <- fread(cmd=paste0('zcat ', covar_beta_f, '| sed -e "s/^#//g"'))    
    covar_score_df <- compute_covar_score(covar_df, covar_beta_df)
    
    read_data(phe_f, score_f, keep_f) %>%
    rename(Predicted_geno_only = Predicted) %>%
    left_join(covar_score_df, by='IID') %>%
    mutate(Predicted = intercept + covar_score + Predicted_geno_only)
}

get_file_names <- function(task_name, phe_name, rda_iter=0, repo_dir='/oak/stanford/groups/mrivas/projects/PRS'){
    file_names <- list()

    file_names[['phe']] <- file.path(
        repo_dir, 'private_output', task_name, '0_input',
        paste0(phe_name, '.phe')
    )

    file_names[['score']] <- file.path(
        repo_dir, 'private_output', task_name, '4_score',
        paste0(phe_name, '.sscore')    
    )

    file_names[['test']] <- file.path(
        repo_dir, 'private_output', task_name, '1_split',
        paste0(phe_name, '.test')    
    )
    
    file_names[['rda']] <- file.path(
        repo_dir, 'private_output', task_name, '3_snpnet',
        phe_name, 'results', paste0('output_iter_', rda_iter, '.rda')
    )
    
    file_names[['covar_beta']] <- file.path(
        repo_dir, 'private_output', task_name, '3_snpnet', 
        paste0(phe_name, '.covars.tsv.gz')
    )    
    
    return(file_names)
}


scatter_and_residual_plots <- function(
    task, phe_name, task_INR, phe_name_INT, out_f, covar_df, 
    rda_iter = 0, n_geom_hex_bins = 250, plot_width=12, plot_height=12
){
    file_names <- get_file_names(task, phe_name, rda_iter = rda_iter)
    file_names_INT <- get_file_names(task_INT, phe_name_INT)

    print('reading data without INT...')
    data <- read_data_with_covars(
        file_names[['phe']], file_names[['score']], 
        file_names[['rda']], covar_df, file_names[['covar_beta']], 
        file_names[['test']]
    )

    print('reading data with INT...')    
    data_INT <- read_data(
        file_names_INT[['phe']], file_names_INT[['score']], file_names_INT[['test']]
    )
    
    options(repr.plot.width=plot_width , repr.plot.height=plot_height)
    p_combined <- grid.arrange(
        data %>% plot_scatter(n_geom_hex_bins)   + labs(title='A.  Predicted phenotype vs. Observed phenotype') , 
        data %>% plot_residuals() + labs(title='B.  Residuals from the polygenic prediction'),     
        data_INT %>% plot_scatter(n_geom_hex_bins)   + labs(title='C.  Predicted phenotype vs. Observed phenotype (w/ inverse-normal transformation)') , 
        data_INT %>% plot_residuals() + labs(title='D.  Residuals from the polygenic prediction (w/ inverse-normal transformation)'), 
        widths = c(1, 1), nrow = 2
    )
    print('saving the results to ...')
    print(out_f)
    ggsave(out_f, p_combined, width=plot_width, height=plot_height)    
}
