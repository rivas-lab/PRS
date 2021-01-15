fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################
sub_d <- args[1]
PRS_sscore_list_f <- '/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch/snpnet.sscore.2_refit.tsv'
####################################################################
source('/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/helpers/snpnet_misc.R')
####################################################################

# get the list of PRS .sscore files
PRS_sscore_list_f %>% fread(head=F) %>%
rename('GBE_ID'=1, 'sub_dir'=2, 'sscore_f'=3) -> PRS_sscore_list_df

# read the sscore files into a data frame
PRS_sscore_list_df %>% filter(sub_dir==sub_d) %>%
pull(sscore_f) %>%
lapply(function(sscore_f){
    gbeid = basename(dirname(dirname(sscore_f)))
    message(sprintf('%s %s', format(Sys.time(), format="%Y%m%d-%H%M%S")
, gbeid))
    read_PRS(sscore_f) %>% rename(!!sprintf('PRS_%s', gbeid) := 'geno_score')
}) %>% reduce(function(x, y){inner_join(x, y, by=c('FID', 'IID'))}) -> PRS_df

# write the results to a file
PRS_df %>%
rename('#FID' = 'FID') %>%
fwrite(file.path(dirname(PRS_sscore_list_f), sub_d, sprintf('snpnet.2_refit.PRSs.%s.phe', sub_d)), sep='\t', na = "NA", quote=F)
