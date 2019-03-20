library(argparse)

snpnet_rds2table_parser <- function() {
    parser <- ArgumentParser(description='Convert snpnet RDS file to table file')

    parser$add_argument(
	'-i', metavar='I', required=TRUE, help='input RDS file'
    )
    parser$add_argument(
	'-o', metavar='O', required=TRUE, 
	help='output file head [O].tsv [O].covars.tsv'
    )
    parser$add_argument(
	'--bim', metavar='B', help='PLINK 1.9 .bim file', 
        default = '/oak/stanford/groups/mrivas/ukbb24983/cal/pgen/ukb24983_cal_cALL_v2.bim'
    )

    return(parser)
}

snpnet_fit2table <- function(fit) {
    df <- fit$beta[which.max(fit$metric.val)] %>% data.frame()
    colnames(df) <- 'BETA'

    df_separated <- df %>%
    rownames_to_column("feature") %>%
    separate(feature, into=c('ID', 'A1'), sep='_')

    return(df_separated)
}

snpnet_join_with_bim <- function(df, bim.file) {
# Define constants
    bim.cols <- c('CHROM', 'ID', 'CM', 'POS', 'ALT', 'REF')
    out.cols <- c('CHROM', 'POS', 'ID', 'REF', 'ALT', 'A1', 'BETA')
# read PLINK bim file
    bim.df <- fread(bim.file, data.table = FALSE)
    colnames(bim.df) <- bim.cols
# process the given data frame (join w/ bim)
    df_joined <- df %>%
    drop_na() %>%
    left_join(bim.df, on='ID') %>%
    select(out.cols) %>%
    arrange(CHROM, POS)
# return
    return(df_joined)
}

snpnet_extract_covars <- function(df) {
    df_slice <- df %>% 
    filter(is.na(A1)) %>% 
    select(ID, BETA)
# return
    return(df_slice)
}

snpnet_rds2table <- function(rda.file) {
# read snpnet results file
    fit <- readRDS(rda.file)
    return(snpnet_fit2table(fit))
}

# parse
cmdargs <- commandArgs(TRUE)
parser <- snpnet_rds2table_parser()
args <- parser$parse_args(cmdargs)
print(args)

# main
library(tidyverse)
library(data.table)
df <- snpnet_rds2table(args$i)
df_genotypes <- snpnet_join_with_bim(df, args$bim)
df_covars <- snpnet_extract_covars(df)
df_genotypes %>% write.table(
	paste0(args$o, '.tsv'), 
	quote=FALSE, row.names=FALSE, sep='\t'
)
df_covars %>% write.table(
	paste0(args$o, '.covars.tsv'), 
	quote=FALSE, row.names=FALSE, sep='\t'
)

