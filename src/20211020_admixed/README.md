# snpnet PRS models for admixed individuals (others)

We fit snpnet using the individuals in `others`. The training, validation, and test set split is specified in population stratification version 20211020.

## data location

- `/scratch/groups/mrivas/projects/PRS/private_output/20211020_admixed/snpnet.admixed`

We should move the results to `$OAK` once the computation is done

## submission commands

### submission for the initial fit (without refit)

```
[ytanigaw@sh03-12n24 ~/repos/rivas-lab/PRS/src/20211020_admixed] (job 35756724) $ bash 2a_submit.sh GBE_ID_list.txt
HC269 (refit: F)
HC382 (refit: F)
INI21001 (refit: F)
INI50 (refit: F)
```

### submission for the refit

```
$ bash 2a_submit.sh GBE_ID_list.txt refit
```

