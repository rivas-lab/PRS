#!/bin/bash
set -beEuo pipefail

usage () {
    echo "usage: $0 sumstats clumped out" >&2
}

if [ $# -lt 3 ] ; then usage ; exit 1 ; fi

sumstats=$1
clumped=$2
out=${3%.gz}

if [ ! -f ${out}.gz ] ; then
	zcat ${sumstats} | egrep '^#'  > $out
	zcat ${clumped} | awk 'NR>1 {print $3, $NF}' \
        | sed -e 's/(1)//g' | sed -e 's/,/ /g' \
        | tr " " "\n" | grep -v "NONE" | sort -k1b,1 \
		| join -1 1 -2 3 /dev/stdin <( zcat ${sumstats} | egrep -v '^#' | sort -k3b,3 ) \
		| awk -v OFS='\t' '{print $2, $3, $1, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13}' | sort -k1b,1 -k2n,2  >> ${out} 
	bgzip $out
fi
