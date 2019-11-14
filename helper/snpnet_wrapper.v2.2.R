fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

#require(tidyverse)
#require(data.table)
#require(glmnet)
#require(survival)


####################################################################
source(file.path(dirname(script.name), 'snpnet_misc.R'))
####################################################################

# read config file
config <- read_config_from_file(args[1])

# load snpnet
devtools::load_all(config[['snpnet.dir']])

# please check if glmnet version is >= 2.0.20
print(packageVersion("glmnet"))

print(config)

#############################
# call snpnet::snpnet()
fit <- snpnet(
    genotype.pfile = config[['genotype.pfile']],
    phenotype.file = config[['phenotype.file']],
    phenotype      = config[['phenotype.name']],
    status.col     = config[['status.col']],
    covariates     = config[['covariates']],
    split.col      = config[['split.col']],
    validation     = config[['validation']],
    family         = config[['family']],
    niter          = config[['niter']],
    results.dir    = config[['results.dir']],
    configs        = config
)
