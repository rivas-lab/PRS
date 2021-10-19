# snpnet PRS models without penalty factors

## data location

- `/scratch/groups/mrivas/projects/PRS/private_output/20211019_no-pfactor`

We should move the results to `$OAK` once the computation is done

## submission commands

### submission for the initial fit (without refit)

```
[ytanigaw@sh03-12n24 ~/repos/rivas-lab/PRS/src/20211019_no-pfactor] (job 35756724) $ bash 2a_submit.sh GBE_ID_list.txt
HC269 (refit: F)
HC382 (refit: F)
INI21001 (refit: F)
INI50 (refit: F)
```

### submission for the refit

```
$ bash 2a_submit.sh GBE_ID_list.txt refit
```

