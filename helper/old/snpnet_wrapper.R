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

# call snpnet::snpnet
fit <- snpnet(
    genotype.dir = config[['genotype_dir']],
    phenotype.file = phenotype.file,
    phenotype = phenotype.name,
    covariates = covariates,
    family = config[['family']],
    results.dir = results.dir,
    niter = as.integer(config[['niter']]), 
    configs = list(
        missing.rate = 0.1,
        MAF.thresh = 0.001,
        nCores = as.integer(config[['cpu']]),
        bufferSize = as.integer(as.integer(config[['mem']]) / as.integer(config[['mem2bufferSizeDivisionFactor']])),
        meta.dir = "meta",
        nlams.init = 10,
        nlams.delta = 5
    ),
    verbose = T, validation = T, save = T,
    prevIter = as.integer(config[['prevIter']])
)

