# PRS (polygenic risk score)

This repository is to run PRS models across various phenotypes in the UK Biobank.


## Where can you find the data?

### Where is the data directory?
We store the output from this repo into two places:
- `private_output`
  - `/oak/stanford/groups/mrivas/projects/PRS/private_output/`
  - This contains individual-level data, such as the PRS score computed for each individual.
  - I would recommend to make a symbolic link so that you can access this directory with `<repository_root>/private_output`
- `public_output`
  - https://github.com/rivas-lab/PRS/tree/master/public_output
  - This contains non-private outputs from the repo, such as evaluation metric (R/AUC).

### Directory structure
- We have multiple PRS models supported in this repo. This includes:
  - `vanilla_PRS`: The canonical PRS with p-value cut-off and LD-clumping
  - `snpnet_PRS`: Junyang's snpnet (https://github.com/junyangq/snpnet)
- In general we structure the repository so that the results (and pipeline) for each model is kept separate:
  - `<repository_root>/[src | public_output | private_output | jobs]/<PRS_model>/`
  - The only exception is in `helper` directory because we share the same scripts across multiple models (such as the one for evaluation)
- `src`
  - This directory contains pipeline (bash script) that can run particular PRS model.
  - If you run `$bash src/script.sh`, it should dump usage.
- `helpr`
- `jobs`
- `public_output`

### example
- The score file is stored here:
  - `$OAK/projects/PRS/private_output/snpnet_PRS/<dataset_name>/4_score/<GBE_ID>.sscore`
  - For example, IOP score is in: `$OAK/projects/PRS/private_output/snpnet_PRS/test/4_score/INI5255.sscore`

## Getting started

0. Install packages

```
$ ml load R gcc/8.1.0
$ R
> # If you don't have devtools on R, please install it.
> # install.packages("devtools") 
> library(devtools)
> install_github("junyangq/snpnet")
> # snpnet depends on glmnetPlus package. 
> # This package is in Junyang's private repo.
> # You may use a copy on $OAK
> install_local('/oak/stanford/groups/mrivas/software/glmnetPlus')
> # Plase make sure you can load the new packages
> library(glmnetPlus)
> library(snpnet)
```

1. Clone the repo and create a symbolic link to `private_output`

```
$ cd $OAK/users/$USER/repos/rivas-lab
$ git clone git@github.com:rivas-lab/PRS.git
$ cd PRS
$ ln -s $OAK/projects/PRS/private_output .
```

2. load the relevant modules

```
$ ml load plink plink2 htslib R gcc/8.1.0 anaconda
```

3. run snpnet_PRS or vanilla_PRS

```
$ cd $OAK/users/$USER/repos/rivas-lab/PRS/src
$ PRS_model="snpnet_PRS"
$ dataset_name="test_$USER"
$ memory=120000 # 120 GB
$ threads=10 # 10 CPUs
$ app_id=24983
$ n_PCs=10
$ bash snpnet_PRS.sh [ GBE_ID | phe_file.phe ] [ qt | bin ] keep.phe $OAK/projects/PRS/private_output/${PRS_model}/${dataset_name} ${memory} ${threads} ${app_id} ${nPCs}
```

You sould be able to run `$OAK/users/$USER/repos/rivas-lab/PRS/src/vanilla_PRS.sh` in a very similar way. 


