#!/bin/bash
set -beEuo pipefail

usage () {
    echo "$0: split phenotype file" >&2
    echo "$0:   The resulting test/val/train keep files have a similar case/control ratio " >&2
    echo "usage: $0 phe_file out_prefix <bin | qt | logistic | linear> [individuals_keep]" >&2
}

if [ $# -lt 2 ] ; then usage ; exit 1 ; fi

phe_file=$1
out_prefix=$2
phe_type=$3
if [ $# -gt 3 ] ; then individuals_keep=$4 ; fi

shuf_random_source="$(readlink -f $(dirname $0))/rand.seed.txt"
missing_value="-9"
split_types=("test" "val"  "train")
# split_types=("test" "val"  "train" "train_and_val")

# create a temp directory
tmp_dir=$(mktemp -d -p $LOCAL_SCRATCH tmp-$(basename $0)-$(date +%Y%m%d-%H%M%S)-XXXXXXXXXX) ; echo "tmp_dir = $tmp_dir"
handler_exit () { rm -rf $tmp_dir ; }
trap handler_exit EXIT

get_seeded_random () {
  seed="$1"
  # generate random file using openssl with a given seed
  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null
}

apply_shuf () {
    phe_f="$1"
    split_type="$2"

    n_indiv=$( cat $phe_f  | wc -l )
    n_test=$(  perl -e "print(int(0.2 * ${n_indiv}))" )
    n_val=$(   perl -e "print(int(0.2 * ${n_indiv}))" )
    n_test_plus_val=$( perl -e "print( ${n_test} + ${n_val} )" )

    if [   $split_type == "test" ] ; then
	idx_start=0 ;                  idx_end=${n_test} 
    elif [ $split_type == "val" ] ; then
	idx_start=${n_test} ;          idx_end=${n_test_plus_val} 
    elif [ $split_type == "train" ] ; then
	idx_start=${n_test_plus_val} ; idx_end=${n_indiv} 
    elif [ $split_type == "train_and_val" ] || [ $split_type == "val_and_train" ] ; then
	idx_start=${n_test} ;          idx_end=${n_indiv} 
    fi

    cat ${phe_f} \
	| shuf --random-source=<(get_seeded_random $(cat ${shuf_random_source})) \
	| awk -v OFS='\t' -v idx_s=$idx_start -v idx_e=$idx_end '( idx_s < NR && NR <= idx_e ){print $1, $1}' 
}

# configure
tmp_in_phe_file=${tmp_dir}/$(basename ${phe_file})
tmp_out_prefix=${tmp_dir}/$(basename ${out_prefix})


# keep individuals with non-missing phenotype values and apply --keep file
if [ $# -gt 3 ] ; then
    cat ${individuals_keep} | awk '{print $1}' | sort -k1b,1 \
	| join -1 1 -2 1 /dev/stdin <( cat ${phe_file} | sort -k1b,1 ) 
else
    cat $phe_file 
fi | awk -v missing_value=${missing_value} '$1 >= 0 && $3 != missing_value' > ${tmp_in_phe_file}

# split the phe file
if [ $phe_type == 'linear' ] || [ $phe_type == 'qt' ] ; then 

    for split_type in ${split_types[@]} ; do
	apply_shuf ${tmp_in_phe_file} ${split_type} > ${tmp_out_prefix}.${split_type}
    done

elif [ $phe_type == 'logistic' ] || [ $phe_type == 'bin' ] ; then

    tmp_in_phe_file_controls=${tmp_dir}/$(basename ${phe_file} .phe).controls.phe
    tmp_in_phe_file_cases=${tmp_dir}/$(basename ${phe_file} .phe).cases.phe
    cat ${tmp_in_phe_file} | awk '$3 == 1' > ${tmp_in_phe_file_controls}
    cat ${tmp_in_phe_file} | awk '$3 == 2' > ${tmp_in_phe_file_cases}

    for split_type in ${split_types[@]} ; do
	apply_shuf ${tmp_in_phe_file_controls} ${split_type} > ${tmp_out_prefix}.${split_type}
	apply_shuf ${tmp_in_phe_file_cases} ${split_type}   >> ${tmp_out_prefix}.${split_type}	
    done

fi

out_dir=$(dirname ${out_prefix})
if [ ! -d $out_dir ] ; then mkdir -p ${out_dir} ; fi

for split_type in ${split_types[@]} ; do
    cp -a ${tmp_out_prefix}.${split_type} ${out_dir} 
done

