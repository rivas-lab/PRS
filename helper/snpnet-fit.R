library(argparse)
library(glmnetPlus)
library(snpnet)

snpnet_fit_parser <- function() {
    parser <- ArgumentParser(description='snpnet fit wrapper')

    parser$add_argument('-p', metavar='P', required=TRUE, help='Phenotype file (we assume this include both phenotype and covariates)')
    parser$add_argument('-n', metavar='N', required=TRUE, help='Phenotype name')

    parser$add_argument('-g', metavar='G', required=TRUE, help='Genotype dir')
    parser$add_argument('-o', metavar='O', required=TRUE, help='Results dir')
    parser$add_argument('-f', metavar='f', default='gaussian', help='family')

    parser$add_argument('--cpu', metavar='t', type="integer", help='CPU cores')
    parser$add_argument('--mem', metavar='m', type="integer", help='Memory (MB)')
    parser$add_argument('--nPCs', metavar='c', type="integer", default=10, help='The number of PCs (covariates)')

    return(parser)
}

# parse
cmdargs <- commandArgs(TRUE)
parser <- snpnet_fit_parser()
args <- parser$parse_args(cmdargs)

print(args)

bufferSize<-as.integer((args$mem) / 5)
print(paste0("buffer size: ", bufferSize))

# config
configs <- list(
   missing.rate = 0.1,
   MAF.thresh = 0.001,
   nCores = args$cpu,
   bufferSize = bufferSize,
   meta.dir = "meta/",
   nlams.init = 10,
   nlams.delta = 5
 )

# run snpnet
out <- snpnet(
   genotype.dir = args$g,
   phenotype.file = args$p,
   phenotype = args$n,
   results.dir = args$o,
   family = args$f,
   standardize.variant = FALSE,
   niter = 100,
   validation = TRUE,
   configs = configs,
   use.glmnetPlus = TRUE,
   verbose = TRUE,
   save = TRUE,
   covariates = c("age", "sex", paste0("PC", 1:(args$nPCs))),
   glmnet.thresh = 1e-12
)

