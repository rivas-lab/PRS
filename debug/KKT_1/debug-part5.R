# ### --- KKT Check --- ###
#     if (verbose) cat("  Start checking KKT condition ...\n")
#     start.KKT.time <- Sys.time()
#     gc()
    
debug.KKT.residual = residual.full
debug.KKT.chr = chr.train
debug.KKT.subset = rowIdx.subset.train
debug.KKT.current.lams = current.lams[start.lams:num.lams]
debug.KKT.prev.lambda.idx = ifelse(use.glmnetPlus, 1, lambda.idx)
debug.KKT.stats = stats
debug.KKT.glmfit = glmfit
debug.KKT.configs = configs
debug.KKT.verbose = buffer.verbose
debug.KKT.results.verbose = KKT.verbose
debug.KKT.path = file.path(genotype.dir, "train.bed")


save(
    debug.KKT.residual,
    debug.KKT.chr,
    debug.KKT.subset,
    debug.KKT.current.lams,
    debug.KKT.prev.lambda.idx,
    debug.KKT.stats,
    debug.KKT.glmfit,
    debug.KKT.configs,
    debug.KKT.verbose,
    debug.KKT.results.verbose,
    debug.KKT.path,
    file='debug.data.iter2.RData'
)
