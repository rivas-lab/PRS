suppressMessages(library(argparse))
suppressMessages(library(tidyverse))
suppressMessages(library(data.table))
suppressMessages(library(glmnetPlus))
#suppressMessages(library(snpnet))
library(devtools)
load_all('/oak/stanford/groups/mrivas/software/snpnet')
#load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/yk-tanigawa/snpnet')
#load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/snpnet')

snpnet_fit_parser <- function() {
    parser <- ArgumentParser(description='snpnet fit wrapper')

    parser$add_argument('-p', metavar='P', required=TRUE, help='Phenotype file (we assume this include both phenotype and covariates)')
    parser$add_argument('-n', metavar='N', required=TRUE, help='Phenotype name')

    parser$add_argument('-g', metavar='G', required=TRUE, help='Genotype dir')
    parser$add_argument('-o', metavar='O', required=TRUE, help='Results dir')
    parser$add_argument('-b', metavar='b', help='Output beta file head [b].tsv [b].covars.tsv')    
    parser$add_argument('-f', metavar='f', default='gaussian', help='family')
    
    parser$add_argument('--covarsList', metavar='C', 
        default='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/helper/snpnet-covars.default', 
        help='Covariates list file')

    parser$add_argument('--cpu', metavar='t', type="integer", help='CPU cores')
    parser$add_argument('--mem', metavar='m', type="integer", help='Memory (MB)')
    parser$add_argument('--nPCs', metavar='c', type="integer", default=10, help='The number of PCs (covariates)')
    parser$add_argument('--prevIter', metavar='i', type="integer", default=0, help='Resume from the previous iteration')
    parser$add_argument(
        '--bim', metavar='B', help='PLINK 1.9 .bim file', 
        default = '/oak/stanford/groups/mrivas/ukbb24983/cal/pgen/ukb24983_cal_cALL_v2.bim'
    )

    parser$add_argument('--rds', metavar='r', default=NULL, help='RDS file')
    
    return(parser)
}

read_file_as_list <- function(file){
    fread(
        file, head=FALSE
    ) %>% 
    dplyr::pull(V1) %>% 
    unlist() %>% 
    as.vector()
}

snpnet_fit2table <- function(fit) {
    df <- fit$beta[which.max(fit$metric.val)] %>% data.frame()
    colnames(df) <- 'BETA'
    df %>%
    rownames_to_column("ID") 
}

snpnet_join_with_bim <- function(df, covariates, bim.file) {
# Define constants
    bim.cols <- c('CHROM', 'ID', 'CM', 'POS', 'ALT', 'REF')
    out.cols <- c('CHROM', 'POS', 'ID', 'REF', 'ALT', 'A1', 'BETA')
# read PLINK bim file
    bim.df <- fread(bim.file, data.table = FALSE)
    colnames(bim.df) <- bim.cols
# process the given data frame (join w/ bim)
    if(is.null(covariates)){ 
        df_filtered <- df
    }else{
        df_filtered <- df %>% filter( ! ID %in% covariates ) 
    }
    df_joined <- df_filtered %>% filter( BETA != 0 ) %>% 
    separate( ID, into=c('ID', 'A1'), sep='_' ) %>% drop_na() %>%
    left_join(bim.df, on='ID') %>%
    select(out.cols) %>%
    arrange(CHROM, POS)
# return
    return(df_joined)
}

snpnet_fit_main <- function(args){

    if(! is.null(args$rds)){
        
        fit <- readRDS(args$rds)
        
    } else {
        
        mem2bufferSizeDivisionFactor<-4
        bufferSize<-as.integer((args$mem) / mem2bufferSizeDivisionFactor)
        print(paste0("buffer size: ", bufferSize))
        chunkSize <- as.integer(bufferSize / args$cpu)
        print(paste0("chunk size: ", chunkSize))
 
        # config
        configs <- list(
           missing.rate = 0.1,
           MAF.thresh = 0.001,
           nCores = args$cpu,
           bufferSize = bufferSize,
           chunkSize = chunkSize,
           meta.dir = "meta/",
           nlams.init = 10,
           nlams.delta = 5
         )

        if(args$covarsList == 'None'){
            covariates <- c()
        }else{
            covariates <- read_file_as_list(args$covarsList)
#             covariates <- c("age", "sex", paste0("PC", 1:(args$nPCs)))
        }
        print(covariates)
        # run snpnet
        fit <- snpnet(
           genotype.dir = args$g,
           phenotype.file = args$p,
           phenotype = as.character(args$n),
           results.dir = args$o,
           family = args$f,
           standardize.variant = FALSE,
           niter = 100,
           validation = TRUE,
           configs = configs,
           use.glmnetPlus = TRUE,
           verbose = TRUE,
           save = TRUE,
           prevIter = args$prevIter,
           covariates = covariates,
           glmnet.thresh = 1e-7
        )
    }
    
    # extract beta values and write them to files
    df <- snpnet_fit2table(fit)
    # beta for genotypes
    df_genotypes <- df %>% 
    snpnet_join_with_bim(covariates, args$bim)
    df_genotypes %>% write.table(
        paste0(args$b, '.tsv'), 
        quote=FALSE, row.names=FALSE, sep='\t'
    )
    if(!is.null(covariates)){
    # beta for covariates
    df_covars <- df %>% filter(
        ID %in% covariates
    ) %>% select(
        ID, BETA
    )
    df_covars %>% write.table(
        paste0(args$b, '.covars.tsv'), 
        quote=FALSE, row.names=FALSE, sep='\t'
    )    
    }
}

# parse
cmdargs <- commandArgs(TRUE)
parser <- snpnet_fit_parser()
args <- parser$parse_args(cmdargs)
print(args)
snpnet_fit_main(args)
