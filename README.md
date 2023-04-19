## Appliance Deployment

Repository of [USB Autorunner](https://github.com/mekomsolutions/appliance-os/tree/master/roles/usb_autorunner) profiles that can be deployed on the cluster appliance

## Quick start

Run
```
./zip_and_encrypt <profile_name>
```

List of profiles:
- backup
- deploy
- restore
- sysinfo
- troubleshoot
- analytics
- monitoring

Output artifacts `autorun.zip.enc` and `secret.key.enc` will be zipped in a file named **<profile_name>-<git_commit_id>.zip**, ready to be sent and extracted onto a USB key.

The USB key can then be plugged on an appliance.

## 'restore' profile

This profile will prepare scripts to restore databases and filestores on an existing cluster.
The profile support restoring the following:
- Odoo database: `odoo.tar`
- OpenMRS database: `openmrs.sql`
- OpenELIS database: `clinlims.tar`
- filestore: `filestore.zip`
Files should be placed in the `archive/` folder.

It needs to be given the following variable to work:

| Variable name      | Default |      Description        |
|--------------------|---------|:-----------------------:|
| `DISTRO_NAME`      | None    | Eg, "bahmni-distro-c2c" |
| `DISTRO_VERSION`   | None    | Eg, "1.0.3"             |
| `DISTRO_GROUP`     | None    | Eg "c2c"                |
| `ARTIFACT_GROUP`   | `net.mekomsolutions`    | The distro Artifact group ID |
| `HELM_CHART_VERSION`  | None   | Eg, "1.0.0-dev" |

## 'deploy' profile

This is a generic profile that will download and package all binaries and configurations needed to run the application on the appliance.

It needs to be given the following variable to work:

| Variable name      | Default |      Description        |
|--------------------|---------|:-----------------------:|
| `DISTRO_NAME`      | None    | Eg, "bahmni-distro-c2c" |
| `DISTRO_VERSION`   | None    | Eg, "1.0.3"             |
| `DISTRO_GROUP`     | None    | Eg, "c2c"             |
| `DISTRO_REVISION`     | None    | Eg, "1.3.0", "1.1.0-20211119.110835-35"   |
| `ARTIFACT_GROUP`   | `net.mekomsolutions`    | The distro Artifact group ID |
| `HELM_CHART_VERSION`  | None   | Eg, "1.0.0-dev" |

### requirements:
- skopeo
- maven
- helm
## 'troubleshoot' profile

Profile used to package any script of your choice that should be run on an appliance.

This is especially usefully for single time troubleshooting operations on a production server. For instance to run a script that applies a database fix, restarts a given service, or any operation really.

No script is provided by default, therefore one must provide one and drop it in the script/ folder. You can have a look at other profiles **run.sh** scripts to get a starting point.

## 'backup' profile

Profile used to backup specific services on an appliance. Currently supported services are:
- OpenMRS
- OpenELIS
- Odoo
- Logging

### Backup output:
Running this profile will result in the following set of files extracted from the appliance:
- OpenMRS database (`backup/openmrs-<timestamp>.sql`)
- Odoo database (`backup/odoo-<timestamp>.tar`)
- OpenELIS database (`backup/clinlims<timestamp>.tar`)
- Filestore - a ZIP file that contain both OpenMRS and Odoo filestore (`backup/filestore/filestore-<timestamp>.zip`)
- Logging (`backup/filestore/filestore-<timestamp>.zip`)

## 'sysinfo' profile

Profile used to retrieve some system information to facilitate troubleshooting.

## 'analytics' profile
Profile used to setup Analytics & reporting on the appliances.
### **requirements**:
Required variables:
- REGISTRY_USER
- REGISTRY_PASSWORD

run: `./zip_and_encrypt.sh analytics` to get the package

***Notes***:

- Docker registry user should have access to `mekomsolutions` private repositories.

## 'parquet' profile
Profile used to setup Analytics & reporting on the appliances.

### **requirements**:
Required variables:
- REGISTRY_USER
- REGISTRY_PASSWORD
- LOCATION_TAG

run: `./zip_and_encrypt.sh parquet` to get the package

***Notes***:
- Github user should have access to `ozone-his` to be able to fetch `ozone-analytics-helm` 

- Docker registry user should have access to `mekomsolutions` private repositories.

- The profile will output a timestamped folder with exported data

## **Dependencies**

- yq (Attention: there are 2 `yq`. Use the Pip3 one: https://kislyuk.github.io/yq/)
- Skopeo
- Helm
- openssl
