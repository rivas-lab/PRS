# PRS map version `202009`

We have finalized the running parameters based on [the results from the test runs](/notebook/20200908_PRS_map_test).

## data location

- `/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch`
  - currently, it's a symlink to a directory under `/scratch`

## job submission

We submit jobs using the wrapper script.

```{bash}
bash 2_submit.sh GBE_IDs/FH.lst
bash 2_submit.sh GBE_IDs/cancer.lst
```

For resubmission, we have a similar but more sophisicated script that focuses on the set of phenotypes that are actually making some progress.

```{bash}
bash 2b_submit.sh GBE_IDs_20200926/GBE_IDs.tsv
```


## snpnet version

We used `snpnet` versions from `snpnet_v.0.3.15` to `snpnet_v.0.3.17`.

