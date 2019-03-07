library(argparse)

snpnet_rds2table_parser <- function() {
    parser <- ArgumentParser(description='Convert snpnet RDS file to table file')

    parser$add_argument('-i', metavar='I', required=TRUE, help='input RDS file')
    parser$add_argument('-o', metavar='O', required=TRUE, help='output file')
    parser$add_argument('--bim', metavar='B', help='PLINK 1.9 .bim file', 
        default = '/oak/stanford/groups/mrivas/ukbb24983/cal/pgen/ukb24983_cal_cALL_v2.bim'
    )

    return(parser)
}

snpnet_rds2table <- function(rda.file, bim.file) {
# Define constants
    bim.cols <- c('CHROM', 'ID', 'CM', 'POS', 'ALT', 'REF')
    out.cols <- c('CHROM', 'POS', 'ID', 'REF', 'ALT', 'A1', 'BETA')
# read PLINK bim file
    bim.df <- fread(bim.file, data.table = FALSE)
    colnames(bim.df) <- bim.cols

# read snpnet results file
    fit <- readRDS(rda.file)
    df <- fit$beta[which.max(fit$metric.val)] %>% data.frame()
    colnames(df) <- 'BETA'

    new_df <- df %>%
    rownames_to_column("feature") %>%
    separate(feature, into=c('ID', 'A1'), sep='_') %>%
    drop_na() %>%
    left_join(bim.df, on='ID') %>%
    select(out.cols) %>%
    arrange(CHROM, POS)

# return
    return(new_df)
}

# parse
cmdargs <- commandArgs(TRUE)
parser <- snpnet_rds2table_parser()
args <- parser$parse_args(cmdargs)
print(args)

# main
library(tidyverse)
library(data.table)
df <- snpnet_rds2table(args$i, args$bim)
df %>% write.table(args$o, quote=FALSE, row.names=FALSE, sep='\t')

