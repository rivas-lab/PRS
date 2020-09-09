fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################
source(file.path(dirname(script.name), 'eval_functions.R'))
####################################################################

GBE_ID <- args[1]

####################################################################

# input
data_d <- '/oak/stanford/groups/mrivas/projects/PRS/private_output/20200528-batch'
phe_f  <- '/oak/stanford/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20200522.phe'

# constants
covars <- c('age', 'sex', paste0('PC', 1:10))

# output
out_f <- file.path(data_d, GBE_ID, 'snpnet.eval.tsv')


####################################################################
phe_df <- read_phe_df_for_eval(phe_f, GBE_ID, covars)

split_strings <- phe_df %>% pull(split) %>% unique() %>% sort()

build_eval_df(phe_df, GBE_ID, split_strings) %>%
rename('#GBE_ID' = 'GBE_ID') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
