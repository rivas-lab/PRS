fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

####################################################################
# cmdargs

phenotype <- args[1]
data_d    <- args[2]
refit <- FALSE
if((length(args)>2) && (! is.null(args[3])) && (args[3] == 'refit')){
    refit <- TRUE
    # we will merge train + val set as train_val
}

# input and parameters

#data_d <- '/oak/stanford/groups/mrivas/projects/PRS/private_output/20200908_PRS_map_test'
phe_f <- '/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200828.phe.zst'
covariates       <- c('age', 'sex', paste0('PC', 1:10))
refit_split_strs <- c('non_british_white', 'african', 's_asian', 'e_asian')
sscore_f             <- file.path(data_d, '__PHENOTYPE__.sscore.zst')
snpnet_BETAs_f       <- file.path(data_d, 'snpnet.tsv')
snpnet_covar_BETAs_f <- file.path(data_d, 'snpnet.covars.tsv')
family <- ifelse((startsWith(phenotype, 'INI') | startsWith(phenotype, 'QT_FC')), 'gaussian', 'binomial')

# output
eval_f <- file.path(data_d, 'snpnet.eval.tsv')
plot_f <- file.path(data_d, 'snpnet.plot.pdf')
percentile_f <- file.path(data_d, 'snpnet.percentile.tsv')

####################################################################

source('/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/helpers/snpnet_misc.R')

# read the raw phenotype file
fread(
    cmd=paste(cat_or_zcat(phe_f), phe_f,  '|', 'sed -e "s/^#//g"'),
    select=c('FID', 'IID', 'split', covariates, phenotype),
    colClasses = c('FID'='character', 'IID'='character'),
    data.table=F
) -> phe_df

if(refit){
    phe_df %>%
    mutate(
        split = if_else(split %in% c('train', 'val'), 'train_val', split)
    ) -> phe_df
}

# read PRS and covariate-based score
phe_df %>%
compute_phe_score_df(
    phenotype,
    str_replace_all(sscore_f, '__PHENOTYPE__', phenotype),
    str_replace_all(snpnet_covar_BETAs_f, '__PHENOTYPE__', phenotype),
    covariates, family, refit_split_strs
) -> phe_score_df

# evaluate the predictive performance
phe_score_df %>%
eval_performance(
    phenotype,
    str_replace_all(snpnet_BETAs_f, '__PHENOTYPE__', phenotype),
    family
) -> eval_df

eval_df %>%
rename('#phenotype_name' = 'phenotype_name') %>%
fwrite(str_replace_all(eval_f, '__PHENOTYPE__', phenotype), sep='\t', na = "NA", quote=F)

# prepare data frames for the plots
phe_score_df %>% filter(split == 'test') %>% drop_na(geno_score, phe) %>%
mutate(
    geno_score_percentile = rank(-geno_score) / n()
) -> plot_df

summary_plot_df <- plot_df %>%
compute_summary_df('geno_score_percentile', 'phe', family=family)

summary_plot_df %>%
rename('#l_bin' = 'l_bin') %>%
fwrite(percentile_f, sep='\t', na = "NA", quote=F)

if(family == 'gaussian'){
    p1 <- plot_df %>% plot_PRS_vs_phe() +
    theme(legend.position=c(.1, .8))+
    labs(title = phenotype, y = phenotype)

    p2 <- summary_plot_df %>%
    plot_PRS_bin_vs_phe(mean(plot_df$phe))+
    labs(title = phenotype, y = phenotype)
}else if(family == 'binomial'){
    p1 <- plot_df %>% plot_PRS_binomial() +
    labs(title = phenotype, x = phenotype)

    p2 <- summary_plot_df %>% plot_PRS_bin_vs_OR() +
    labs(title = phenotype)
}else{
    stop(sprintf('%s family is not supported!', family))
}

g <- gridExtra::arrangeGrob(p1, p2, ncol=2)
ggsave(plot_f, g, width=12, height=6)
ggsave(str_replace(plot_f, '.pdf$', '.png'), g, width=12, height=6)
