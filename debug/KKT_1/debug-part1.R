suppressPackageStartupMessages(require(tidyverse))
suppressPackageStartupMessages(require(data.table))
suppressPackageStartupMessages(require(glmnet))

snpnet_dir<-'/oak/stanford/groups/mrivas/software/snpnet'
mem2bufferSizeDivisionFactor<-4
cpu<-6
mem<-60000
niter<-100
genotype_dir<-'/scratch/users/ytanigaw/tmp/snpnet/geno/array_imp_combined'
data_dir_root<-'/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/public-resources/uk_biobank/biomarkers/snpnet/data_array_imp'
phenotype_file<-'biomarkers_covar.phe'
phenotype_name<-'Cystatin_C'
family<-'gaussian'
prevIter<-0

devtools::load_all(snpnet_dir)

genotype.dir <- genotype_dir
data_dir_root  <- data_dir_root
phenotype.name <- phenotype_name
phenotype.file <- file.path(data_dir_root, phenotype_file)
results.dir    <- file.path(data_dir_root, phenotype.name, 'results')
covariates     <- c()

print(phenotype.name)

phenotype = phenotype.name
nlambda = 100
lambda.min.ratio = NULL
num.snps.batch = 1000
increase.size = num.snps.batch/2
standardize.variant = FALSE
use.glmnetPlus = (family == 'gaussian')
stopping.lag = 2
early.stopping = TRUE
glmnet.thresh = 1E-7

configs = list(
    missing.rate = 0.1,
    MAF.thresh = 0.001,
    nCores = cpu,
    bufferSize = mem / mem2bufferSizeDivisionFactor,
    meta.dir = 'meta',
    nlams.init = 10,
    nlams.delta = 5
)
verbose = T
KKT.verbose = T
buffer.verbose = T
validation = T
save = R

