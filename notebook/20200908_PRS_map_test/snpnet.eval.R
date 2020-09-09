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

# output
eval_f <- file.path(data_d, 'snpnet.eval.tsv')

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

# evaluate the predictive performance
eval_performance(
    phe_df, phenotype,
    str_replace_all(sscore_f, '__PHENOTYPE__', phenotype),
    str_replace_all(snpnet_BETAs_f, '__PHENOTYPE__', phenotype),
    str_replace_all(snpnet_covar_BETAs_f, '__PHENOTYPE__', phenotype),
    covariates,
    ifelse((startsWith(phenotype, 'INI') | startsWith(phenotype, 'QT_FC')), 'gaussian', 'binomial'),
    refit_split_strs
) -> eval_df

eval_df %>%
rename('#phenotype_name' = 'phenotype_name') %>%
fwrite(str_replace_all(eval_f, '__PHENOTYPE__', phenotype), sep='\t', na = "NA", quote=F)
