suppressPackageStartupMessages(require(tidyverse))
suppressPackageStartupMessages(require(data.table))

df <- fread('/home/users/ytanigaw/R/x86_64-pc-linux-gnu-library/3.5/snpnet/extdata/sample_phe.csv', sep=',')

cols <- df %>% colnames()

val <- sort(sample(1:nrow(df), nrow(df) * 0.2, replace = FALSE))

set.seed(20191021)

df %>% 
rename('IID' = 'ID') %>%
mutate(
    FID = IID,
    row_idx = 1:n(),
    split = if_else(row_idx %in% val, 'val', 'train')
) %>% 
select(c('FID', 'IID', cols[2:length(cols)], split)) %>%
fwrite(
    '/oak/stanford/groups/mrivas/projects/snpnet/sample_phe.phe', sep='\t'
)

