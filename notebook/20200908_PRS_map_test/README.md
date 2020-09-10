# PRS map test run version `20200908`

## `2_p_factor_v2`

- 2020/9/10
- We have updated the penalty factor file (v2).
- The `snpnet.sh` is updated so that
  - No need to specify the family (default is AUTO - infer from the phenotype name)
  - Support refit with `--refit` option

### Job submission

```{bash}
# the initial fit with validation set

bash 1_submit.2_pfactor_v2.sh test.phes.lst

# refit

bash 1_submit.2_pfactor_v2.sh test.phes.lst refit
```

## `1_p_factor_v1`

- 2020/9/8-9
- We tested the new local PCs for WB
- We also tested the refit procedure
- The scripts are moved to `old_scripts` dir

```{bash}
bash 1_submit.sh test.phes.lst
```
