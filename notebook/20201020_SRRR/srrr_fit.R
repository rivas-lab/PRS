# another example of SRRR
# /oak/stanford/groups/mrivas/users/mrivas/repos/multiresponse-ukbb/job_mr.R

suppressWarnings(suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
}))

args <- commandArgs(trailingOnly=TRUE)

####################################################################
# args
####################################################################

rank        <- as.integer(args[1])
prev_iter   <- as.integer(args[2])
mem         <- as.integer(args[3]) # 300000
nCores      <- as.integer(args[4]) # 16

####################################################################
# functions
####################################################################

library(glmnetPlus)
devtools::load_all('/oak/stanford/groups/mrivas/software/snpnet/snpnet_v.0.3.17')
devtools::load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/multiSnpnet')

compute_lambda_min_ratio <- function(nlambda.new, nlambda = 100, ratio = 0.01) {
  exp((nlambda.new-1)/(nlambda-1)*log(ratio))
}

####################################################################
# Configs
####################################################################

genotype_file    <- '/scratch/groups/mrivas/ukbb24983/array-combined/pgen/ukb24983_cal_hla_cnv'     # ukb genotype data 
phenotype_file   <- '/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200828.phe' # ukb master phe data 
phe_list_in      <- '/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200828.phe.info.tsv'
results_root_dir <- '/scratch/groups/mrivas/projects/PRS/private_output/20201020_SRRR' # parent results directory to save intermediate results
batch_size       <- 2000

weight <- NULL
# weight <- c(rep(1,8),rep(5))  # one can specify weights here

# other computational configurations

phenotype_names      <- fread(phe_list_in) %>% rename('GBE_ID'='#GBE_ID') %>% pull(GBE_ID)
results_dir          <- file.path(results_root_dir, paste0("results_rank_", rank, "/")) # subdirectory for each rank
covariate_names      <- c("age", "sex", paste0("PC", 1:10))
standardize_response <- TRUE  # should we standardize response beforehand (rescale when prediction for sure)
save                 <- TRUE  # should the program save intermediate results?
nlambda              <- 150
lambda.min.ratio     <- compute_lambda_min_ratio(nlambda)
max.iter             <- 30  # maximum BAY iteration
thresh               <- 1e-5  # convergence threshold
validation           <- TRUE  # is validation set provided
early_stopping       <- TRUE  # should we adopt early stopping
split.col            <- "split"

configs <- list(
    missing.rate        = 0.2,  # variants above this missing rate are discarded
    MAF.thresh          = 0.0001,  # MAF threshold
    nCores              = nCores,  # number of cores to be used
    bufferSize          = 50000,  # number of COLUMNS (Variants) the memory can hold at a time
    standardize.variant = FALSE,  # standardize predictors or not
    meta.dir            = "meta/",
    KKT.verbose         = FALSE,
    results.dir         = results_dir,
    thresh              = thresh,
    glmnet.thresh       = thresh
)

####################################################################
# main
####################################################################

fit <- multisnpnet(
    genotype_file = genotype_file, 
    phenotype_file = phenotype_file, 
    phenotype_names = phenotype_names, 
    covariate_names = covariate_names, 
    rank = rank, 
    batch_size = batch_size, 
    split_col = split.col,
    max.iter = max.iter, 
    configs = configs,
    lambda.min.ratio = lambda.min.ratio,
    nlambda = nlambda,
    standardize_response = standardize_response,
    save = save, 
    validation = validation, 
    prev_iter = prev_iter,
    early_stopping = early_stopping,
    weight = weight,
    mem = mem
)

save(fit, file = file.path(results_dir, paste0("multisnpnet.RData")))
