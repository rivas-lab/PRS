# snpnet PRS models using the combined dataset of array-based and imputed variants

This includes array genotypes (cal), imputed CNVs, HLA, and imputed variants.

We use the following genotype data and penalty factor file as specified in our wrapper, `snpnet.sh`.

- `/scratch/groups/mrivas/ukbb24983/array_imp_combined/pgen_v2/ukb24983_cal_hla_cnv_imp`
- `/oak/stanford/groups/mrivas/ukbb24983/array_imp_combined/snpnet/penalty.v1.rds`

## data location

- `/scratch/groups/mrivas/projects/PRS/private_output/20211019_array_imp_combined`

We should move the results to `$OAK` once the computation is done

## submission commands

### submission for the initial fit (without refit)

```
[ytanigaw@sh03-12n24 ~/repos/rivas-lab/PRS/src/20211019_array_imp_combined] (job 35756724) $ bash 2a_submit.sh GBE_ID_list.txt
HC269 (refit: F)
HC382 (refit: F)
INI21001 (refit: F)
INI50 (refit: F)
```

### submission for the refit

```
$ bash 2a_submit.sh GBE_ID_list.txt refit
```

