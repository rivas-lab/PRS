suppressMessages(require(tidyverse))
suppressMessages(require(data.table))
suppressMessages(require(glmnet))
suppressMessages(require(devtools))
# suppressMessages(require(survival))

load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet_cox')

# please check if glmnet version is >= 2.0.20
packageVersion("glmnet")

mem2bufferSizeDivisionFactor<-4 # this is Yosuke's magic number

# [ytanigaw@sh-116-04 /lscratch/ytanigaw/snpnet-geno]$ for s in train val ; do for ext in bim fam bed ; do cp /oak/stanford/groups/mrivas/projects/PRS/private_data/split/ukb24983_cal_hla_cnv_white_british/${s}.${ext} . ; done ; done

data_dir_root <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/jobs/hearing_2247'
phenotype.name <- 'BIN_FC1002247'
#phenotype.name <- 'BIN_FC3002247'

genotype.dir.tmp <- file.path('/lscratch/ytanigaw/snpnet-geno')
genotype.dir     <- '/oak/stanford/groups/mrivas/projects/PRS/private_data/split/ukb24983_cal_hla_cnv_white_british'
phenotype.file   <- file.path(data_dir_root, 'phe.tsv')
results.dir      <- file.path(data_dir_root, phenotype.name, 'results')

cpu <- 24 # 24 cores
mem <- 370000 # 370 GB memory
niter <- 100

configs <- list(
    missing.rate = 0.1,
    MAF.thresh = 0.001,
    nCores = cpu,
    bufferSize = as.integer((mem) / mem2bufferSizeDivisionFactor),
    meta.dir = "meta",
    nlams.init = 10,
    nlams.delta = 5
)

fit <- snpnet(
    genotype.dir = genotype.dir.tmp,
    phenotype.file = phenotype.file,
    phenotype = phenotype.name,
    covariates = c("sex", "age", paste0("PC", 1:10)),
    family = 'binomial', use.glmnetPlus = FALSE,
    results.dir = results.dir, niter = niter, configs = configs, standardize.variant = FALSE,
    verbose = TRUE, validation = TRUE, save = TRUE, glmnet.thresh = 1e-7
)
