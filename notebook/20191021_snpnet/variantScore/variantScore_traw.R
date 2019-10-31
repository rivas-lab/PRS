require(tidyverse)
require(data.table)

### input file
pfile <- '/oak/stanford/groups/mrivas/projects/snpnet/sample_data/train'
gcount_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/meta/train.subset.gcount.tsv'
res_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5.tsv'

out_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5_lambda26.traw.tsv'

### load files

traw <- fread(paste0(pfile, '.traw'))
sample_IDs <- traw %>% colnames() %>% tail(length(colnames(traw)) -6)
variant_IDs <- traw %>% mutate(ID = paste0(SNP, '_', ALT)) %>% select(ID) %>% pull()

geno_mat <- as.matrix(2 - traw %>% select(-CHR, -SNP, -'(C)M', -POS, -COUNTED, -ALT))
rownames(geno_mat) <- variant_IDs

res <- fread(res_f, sep='\t', head=T) %>% rename('ID' = 'V1')
res26 <- res %>% select('26') %>% pull()

for(i in 1:10){
    geno_mat[i, is.na(geno_mat[i, ])] <- mean(geno_mat[i, ], na.rm=T)
}


vscores <- (geno_mat[1:10, ] %*% matrix(res26, ncol=1) )

as.data.frame(vscores) %>% rename('26' ='V1') %>% fwrite(out_f, sep='\t', row.names=T)
