# PRS map test run version `20200908`

We have explored several parameters.

- Penalty factor based on variant annotation
  - Please see [`ukbb-tools`](https://github.com/rivas-lab/ukbb-tools/tree/master/03_filtering/array-combined#penalty-factor-for-snpnet) repo for the penalty factor.
  - We also consider incorporating the annotations from Human Phenotype Ontology (HPO).
- We have also examined the early stopping criteria.
  - Please see [`AUC_diff_p_analysis`](AUC_diff_p_analysis) for more details.

## How to update the GBE snpnet page?

The snpnet page is defined in `snpnet_page` function in `gbe.py`.

We have example pages:

- https://gbe.stanford.edu/RIVAS_HG19/snpnet/HC269
- https://gbe.stanford.edu/RIVAS_HG19/snpnet/HC382
- https://gbe.stanford.edu/RIVAS_HG19/snpnet/INI50
- https://gbe.stanford.edu/RIVAS_HG19/snpnet/INI21001

```{bash}
scp snpnet.html gbe:/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
```

The files are in our usual place: `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser`
`templates/snpnet.html` is the Flask template. It's called from `snpnet_page` function in `gbe.py`.
The image data is in `static/PRS_map/`

## `5_p_factor_v3`

- 2020/9/14
- We have updated penalty factor to v4 (0.5, 0.75, and 1.0 only with VEP v101).
- We incorporate the Mendelian gene annotation in Human Phenotype Ontology

```{bash}
# the initial fit with validation set

bash 1_submit.5_regDoms_pfactor_v4.sh test.HC_phes.lst

# refit

bash 1_submit.5_regDoms_pfactor_v4.sh test.HC_phes.lst refit
```


## `4_regDoms_pfactor`

- 2020/9/14
- We incorporate the Mendelian gene annotation in Human Phenotype Ontology
- The base penalty factor is v3.

```{bash}
# the initial fit with validation set

bash 1_submit.4_regDoms_pfactor.sh test.HC_phes.lst

# refit

bash 1_submit.4_regDoms_pfactor.sh test.HC_phes.lst refit
```

## `3_p_factor_v3`

- 2020/9/13
- We have again updated the penalty factor file (v3).
- We applied VEP version 101.
- For we applied weights of .9 to varinats on coding sequence

```{bash}
# the initial fit with validation set

bash 1_submit.3_pfactor_v3.sh test.phes.lst

# refit

bash 1_submit.3_pfactor_v3.sh test.phes.lst refit
```

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
