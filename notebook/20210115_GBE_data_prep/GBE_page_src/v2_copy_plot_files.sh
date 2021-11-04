#!/bin/bash
set -beEuo pipefail

SRCNAME=$(readlink -f $0)
SRCDIR=$(dirname ${SRCNAME})

if [ $# -ge 1 ] && [ $1 == "force" ] ; then force="TRUE" ; else force="FALSE" ; fi

src_d=/home/ytanigaw/repos/rivas-lab/PRS/src/20211028_freeze/
dst_d=/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRSmap/PRSmap_v2/

# table files
for file_basename in traits_w_metrics.tsv PRSmap.eval.tsv.gz ; do
    src_f=${src_d}/${file_basename}
    dst_f=${dst_d}/${file_basename}
    if [ -s ${src_f} ] ; then
        if [ "${force}" == "TRUE" ] || [ ! -f ${dst_f} ] ; then
            cp ${src_f} ${dst_f}
        fi
    fi
done

# summary plots
for ext in png pdf ; do
    for fam in binomial gaussian ; do
        for plot in h2_vs_geno size_vs_delta ; do
            src_f=${src_d}/${plot}_${fam}.${ext}
            dst_f=${dst_d}/${plot}_${fam}.${ext}
            if [ -s ${src_f} ] ; then
                if [ "${force}" == "TRUE" ] || [ ! -f ${dst_f} ] ; then
                    cp ${src_f} ${dst_f}
                fi
            fi
        done
    done
done
