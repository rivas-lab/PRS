# PRS map page in the Global Biobank Engine

We deploy the Jinja template to the following directory in GBE: `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates`

Our data location is: `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRSmap`

## How to deploy the changes?

```{bash}
# as a regular user
cp prs_v2.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
cp snpnet_v2.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
# cp /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/gbe.py gbe.$(date +%Y%m%d-%H%M%S).py
# cp gbe.py /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/
```

```{bash}
sudo su
cd /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates
docker-compose restart gbbe
```
## Files
### Symlinks to the main branch

Those files points to the files under the GBE repo.

- `main_gbe.py`
- `main_prs_v2.html`
- `main_snpnet_v2.html`
