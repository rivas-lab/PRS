# GBE app

The PRS page in GBE is implemented with Flask template. We keep two versions of the browser (v1 and v2).

## version 2


```{bash}
# on GBE VM
cd /home/ytanigaw/repos/rivas-lab/PRS/notebook/20210115_GBE_data_prep/GBE_page_src

bash v2_copy_plot_files.sh # force
# please add force option to override the files

# cp gbe.py /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/
cp prs_v2.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
cp snpnet_v2.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
```

## version 1

- We have the data in `$OAK` (`/oak/stanford/groups/mrivas/projects/PRS/GBE_data/`).
- Please copy it to `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRSmap/PRSmap_v1/traits.tsv`
- so that it's accessible as `/biobankengine/app/static/PRSmap/PRSmap_v1/traits.tsv` from the GBE VM.

To update the app, please copy the current version of `gbe.py` in the GBE repo, make an edit, and copy to the repo.

```{bash}
# on GBE VM
cd /home/ytanigaw/repos/rivas-lab/PRS/notebook/20210115_GBE_data_prep/GBE_page_src
# cp gbe.py /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/
cp prs.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
cp snpnet.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
```

Once you made an update, you'll start the GBE docker

```{bash}
root@biobankengine:/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser# docker-compose restart gbbe
Restarting biobankengine_gbbe_1 ... done
```

### the summary table

- [`3_summary_table.ipynb`](../3_summary_table.ipynb): the list of 1617 traits.

scp /oak/stanford/groups/mrivas/projects/PRS/GBE_data/traits.tsv gbe:/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRSmap/PRSmap_v1/traits.tsv