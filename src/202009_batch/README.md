# PRS map version `202009`

We have finalized the running parameters based on [the results from the test runs](/notebook/20200908_PRS_map_test).

## data location

- `/oak/stanford/groups/mrivas/projects/PRS/private_output/202009_batch`
  - currently, it's a symlink to a directory under `/scratch`
- [Google spreadsheet summarizing the performance of the models](https://docs.google.com/spreadsheets/d/1n-Lk2ooPJPG7Zbk8Vu43h_n9dzZWvV7elqQyclWvGI8/edit?usp=sharing)
  - We have two spreadsheets each corresponds to the initial fit with validation set or the refit with the combined (70 + 10) % (training + validation) set.

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

## aggregate the results

```{bash}
bash 5_agg_eval.sh
bash 5_agg_eval.sh refit
```

## snpnet version

We used `snpnet` versions from `snpnet_v.0.3.15` to `snpnet_v.0.3.17`.

