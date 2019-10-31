require(tidyverse)
require(data.table)
require(pgenlibr)
devtools::load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/snpnet')

### input file
pfile <- '/oak/stanford/groups/mrivas/projects/snpnet/sample_data/train'
gcount_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/meta/train.subset.gcount.tsv'
res_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5.tsv'

out_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5_lambda26.BEDMatrixPlus.tsv'

### load files

chr <- BEDMatrixPlus(paste0(pfile, ".bed"))

gcount_df <- fread(gcount_f)
res <- fread(res_f, sep='\t', head=T) %>% rename('ID' = 'V1')

res26 <- res %>% select('26') %>% pull()


out <- list()
out[["pnas"]]  <- gcount_df %>% select(stats_pNAs) %>% pull()
out[["means"]] <- gcount_df %>% select(stats_means) %>% pull()
out[["sds"]]   <- gcount_df %>% select(stats_SDs) %>% pull()
for(key in names(out)){
names(out[[key]]) <- gcount_df %>% select(ID) %>% pull()
}    
out[["excludeSNP"]] <- names(out[["means"]])[(out[["pnas"]] > 0.1) | (out[["means"]] < 2 * 0.001)]
stats <- out


vscores <- chunkedApply_missing(chr, matrix(res26, ncol=1), missing = stats[["means"]], nCores = 4, bufferSize = 6000, verbose = T, path = paste0(pfile, ".bed"))

as.data.frame(vscores) %>% rename('26' ='V1') %>% fwrite(out_f, sep='\t', row.names=T)