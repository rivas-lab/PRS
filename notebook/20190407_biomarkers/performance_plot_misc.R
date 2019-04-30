suppressMessages(require(tidyverse))
suppressMessages(require(data.table))
suppressMessages(require(gridExtra))
suppressMessages(require(repr))

get_stats_filename <- function(dataset_name, method_name, repo_root){
    file <- file.path(
        repo_root, 
        'public_output', 
        paste0(method_name, '_PRS'), 
        paste0(dataset_name, '.tsv')
    )
    return(file)
}

read_datasets <- function(method_name, named_dataset_list, repo_root){
    named_dataset_list[method_name][[1]] %>%
    lapply(               
        function(x){
            dataset_n <- str_split(x, '_') %>% simplify() %>% first()
            dataset_v <- str_split(x, '_') %>% simplify() %>% last()            
            df <- tryCatch(                
                x %>%
                get_stats_filename(method_name, repo_root) %>%
                fread(data.table=FALSE) %>%
                mutate(
                    method = method_name,
                    dataset_name = dataset_n,
                    dataset_version = dataset_v,
                    dataset_full = x
                ),
                error=function(e){NULL}
            )
            if(!is.null(df)) {
                colnames(df) <- gsub("^#", "", colnames(df))
            }
            df
        }
    ) %>%
    bind_rows()
}

read_all_data <- function(dataset_named_list, repo_root){
    dataset_named_list %>% names() %>% lapply(
        function(x){
            read_datasets(x, dataset_named_list, repo_root)
        }
    ) %>% 
    bind_rows() %>%
    replace_na(list(N = 0))
    
}

compute_delta <- function(df){
    df %>%
    spread(features, R_or_AUC) %>%
    mutate(
        delta_R_or_AUC = Genotype_and_covariates - Covariates_only
    ) %>% 
    gather(
        "features", "R_or_AUC", 
        c('Covariates_only', 'Genotype_only', 'Genotype_and_covariates', 'delta_R_or_AUC')
    ) %>%
    arrange(Population, GBE_ID)    
}

format_labels <- function(df){
    df %>% mutate(
        label = str_replace_all(GBE_ID, '_', ' '),
        label = str_replace_all(label, 'adjstatins', ''),
        label = str_replace_all(label, 'Normal', ''),
        label = str_replace_all(label, 'C reactive', 'C-reactive'),
        Population = str_replace(Population, 'white_british', 'White British'),
        Population = str_replace(Population, 'african', 'African'),
        Population = str_replace(Population, 's_asian', 'South Asian'),
        Population = str_replace(Population, 'e_asian', 'East Asian'),
        Population = str_replace(Population, 'non_british_white', 'Non-British White')        
    )    
}

show_job_status <- function(df, final_list){
    df %>% filter(
        features == 'Genotype_and_covariates',
    ) %>% count(
        Population, GBE_ID
    ) %>% spread(
        Population, n, fill =0
    ) %>% 
    right_join(final_list)    
}

tabulate_df <- function(df){
    df_tabulated <- df %>% compute_delta() %>% format_labels() %>% mutate(Phenotype = label) %>% spread(features, R_or_AUC) %>%
    select(Phenotype, phe_type, Population, delta_R_or_AUC, Genotype_and_covariates, Covariates_only, Genotype_only)

    df_tabulated_WB <- df_tabulated %>% filter(Population == 'White British') %>% 
    rename(
        WB_delta_R_or_AUC          = delta_R_or_AUC,
        WB_Genotype_and_covariates = Genotype_and_covariates,
        WB_Covariates_only         = Covariates_only, 
        WB_Genotype_only           = Genotype_only
    ) %>% select(
        -phe_type, -Population
    )

    df_tabulated %>% left_join(
        df_tabulated_WB, by='Phenotype'
    ) %>% 
    mutate(
        Relative_to_WB_delta_R_or_AUC          = 100 * delta_R_or_AUC          / WB_delta_R_or_AUC, 
        Relative_to_WB_Genotype_and_covariates = 100 * Genotype_and_covariates / WB_Genotype_and_covariates,
        Relative_to_WB_Covariates_only         = 100 * Covariates_only         / WB_Covariates_only, 
        Relative_to_WB_Genotype_only           = 100 * Genotype_only           / WB_Genotype_only
    ) %>% 
    arrange(phe_type, Phenotype, Population)    
}

compute_performance_reduction <- function(tabulated_df){
    tabulated_df %>% 
    select(Phenotype, phe_type, Population, Relative_to_WB_delta_R_or_AUC, delta_R_or_AUC, WB_delta_R_or_AUC) %>% 
    group_by(Population) %>% 
    summarise(
        max = max(as.numeric(Relative_to_WB_delta_R_or_AUC), na.rm = TRUE),
        median = median(as.numeric(Relative_to_WB_delta_R_or_AUC), na.rm = TRUE),
        min = min(as.numeric(Relative_to_WB_delta_R_or_AUC), na.rm = TRUE)
    ) %>%
    mutate(
        median_reduction = 100 - median
    )    
}

plot_bar_performance <- function(df){
    df %>% compute_delta() %>% format_labels() %>% spread(features, R_or_AUC) %>%
    filter(Population == 'White British') %>%
    ggplot(aes(x = reorder(label, delta_R_or_AUC), y=delta_R_or_AUC)) + 
    theme_bw() + theme(
        strip.text = element_text(size=7)
    )+ 
    coord_flip()+ geom_bar(stat = 'identity') +
    labs(
        x = 'Phenotype',
        y = expression("Increments in predictive performance with genotype ("*Delta*"R or "*Delta*"AUC)")
    )    
}

plot_trans_ethnic_delta <- function(tabulated_df){
    tabulated_df %>% filter(Population != 'White British') %>%
    mutate(
        label = if_else(Population == 'Non-British White', Phenotype, ''),
    ) %>%
    rename(score = delta_R_or_AUC, WB_score = WB_delta_R_or_AUC) %>%
    select(Phenotype, Population, score, WB_score, label) %>%
    ggplot(aes(x = WB_score, y=score, color=Population, shape=Population, label=label))+ 
    theme_bw() + 
    theme(
        strip.text = element_text(size=7),
        legend.position = c(0.25, 0.8)
    )+ 
    geom_abline(slope=1, intercept=0, linetype = "dashed") + 
    geom_point(stat = 'identity') +
    xlim(0, .75) + ylim(0, .75) + 
    labs(
        x = 'Increments in predictive performance for White British',
        y = 'Increments in predictive performance for non-White British populations',
        color = 'Non-White British population',
        shape = 'Non-White British population'
    ) + 
    ggrepel::geom_text_repel(size=2) + 
    scale_color_brewer(palette="Dark2")    
}

plot_trans_ethnic <- function(tabulated_df){
    tabulated_df %>% filter(Population != 'White British') %>%
    mutate(
        label = if_else(Population == 'Non-British White', Phenotype, ''),
    ) %>%
    rename(score = Genotype_and_covariates, WB_score = WB_Genotype_and_covariates) %>%
    select(Phenotype, Population, score, WB_score, label) %>%
    ggplot(aes(x = WB_score, y=score, color=Population, shape=Population, label=label))+ 
    theme_bw() + 
    theme(
        strip.text = element_text(size=7),
        legend.position = c(0.2, 0.8)
    )+ 
    geom_abline(slope=1, intercept=0, linetype = "dashed") + 
    geom_point(stat = 'identity') +
    xlim(0, 1) + ylim(0, 1) + 
    labs(
        x = 'Predictive performance for White British',
        y = 'Predictive performance for non-White British populations',
        color = 'Non-White British population',
        shape = 'Non-White British population'
    ) + 
    ggrepel::geom_text_repel(size=2) + 
    scale_color_brewer(palette="Dark2")    
}
