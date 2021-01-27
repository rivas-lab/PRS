# PRS map page in the Global Biobank Engine

We deploy the Jinja template to the following directory in GBE: `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates`

Our data location is: `/opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/static/PRS_map`

```{bash}
# as a regular user
cp prs.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
cp snpnet.html /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates/
# cp gbe.py /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/
```

```{bash}
sudo su
cd /opt/biobankengine/GlobalBioBankEngineRepo/gbe_browser/templates
docker-compose restart gbbe
```
