fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(DescTools)
}))

####################################################################
source(file.path(dirname(script.name), 'paths.sh'))
source(snpnet_helper)
source(fPRS_helper)
####################################################################
# pase command line args
# output
performance_eval_prefix <- args[1] # the prefix of output files
## inputs
pheno_and_covar_f <- args[2] # the master phenotype file with covariates
pheno_col <- args[3] # the phenotype column
family <- args[4] # gaussian or binomial
covariates_str <- args[5]
split_strs <- args[6] # list of split groups to consider
sscore_f <- args[7] # the sscore input file
####################################################################

####################################################################
# main

## parse lists

covariates_str %>% split_list_str() -> covariates

split_strs %>% split_named_list_str() -> population_splits

# set gaussian and binomial phenotype lists
stopifnot(family %in% c('gaussian', 'binomial'))
if(family == 'gaussian'){
    phes_binary <- NULL
    phes_quantitative <- c(pheno_col)
}else if(family == 'binomial'){
    phes_binary <- c(pheno_col)
    phes_quantitative <- NULL
}

# regression formula
covar_formula_str <- sprintf(
    '%s ~ 1 + %s',
    pheno_col, paste(covariates, collapse=' + ')
)

# list of risk score models we consider in the evaluation
score_geno  <- paste0('PRS_', pheno_col)
score_covar <- paste0('covar_', pheno_col)
score_full  <- paste0('full_', pheno_col)

# get the GBE_ID to trait name mapping
GBE_category_f %>%
fread() %>%
rename_with(
    function(x){str_replace(x, '#', '')}, starts_with("#")
) -> GBE_names_df
GBE_names_dict <- setNames(
    GBE_names_df$GBE_short_name,
    GBE_names_df$GBE_ID
)

get_plot_label <- function(GBE_ID, GBE_names=GBE_names_dict) {
    if (GBE_ID %in% names(GBE_names))
        sprintf('%s: %s', GBE_ID, GBE_names[[GBE_ID]])
    else
        GBE_ID
}

# read phenotype
pheno_and_covar_f %>%
read_phenotype_file(c(covariates, phes_binary, phes_quantitative, 'split_nonWB')) %>%
recode_pheno_values(phes_binary, phes_quantitative) %>%
mutate(
    split = if_else(
        population == 'white_british',
        split,
        split_nonWB
    )
) %>%
select(-split_nonWB) %>%
update_split_column_for_refit() %>%
mutate(
    split = paste(population, split, sep=':')
) -> pheno_df

# count the number of individuals
pheno_df %>%
filter(split %in% names(population_splits)) %>%
count_n_per_split(pheno_col, family) -> split_cnt_df

# focus on the population/split where we have non-zero cases
if (family == 'binomial') {
    population_splits <- population_splits[
        split_cnt_df %>%
        filter(case_n > 0, control_n > 0) %>%
        pull(split)
    ]
} else {
    population_splits <- population_splits[
        split_cnt_df %>%
        filter(n > 0) %>%
        pull(split)
    ]
}

# we fit the specified regression model for each split independently
# and aggregate the results into one data frame
population_splits %>% unique() %>%
lapply(function(s){
    pheno_df %>%
    filter(split == s) %>%
    fit_glm(covar_formula_str, family) %>%
    fit_to_df() %>%
    mutate(split = s) %>%
    select(split, variable, estimate, SE, z_or_t_value, P)
}) %>%
bind_rows() -> covar_model_BETAs_df

# save coefficients of covariate-only model
covar_model_BETAs_df %>%
rename('#split' = 'split') %>%
fwrite(sprintf('%s.covarBETAs.tsv.gz', performance_eval_prefix), sep='\t', na = "NA", quote=F)

# we fit the specified regression model for each split independently
# and aggregate the results into one data frame
population_splits %>% names() %>%
lapply(function(s){
    # use the BETAs on a split specified in named list, PRS_model_covar_BETAs_split
    covar_score_split <- (population_splits[[s]])

    # get BETAs
    covar_model_BETAs_df %>%
    filter(split == covar_score_split) %>%
    rename(!!score_covar := 'estimate') -> covar_betas_pop_df

    # loop across different split
    pheno_df %>%
    filter(split == s) %>%
    FID_IID_to_rownames() %>%
    compute_matrix_product(
        covar_betas_pop_df,
        covar_betas_pop_df %>% pull(variable) %>% intersect(covariates),
        beta_estimate_cols=c(score_covar)
    ) %>%
    mutate(covar_score_computed_on = covar_score_split) %>%
    FID_IID_from_rownames()
}) %>%
bind_rows() -> covar_score_df

# read PRS (sscore) file
message(sprintf('.. reading %s', sscore_f))
sscore_f %>%
read_sscore_file(columns = 'SCORE1_SUM') %>%
rename(!!score_geno := 3) -> sscore_df

# join all the individual-level data into one data frame
pheno_df %>%
filter(split %in% names(population_splits)) %>%
left_join(sscore_df, by=c("FID", "IID")) %>%
left_join(covar_score_df, by=c("FID", "IID")) %>%
mutate(!!score_full := rowSums(across(all_of(c(score_geno, score_covar))))) -> full_df

# regression formula to evaluate the significance of PRS models
covarPRS_formula_str <- sprintf(
    '%s ~ 1 + (1*%s) + %s',
    pheno_col, score_covar, score_geno
)

# we fit the specified regression model for each split independently
# and aggregate the results into one data frame
population_splits %>% names() %>%
lapply(function(s){
    full_df %>%
    filter(split == s) %>%
    fit_glm(covarPRS_formula_str, family) %>%
    fit_to_df() %>%
    mutate(split = s) %>%
    select(split, variable, estimate, SE, z_or_t_value, P)
}) %>%
bind_rows() -> covarPRS_model_BETAs_df

# save the significance of PRS model
covarPRS_model_BETAs_df %>%
rename('#split' = 'split') %>%
fwrite(sprintf('%s.PRS_pval.tsv.gz', performance_eval_prefix), sep='\t', na = "NA", quote=F)

# list of "scores" we will use in the evaluation
c(score_geno, score_covar, score_full) -> risk_score_list

# run evaluation
names(population_splits) %>%
lapply(function(split_str){
    risk_score_list %>% lapply(function(predictor){
        message(sprintf('--%s %s', split_str, predictor))
        tryCatch({
            full_df %>% filter(split == split_str) -> filtered_df
            if(length(filtered_df %>% pull(all_of(pheno_col)) %>% unique())>1){
                filtered_df %>%
                eval_CI(pheno_col, c(all_of(predictor)), family) %>%
                mutate(split = split_str)
            }else{
                message(sprintf(' .. skip (the phenotype value is constant in %s', split_str))
            }
        }, error=function(e){print(e)})
    }) %>% bind_rows()
}) %>%
bind_rows() %>%
left_join(
    split_cnt_df,
    by = "split"
) -> PRS_eval_df

# write the performance metric to a file
PRS_eval_df %>%
rename('#response' = 'response') %>%
fwrite(sprintf('%s.eval.tsv.gz', performance_eval_prefix), sep='\t', na = "NA", quote=F)

# prepare data frames for the plots
full_df %>%
filter(split == 'white_british:test') %>%
drop_na(all_of(c(score_geno, pheno_col))) %>%
rename('geno_score' := all_of(score_geno)) %>%
rename('phe' := all_of(pheno_col)) %>%
mutate(
    phe = phe + 1,
    geno_score_percentile = rank(-geno_score) / n()
) -> plot_df

summary_plot_df <- plot_df %>%
compute_summary_df('geno_score_percentile', 'phe', family=family)

# save a data frame used for the summary plot
summary_plot_df %>%
rename('#l_bin' = 'l_bin') %>%
fwrite(sprintf('%s.percentile.tsv.gz', performance_eval_prefix), sep='\t', na = "NA", quote=F)

# generate plots
if(family == 'gaussian'){
    p1 <- plot_df %>% plot_PRS_vs_phe() +
    theme(legend.position=c(.1, .8))+
    labs(title = get_plot_label(pheno_col), y = get_plot_label(pheno_col))

    p2 <- summary_plot_df %>%
    plot_PRS_bin_vs_phe(mean(plot_df$phe))+
    labs(title = get_plot_label(pheno_col), y = get_plot_label(pheno_col))
}else if(family == 'binomial'){
    p1 <- plot_df %>% plot_PRS_binomial() +
    labs(title = get_plot_label(pheno_col), x = get_plot_label(pheno_col))

    p2 <- summary_plot_df %>% plot_PRS_bin_vs_OR() +
    labs(title = get_plot_label(pheno_col))
}else{
    stop(sprintf('%s family is not supported!', family))
}

for(ext in c('png', 'pdf')){ggsave(
    sprintf('%s.plot.%s', performance_eval_prefix, ext),
    gridExtra::arrangeGrob(p1, p2, ncol=2),
    width=12, height=6
)}
