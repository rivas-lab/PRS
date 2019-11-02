fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

require(tidyverse)
require(data.table)
require(glmnet)
require(survival)

####################################################################
source(file.path(dirname(script.name), 'snpnet_misc.R'))
####################################################################

# read config file
config <- read_config_from_file(args[1])

# load snpnet
devtools::load_all(config[['snpnet_dir']])

# please check if glmnet version is >= 2.0.20
print(packageVersion("glmnet"))

# configue parameters
out_dir_root   <- config[['out_dir_root']]
phenotype.name <- config[['phenotype_name']]
phenotype.file <- config[['phenotype_file']]
results.dir    <- file.path(out_dir_root, phenotype.name, 'results')
covariates     <- parse_covariates(config[['covariates']])

print(phenotype.name)

#############################
# phe.dt <- data.table::fread(
#     phenotype.file, colClasses = c("FID" = "character", "IID" = "character"),
#     select = c("FID", "IID", covariates, split, phenotype.name)
# )

#############################
# call snpnet::snpnet
fit <- snpnet(
    genotype.pfile = config[['genotype_pfile']],
    phenotype.file = phenotype.file,
    split.col = config[['split_col']],
    phenotype = phenotype.name,
    covariates = covariates,
    family = config[['family']],
    results.dir = results.dir,
    niter = as.integer(config[['niter']]), 
    configs = list(
        nCores = as.integer(config[['cpu']]),
        bufferSize = as.integer(as.integer(config[['mem']]) / as.integer(config[['mem2bufferSizeDivisionFactor']])),
        save = F,
        prevIter = as.integer(config[['prevIter']]),
        verbose = T
    ),
    validation = T
)
