fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################

regdom_vars_f <- args[1]
rds_in_f <- args[2]
rds_out_f <- args[3]

####################################################################

regdom_vars_f %>% fread() %>%
mutate(ID_ALT = paste(ID, ALT, sep='_')) %>%
pull(ID_ALT) -> regdom_vars

rds_in_f %>% readRDS() %>% enframe() %>%
mutate(value = if_else(name %in% regdom_vars, value * 0.8, value)) %>%
deframe() %>%
saveRDS(file = rds_out_f)