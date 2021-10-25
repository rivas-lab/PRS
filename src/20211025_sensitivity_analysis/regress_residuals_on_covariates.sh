#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

run-simg.sh Rscript regress_residuals_on_covariates.R $1
