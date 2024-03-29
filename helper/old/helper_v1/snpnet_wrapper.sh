#!/bin/bash
set -beEuo pipefail
usage () {
    echo "$0: snpnet PRS R script wrapper" >&2
    echo "usage: $0 geno_dir pheno phe_name phe_type file_covar keep_train out [memory] [threads] [nPCs]" >&2
    echo "Input:"    
    echo "  geno_dir   we assume there are geno_dir/{train,val}.{bed,bim,fam}"
    echo "  pheno      phenotype file that has both response and covariates"
    echo "  phe_name   phenotype name (this should match with column name in pheno file)"
    echo "  phe_type   qt | bin | linear | logistic"
    echo "  file_covar covariates file"
    echo "  keep_train train.keep file"
    echo "  out        output file path (see Output section below)"
    echo "  nPCs       number of genotype PCs (for covariates)"
    echo "Output:"
    echo "  out/              (directory)"
    echo "  out.tsv.gz         BETA values for genotype"    
    echo "  out.covars.tsv.gz  BETA values for covariates"
}

get_glm_family () {
    phe_type=$1
    if [ ${phe_type} == 'linear' ] || [ ${phe_type} == 'qt' ] ; then
        glm_family='gaussian'
    elif [ ${phe_type} == 'logistic' ] || [ ${phe_type} == 'bin' ] ; then
        glm_family='binomial'
    fi
    echo ${glm_family}
}

find_prevIter () {
    dir=$1
    if [ $(find ${dir} -name "output_iter_*.rda" | wc -l) -gt 0 ] ; then
	find ${dir} -name "output_iter_*.rda" \
        | sort -Vr \
        | awk 'NR==1' \
        | awk -v FS='/' '{print $NF}' \
        | sed -e 's/^output_iter_//g' \
        | sed -s 's/.rda$//g'
    else
	echo 0
    fi
}

clean_up_intermediate_rda_files () {
    dir=$1
    prevIter=$( find_prevIter ${dir} )
    for iter in $( seq 0 ${prevIter} | grep -v 0 | sort -nr | awk 'NR>1' ) ; do
        rda_file="${dir}/results/output_iter_${iter}.rda"
        if [ -f ${rda_file} ] ; then rm ${rda_file} ; fi
    done
}

# parse command line args
if [ $# -lt 7 ] ; then usage ; exit 1 ; fi
geno=$1
pheno=$2
phe_name=$3
phe_type=$4
file_covar=$5
keep_train=$6
out=$7
if [ $# -gt 7 ] ; then memory=$8 ;  else memory=120000 ; fi
if [ $# -gt 8 ] ; then threads=$9 ; else threads=10 ; fi
if [ $# -gt 9 ] ; then nPCs=${10} ;   else nPCs=10 ; fi
if [ $# -gt 10 ] ; then
    covar_list=${11}
    covar_list_opt="--covarsList ${covar_list}"
else
    covar_list="None"
    covar_list_opt=""
fi

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir"
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

# scripts
helper_dir="$(dirname $(readlink -f $0))"
snpnet_fit_R="${helper_dir}/snpnet-fit.R"
covar_py="${helper_dir}/compute_covar_Z_transform_statistics.py"

# tmp files
tmp_head="${tmp_dir}/$(basename ${out})"
tmp_geno_1="${tmp_head}.1.tsv"
tmp_geno_2="${tmp_head}.2.tsv"
tmp_covar_1="${tmp_head}.1.covars.tsv"
tmp_covar_2="${tmp_head}.2.covars.tsv"
tmp_covar_3="${tmp_head}.3.covars.tsv"
snpnet_phe="${geno}/phe.tsv"

# output file
out_file_geno="${out}.tsv.gz"
out_file_covars="${out}.covars.tsv.gz"

# create output directory
if [ ! -d ${out} ] ; then mkdir -p ${out} ; fi

if [ ! -f ${snpnet_phe} ] ; then 
    cp ${pheno} ${snpnet_phe}
fi

if [ ! -f ${snpnet_phe%.tsv}.csv ] ; then 
    cat ${pheno} | cut -f2- | tr "\t" "," | sed -e 's/^IID/ID/g' > ${snpnet_phe%.tsv}.csv
fi

# check whether the output files exist
if [ ! -f ${out_file_geno} ] || [ ${covar_list} != "None" -a ! -f ${out_file_covars} ]  ; then

    glm_family=$( get_glm_family ${phe_type} )
    prevIter=$( find_prevIter ${out} )

    tmp_geno=${tmp_dir}/geno
    if [ ! -d ${tmp_geno} ] ; then mkdir -p ${tmp_geno} ; fi
    for split in "train" "val" ; do
        for ext in "bed" "bim" "fam" ; do
            cp ${geno}/${split}.${ext} ${tmp_geno}/${split}.${ext}
        done
    done
    tmp_pheno=${tmp_dir}/$(basename ${pheno})

    cp ${snpnet_phe%.tsv}.csv ${tmp_pheno}
#    cat ${pheno} | cut -f2- | tr "\t" "," | sed -e 's/^IID/ID/g' > ${tmp_pheno}

    echo Rscript ${snpnet_fit_R} -p ${pheno}     -n ${phe_name} -g ${geno}     -o ${out} --nPCs ${nPCs} --cpu ${threads} --mem ${memory} --prevIter ${prevIter} -f ${glm_family} -b ${tmp_geno_1%.tsv} ${covar_list_opt}
    echo Rscript ${snpnet_fit_R} -p ${tmp_pheno} -n ${phe_name} -g ${tmp_geno} -o ${out} --nPCs ${nPCs} --cpu ${threads} --mem ${memory} --prevIter ${prevIter} -f ${glm_family} -b ${tmp_geno_1%.tsv} ${covar_list_opt}
    Rscript      ${snpnet_fit_R} -p ${tmp_pheno} -n ${phe_name} -g ${tmp_geno} -o ${out} --nPCs ${nPCs} --cpu ${threads} --mem ${memory} --prevIter ${prevIter} -f ${glm_family} -b ${tmp_geno_1%.tsv} ${covar_list_opt}
#        --rds ${out}/results/output_iter_${prevIter}.rda
    
# beta for SNPs
    cat ${tmp_geno_1} | awk '(NR == 1){print "#" $0} ; (NR > 1){print $0}' > ${tmp_geno_2}

if [ -f ${tmp_covar_1} ] ; then     
# beta for covariates
    python ${covar_py} -i ${tmp_covar_1} -k ${keep_train} -c ${file_covar} -o ${tmp_covar_2}
    cat ${tmp_covar_2} | awk '(NR == 1){print "#" $0} ; (NR > 1){print $0}' > ${tmp_covar_3}
fi

# compress and copy
    bgzip ${tmp_geno_2}
    echo cp ${tmp_geno_2}.gz  ${out_file_geno}    
    cp ${tmp_geno_2}.gz  ${out_file_geno}    

    if [ -f ${tmp_covar_3} ] ; then 
        bgzip ${tmp_covar_3} 
        echo cp ${tmp_covar_3}.gz ${out_file_covars}
        cp ${tmp_covar_3}.gz ${out_file_covars}
    fi

# clean up intermediate rda files
    clean_up_intermediate_rda_files ${out}
    
fi

