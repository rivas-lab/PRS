require(tidyverse)
require(data.table)
require(pgenlibr)
devtools::load_all('/oak/stanford/groups/mrivas/users/ytanigaw/repos/junyangq/snpnet')

### input file
pfile <- '/oak/stanford/groups/mrivas/projects/snpnet/sample_data/train'
gcount_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/meta/train.subset.gcount.tsv'
res_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5.tsv'

out_f <- '/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/PRS/notebook/20191021_snpnet/private_out/9/QPHE/results/debug/residuals_iter_5_lambda26.tsv'

### load files

pvar <- NewPvar(paste0(pfile, '.pvar.zst'))
pgen <- NewPgen(paste0(pfile, '.pgen'), pvar=pvar)
gcount_df <- fread(gcount_f)
res <- fread(res_f, sep='\t', head=T) %>% rename('ID' = 'V1')

res26 <- res %>% select('26') %>% pull()

vscores <- matrix(VariantScores(pgen, res26), ncol=1)
rownames(vscores) <- gcount_df %>% select(ID) %>% pull()

as.data.frame(vscores) %>% rename('26' ='V1') %>% fwrite(out_f, sep='\t', row.names=T)
