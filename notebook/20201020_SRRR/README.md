# SRRR analysis

We apply sparse reduced rank regression (SRRR) implemented in R `multiSnpnet` package to fit multi-variate and multi-response sparse regression model.

To compare the results with single-trait models (e.g. snpnet), we focused on 1772 traits where we have the snpnet PRS models (and scores). The list of traits used in the analysis is listed in [`SRRR.GBE_ID.lst`](SRRR.GBE_ID.lst), which is generated from [`1_generate_trait_list.sh`](1_generate_trait_list.sh).

We fixed several issues and submitted SLURM jobs on 2020/12/23 and the results will be written to `/scratch/groups/mrivas/projects/PRS/private_output/20201020_SRRR`.

example job submission command:

```{bash}
ncores=16
last_iter=0
rank=50
sbatch --cores=${ncores} srrr_fit.nCoresArgs.sh ${rank} ${last_iter} ${ncores}
```

