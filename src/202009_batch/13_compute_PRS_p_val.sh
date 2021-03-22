#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

GBE_ID=$1
src="13_compute_PRS_p_val.R"

ml load R/3.6 gcc

echo foo
Rscript ${src} ${GBE_ID}
