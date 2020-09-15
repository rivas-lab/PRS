fullargs <- commandArgs(trailingOnly=FALSE)
args <- commandArgs(trailingOnly=TRUE)

script.name <- normalizePath(sub("--file=", "", fullargs[grep("--file=", fullargs)]))

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(data.table))

####################################################################

data_d <- args[1]
out_f <- args[2]

####################################################################


find_latest_intermediate_file <- function(results_d){
    fs <- file.path(results_d, 'output_iter*.RData')
    Sys.glob(fs, dirmark = FALSE) %>%
    lapply(function(f){
        basename(f) %>% 
        str_remove_all('^output_iter_|.RData$') %>%
        as.integer()
    }) %>% simplify() %>% sort(decreasing = T) %>%
    first() -> latest_idx
    file.path(results_d, sprintf('output_iter_%d.RData', latest_idx))
}

read_RData_to_metric_df <- function(datad){
    tmp_env <- new.env()    
    rdf <- file.path(datad, 'snpnet.RData')
    if(file.exists(rdf)){
        message(rdf)
        load(rdf, envir = tmp_env)
        
        data.frame(
            train = (tmp_env$fit)$metric.train, 
            val   = (tmp_env$fit)$metric.val
        ) %>% mutate(lambda_idx = 1:n()) %>% drop_na(train, val)
    }else{
        rdf <- find_latest_intermediate_file(file.path(datad, 'results'))        
        if(file.exists(rdf)){
            message(rdf)
            load(rdf, envir = tmp_env)            
            data.frame(
                train = tmp_env$metric.train, 
                val   = tmp_env$metric.val
            ) %>% mutate(lambda_idx = 1:n()) %>% drop_na(train, val)
        }
    }
}

data_d %>% read_RData_to_metric_df() %>%
select(lambda_idx, train, val) %>%
rename('#lambda_idx' = 'lambda_idx') %>%
fwrite(out_f, sep='\t', na = "NA", quote=F)
