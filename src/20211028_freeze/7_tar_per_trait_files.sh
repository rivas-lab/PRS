#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

source paths.sh

cd ${PRS202110_d}

find per_trait \( -name "*.plot.p*" -o -name "*.snpnetBETAs.tsv" \) -print0 \
    | tar -cvzf per_trait.tar.gz --null -T -

