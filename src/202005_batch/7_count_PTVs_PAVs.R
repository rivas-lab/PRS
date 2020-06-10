fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################
in_snpnet_tsv_f <- args[1]
out_f <- str_replace(in_snpnet_tsv_f, '.tsv$', '.cnt.tsv')
####################################################################

GBE_ID <- basename(dirname(in_snpnet_tsv_f))

penalty <- readRDS('/oak/stanford/groups/mrivas/ukbb24983/array-combined/snpnet/penalty.rds')

penalty_df <- data.frame(
    ID_A1 = names(penalty),
    penalty = penalty,
    stringsAsFactors=F
) %>%
mutate(
    Csq = if_else(
        penalty == .5, 'PTVs',
        if_else(
            penalty == .75, 'PAVs', 'Others'
        )    
    )
)

count_csq <- function(beta_df, p_df=penalty_df){
    beta_df %>% 
    mutate(ID_A1 = paste(ID, ALT, sep='_')) %>%
    left_join(p_df, by='ID_A1') %>% count(Csq)
}

in_df <- fread(in_snpnet_tsv_f)

data.frame(
    Csq = penalty_df %>% pull(Csq) %>% unique(),
    n0 = c(0, 0, 0),
    stringsAsFactors=F
) %>%
left_join(
    in_df %>% count_csq(), by='Csq'
) %>%
replace_na(list(n = 0)) %>%
mutate(n = n + n0) %>%
select(-n0) %>%
spread(Csq, n) %>%
mutate(GBE_ID = GBE_ID) %>%
select(GBE_ID, PTVs, PAVs, Others) %>%
rename('#GBE_ID' = 'GBE_ID') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
