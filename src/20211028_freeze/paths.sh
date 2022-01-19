
# local files

trait_list_f='traits.tsv'
biomarkers_mapping_f='traits.biomarkers.tsv'
eval_full_f='PRSmap.eval.tsv.gz'
eval_fullwDelta_f='PRSmap.eval.wDelta.tsv.gz'
traits_w_metrics_f='traits_w_metrics.tsv'

# helper functions
fPRS_helper='/oak/stanford/groups/mrivas/users/ytanigaw/repos/yk-tanigawa/fPRS/helpers/functions.R'
snpnet_helper='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/snpnet/helpers/snpnet_misc.R'
cud4_d='/oak/stanford/groups/mrivas/users/ytanigaw/repos/yk-tanigawa/cud4'

# project dir
# project_d='/oak/stanford/groups/mrivas/projects/PRS'
project_d='/scratch/groups/mrivas/projects/PRS'

# list of GBE traits and category
GBE_category_f='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/05_gbe/extras/20200812_GBE_category/GBE_category.20201024.tsv'

# icdinfo file
icdinfo_f='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/05_gbe/array-combined/icdinfo.white_british.txt'

# variant annotation
ukb24983_var_annot_f="/oak/stanford/groups/mrivas/ukbb24983/array-combined/annotation/annotation_20201012/ukb24983_cal_hla_cnv.annot_compact_20201023.tsv.gz"

# GWAS
ukb24983_cal_gwas_d="/oak/stanford/groups/mrivas/ukbb24983/array-combined/gwas/current"

# GWAS h2 file (heritability)
GWAS_h2_f='/oak/stanford/groups/mrivas/ukbb24983/array-combined/ldsc/h2.white_british.20211101.tsv'

# master PRS file from the 2020/09 freeze
PRS202009_f='/scratch/groups/mrivas/projects/PRS/private_output/202009_batch/ukb24983_GWAS_covar.20200828.PRSs.phe.gz'
# snpnet PRS coefficients (BETAs)
# __TRAIT__ needs to be replaced
PRS202009_BETA_f='/oak/stanford/groups/mrivas/projects/PRS/GBE_data/__TRAIT__.tsv'

# master PRS file from the 2021/10 freeze
PRS202110_f='/scratch/groups/mrivas/projects/PRS/20211028_freeze/ukb24983_PRSmap.20211029.phe.gz'
PRS202110_d='/scratch/groups/mrivas/projects/PRS/20211028_freeze'

# sqc file (covariates etc.)
sample_qc_f='/oak/stanford/groups/mrivas/ukbb24983/sqc/population_stratification_w24983_20211020/ukb24983_GWAS_covar.20211020.phe'

# master phenotype file
phe_f='/scratch/groups/mrivas/ukbb24983/phenotypedata/master_phe/master.20211020.phe.zst'

# MRP blacklist
mrp_blacklist_f='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/ukbb-tools/13_mrp/gbe_blacklist.tsv'

# biomarkers
biomarkers_f='/oak/stanford/groups/mrivas/users/ytanigaw/repos/rivas-lab/biomarkers/common/canonical_trait_names.txt'

# biomarkers snpnet PRS score
# __TRAIT__ needs to be replaced
biomarkers_snpnet_f='/oak/stanford/groups/mrivas/projects/biomarkers/snpnet/biomarkers/__TRAIT__/results/score/__TRAIT__.sscore.zst'

# biomarkers snpnet PRS coefficients (BETAs)
# __TRAIT__ needs to be replaced
biomarkers_BETA_f='/oak/stanford/groups/mrivas/projects/biomarkers/snpnet/figshare/snpnet.BETAs.__TRAIT__.tsv.gz'
