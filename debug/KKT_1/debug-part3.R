    cat("Recover iteration ", prevIter, ". Now time: ", as.character(Sys.time()), "\n", sep = "")
    load(file.path(results.dir, configs[["results.dir"]], paste0("output_iter_", prevIter, ".RData")))
    chr.to.keep <- setdiff(features.to.keep, covariates)
    load_start <- Sys.time()

    if (!is.null(features.train)) {
      features.train[, (chr.to.keep) := prepareFeatures(chr.train, chr.to.keep, stats, rowIdx.subset.train)]
    } else {
      features.train <- prepareFeatures(chr.train, chr.to.keep, stats, rowIdx.subset.train)
    }

    if (validation) {
      if (!is.null(features.val)) {
        features.val[, (chr.to.keep) := prepareFeatures(chr.val, chr.to.keep, stats, rowIdx.subset.val)]
      } else {
        features.val <- prepareFeatures(chr.val, chr.to.keep, stats, rowIdx.subset.val)
      }
    }

    load_end <- Sys.time()
    cat("Time elapsed on loading back features:", time_diff(load_start, load_end), "\n")
    prev.max.valid.idx <- max.valid.idx
