fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################
in_snpnet_tsv_f <- args[1]
GBE_ID <- basename(dirname(in_snpnet_tsv_f))
gwas_f <- file.path(
    '/oak/stanford/groups/mrivas/ukbb24983/array-combined/gwas/current/white_british',
    sprintf('ukb24983_v2_hg19.%s.array-combined.glm.logistic.hybrid.gz', GBE_ID)
)
out_snpnet_gwas_f <- str_replace(in_snpnet_tsv_f, '.tsv$', '.gwasP.tsv')
out_cnt_f <- str_replace(in_snpnet_tsv_f, '.tsv$', '.cnt.tsv')
####################################################################

# read the variant annotation data


# read the penalty factor data
penalty <- readRDS('/oak/stanford/groups/mrivas/ukbb24983/array-combined/snpnet/penalty.rds')

penalty_df <- data.frame(ID_A1=names(penalty), penalty=penalty, stringsAsFactors=F) %>%
mutate(Csq = if_else(penalty == .5, 'PTVs', if_else(penalty == .75, 'PAVs', 'Others')))

# read the gwas df
gwas_df <- fread(gwas_f, select=c('ID', 'OR', 'P'), colClasses=c('ID'='character', 'OR'='numeric', 'P'='numeric'))

# read the snpnet BETA files and join them with the penalty factor category and GWAS OR and P
df <- fread(in_snpnet_tsv_f, colClasses=c('ID'='character')) %>%
mutate(ID_A1 = paste(ID, ALT, sep='_')) %>%
left_join(penalty_df %>% select(-penalty), by='ID_A1') %>%
left_join(gwas_df, by='ID') %>%
select(-ID_A1) %>%
rename('GWAS_OR'='OR', 'GWAS_P'='P') %>%
mutate(snpnet_OR = exp(BETA))

# count the number of PTVs, PAVs, and other variants along with
# along with whether they reached the GWAS-significant threshold (P < 5e-8)
cnt_df <- data.frame(
    is_GWAS_sig = c(rep(F,3), rep(T,3)),
    Csq = penalty_df %>% pull(Csq) %>% unique() %>% rep(2),
    n0 = rep(0, 6),
    stringsAsFactors=F
) %>%
left_join(
    df %>% 
    mutate(is_GWAS_sig = (GWAS_P < 5e-8)) %>%
    replace_na(list(is_GWAS_sig=F)) %>%
    count(is_GWAS_sig, Csq), 
    by=c('is_GWAS_sig', 'Csq')
) %>%
replace_na(list(n = 0)) %>%
mutate(n = n + n0) %>%
select(-n0)%>%
mutate(spread_col = paste(Csq, is_GWAS_sig, sep='_')) %>%
select(-Csq, -is_GWAS_sig) %>%
spread(spread_col, n) %>%
rename('PTVs_novel'='PTVs_FALSE', 'PAVs_novel'='PAVs_FALSE', 'Others_novel'='Others_FALSE') %>%
mutate(
    GBE_ID=GBE_ID,
    PTVs = PTVs_TRUE + PTVs_novel,
    PAVs = PAVs_TRUE + PAVs_novel,
    Others = Others_TRUE + Others_novel
) %>%
select(GBE_ID, PTVs, PAVs, Others, PTVs_novel, PAVs_novel, Others_novel)

# write to the output files
df %>%
rename('#CHROM' = 'CHROM') %>%
fwrite(out_snpnet_gwas_f, sep='\t', na = "NA", quote=F)

cnt_df %>%
rename('#GBE_ID' = 'GBE_ID') %>%
fwrite(out_cnt_f, sep='\t', na = "NA", quote=F)
