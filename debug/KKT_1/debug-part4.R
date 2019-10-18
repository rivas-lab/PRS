iter <- 2
    cat("Iteration ", iter, ". Now time: ", as.character(Sys.time()), "\n", sep = "")
    start.iter.time <- Sys.time()

    num.lams <- min(num.lams + ifelse(lambda.idx >= num.lams-configs[["nlams.delta"]]/2, configs[["nlams.delta"]], 0),
                    nlambda)   ## extend lambda list if necessary
    num.lams <- min(num.lams, lambda.idx + ifelse(is.null(num.new.valid), Inf, max(c(utils::tail(num.new.valid, 3), 1))))

    ### --- Update the feature matrix --- ###
    if (verbose) cat("  Start updating feature matrix ...\n")
    start.update.time <- Sys.time()
    if (iter > 1) {
      features.to.discard <- setdiff(colnames(features.train), features.to.keep)
      if (length(features.to.discard) > 0) {
        features.train[, (features.to.discard) := NULL]
        if (validation) features.val[, (features.to.discard) := NULL]
      }
      which.in.model <- which(names(score) %in% colnames(features.train))
      score[which.in.model] <- NA
    }
    sorted.score <- sort(score, decreasing = T, na.last = NA)
    if (length(sorted.score) > 0) {
      features.to.add <- names(sorted.score)[1:min(num.snps.batch, length(sorted.score))]
      features.add.train <- prepareFeatures(chr.train, features.to.add, stats, rowIdx.subset.train)
      if (!is.null(features.train)) {
        features.train[, colnames(features.add.train) := features.add.train]
        rm(features.add.train)
      } else {
        features.train <- features.add.train
      }
      if (validation) {
        features.add.val <- prepareFeatures(chr.val, features.to.add, stats, rowIdx.subset.val)
        if (!is.null(features.val)) {
          features.val[, colnames(features.add.val) := features.add.val]
          rm(features.add.val)
        } else {
          features.val <- features.add.val
        }
      }
    } else {
      break
    }
    end.update.time <- Sys.time()
    if (increase.snp.size)  # increase batch size when no new valid solution is found in the previous iteration, but after another round of adding new variables
      num.snps.batch <- num.snps.batch + increase.size
    if (verbose) cat("  End updating feature matrix. Time elapsed:", time_diff(start.update.time, end.update.time), "\n")
    if (verbose) {
      cat("  -- Number of ever-active variables: ", length(features.to.keep), ".\n", sep = "")
      cat("  -- Number of newly added variables: ", length(features.to.add), ".\n", sep = "")
      cat("  -- Total number of variables in the strong set: ", ncol(features.train), ".\n", sep = "")
    }
    ### --- Fit glmnet --- ###
    if (verbose) cat("  Start fitting Glmnet ...\n")
    penalty.factor <- rep(1, ncol(features.train))
    penalty.factor[seq_len(length(covariates))] <- 0
    current.lams <- full.lams[1:num.lams]
    current.lams.adjusted <- full.lams[1:num.lams] * sum(penalty.factor) / length(penalty.factor)  # adjustment to counteract penalty factor normalization in glmnet
    start_time_glmnet <- Sys.time()
    if (use.glmnetPlus) {
      start.lams <- lambda.idx   # start index in the whole lambda sequence
      if (!is.null(prev.beta)) {
        beta0 <- rep(1e-20, ncol(features.train))
        beta0[match(names(prev.beta), colnames(features.train))] <- prev.beta
      } else {
        beta0 <- prev.beta
      }
      glmfit <- glmnetPlus::glmnet(features.train, response.train, family = family, lambda = current.lams.adjusted[start.lams:num.lams], penalty.factor = penalty.factor, standardize = standardize.variant, thresh = glmnet.thresh, type.gaussian = "naive", beta0 = beta0)
    } else {
      start.lams <- 1
      features.train.matrix <- as.matrix(features.train)
      glmfit <- glmnet::glmnet(features.train.matrix, response.train, family = family, lambda = current.lams.adjusted[start.lams:num.lams], penalty.factor = penalty.factor, standardize = standardize.variant, thresh = glmnet.thresh, type.gaussian = "naive")
    }
    glmnet.results[[iter]] <- glmfit
    if (use.glmnetPlus) {
      residual.full <- glmfit$residuals
      pred.train <- response.train - residual.full
    } else {
      pred.train <- stats::predict(glmfit, newx = features.train.matrix, type = "response")
      residual.full <- response.train - pred.train
      rm(features.train.matrix) # save memory
    }
    end_time_glmnet <- Sys.time()
    if (verbose) cat("  End fitting Glmnet. Elapsed time:", time_diff(start_time_glmnet, end_time_glmnet), "\n")
