fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)
script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))
#########################################################
cpu<-as.integer(args[1])
mem<-as.integer(args[2])
#########################################################
mem2bufferSizeDivisionFactor<-4

suppressPackageStartupMessages(require(tidyverse))
suppressPackageStartupMessages(require(data.table))
suppressPackageStartupMessages(require(glmnet))

snpnet_dir<-'/oak/stanford/groups/mrivas/software/snpnet'
devtools::load_all(snpnet_dir)

load('/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/debug/KKT_1/debug.data.iter2.RData')

residual <- debug.KKT.residual
chr      <- debug.KKT.chr
subset   <- debug.KKT.subset
stats    <- debug.KKT.stats
configs  <- debug.KKT.configs
path     <- debug.KKT.path

n.chr <- nrow(chr)
n.subset <- length(subset)
residual.full <- matrix(0, n.chr, ncol(residual))
residual.full[subset, ] <- residual

print(sprintf('cpu: %d', cpu))
print(sprintf('mem: %d', mem))
t_s <- Sys.time()
print(t_s)

prod.full <- chunkedApply_missing(
    chr, 
    residual.full, 
    missing = stats[["means"]], 
    nCores = cpu,
    bufferSize = mem / mem2bufferSizeDivisionFactor,
    verbose = T, 
    path = path
)

t_e <- Sys.time()
print(t_e)
print('==========results==========')
print(sprintf('cpu: %d', cpu))
print(sprintf('mem: %d', mem))
print(t_e - t_s)
print(gc())
