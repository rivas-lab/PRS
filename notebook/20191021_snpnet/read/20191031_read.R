suppressPackageStartupMessages(require(pgenlibr))
suppressPackageStartupMessages(require(tidyverse))
show_counts <- function(l){data.frame(x = l) %>% count(x) %>% print()}
pfile <- '/oak/stanford/groups/mrivas/projects/snpnet/sample_data/val'
variant_subset <- c(3530)
pvar <- NewPvar(paste0(pfile, '.pvar.zst'))

pgenlibr::GetVariantId(pvar, variant_subset[1]) %>% print()

pgen <- NewPgen(paste0(pfile, '.pgen'), pvar=pvar)
buf <- pgenlibr::Buf(pgen)

buf2d <- pgenlibr::ReadList(pgen, variant_subset, meanimpute=T)
show_counts(buf2d[,1])

pgenlibr::Read(pgen, buf, variant_subset[1])
show_counts(buf)

buf2d_no_impute <- pgenlibr::ReadList(pgen, variant_subset, meanimpute=F)
show_counts(buf2d_no_impute[,1])

