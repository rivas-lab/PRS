  if (prevIter >= niter) stop("prevIter is greater or equal to the total number of iterations.")
  configs <- setup_configs_directories(configs, covariates, standardize.variant, early.stopping,
                           stopping.lag, save, results.dir)

  start.time.tot <- Sys.time()
  cat("Start snpnet:", as.character(start.time.tot), "\n")

  ### --- Process phenotypes --- ###
  cat("Preprocessing start:", as.character(Sys.time()), "\n")
  phe.master <- data.table::fread(phenotype.file, colClasses = c("FID" = "character", "IID" = "character"), select = c("FID", "IID", covariates, phenotype))
  cat_ids <- paste(phe.master$FID, phe.master$IID, sep = "_")
  # rownames(phe.master) <- phe.master$ID
  if (is.null(family)) {
    if (all(unique(phe.master[[phenotype]] %in% c(0, 1, 2, -9)))) {
      family <- "binomial"
    } else {
      family <- "gaussian"
    }
  }
  if (family == "binomial") phe.master[[phenotype]] <- phe.master[[phenotype]] - 1

  ### --- Check whether to use glmnet or glmnetPlus --- ###
  use.glmnetPlus <- checkGlmnetPlus(use.glmnetPlus, family)
  if (use.glmnetPlus) {
    glmnet.settings <- glmnetPlus::glmnet.control()
    on.exit(do.call(glmnetPlus::glmnet.control, glmnet.settings))
    glmnetPlus::glmnet.control(fdev = 0, devmax = 1)
  } else {
    glmnet.settings <- glmnet::glmnet.control()
    on.exit(do.call(glmnet::glmnet.control, glmnet.settings))
    glmnet::glmnet.control(fdev = 0, devmax = 1)
  }

  ### --- Process genotypes --- ###
  chr.train <- BEDMatrixPlus(file.path(genotype.dir, "train.bed"))
  n.chr.train <- nrow(chr.train)
  ids.chr.train <- rownames(chr.train)

  if (validation) {
    chr.val <- BEDMatrixPlus(file.path(genotype.dir, "val.bed"))
    n.chr.val <- nrow(chr.val)
    ids.chr.val <- rownames(chr.val)
  }

#   # asssume IDs in the genotype matrix must exist in the phenotype matrix, and stop if not #
#   check.missing <- ids.chr.train[!(ids.chr.train %in% cat_ids)]
#   if (validation) check.missing <- c(check.missing, ids.chr.val[!(ids.chr.val %in% cat_ids)])
#   if (length(check.missing) > 0) {
#     stop(paste0("Missing phenotype entry (", phenotype, ") for: ", utils::head(check.missing, 5), " ...\n"))
#   }

  ### --- Prepare the feature matrix --- ###
  rowIdx.subset.train <- which(ids.chr.train %in% cat_ids[phe.master[[phenotype]] != -9])  # missing phenotypes are encoded with -9
  n.subset.train <- length(rowIdx.subset.train)
  stats <- computeStats(chr.train, rowIdx.subset.train, stat = c("pnas", "means", "sds"),
                        path = file.path(results.dir, configs[["meta.dir"]]), save = save, configs = configs, verbose = verbose, buffer.verbose = buffer.verbose)
  phe.train <- phe.master[match(ids.chr.train, cat_ids), ]
  if (length(covariates) > 0) {
    features.train <- phe.train[, covariates, with = F]
    features.train <- features.train[rowIdx.subset.train, ]
  } else {
    features.train <- NULL
  }
  if (validation) {
    rowIdx.subset.val <- which(ids.chr.val %in% cat_ids[phe.master[[phenotype]] != -9])  # missing phenotypes are encoded with -9
    n.subset.val <- length(rowIdx.subset.val)
    phe.val <- phe.master[match(ids.chr.val, cat_ids), ]
    if (length(covariates) > 0) {
      features.val <- phe.val[, covariates, with = F]
      features.val <- features.val[rowIdx.subset.val, ]
    } else {
      features.val <- NULL
    }
  }

  ### --- Prepare the response --- ###
  # cat(paste0("Number of missing phenotypes in the training set: ", n.chr.train - n.subset.train, "\n"))
  response.train <- phe.train[[phenotype]][rowIdx.subset.train]
  if (validation) response.val <- phe.val[[phenotype]][rowIdx.subset.val]

  cat("Preprocessing end:", as.character(Sys.time()), "\n\n")
