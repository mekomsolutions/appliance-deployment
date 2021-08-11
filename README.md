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

Copy the output artifacts `autorun.zip.enc` and `secret.key.enc` at the root of any USB key.

This will be ready to be plugged on one of the appliance nodes

## 'deploy' profile

This is a generic profile that will download and package all binaries and configurations needed to run the application on the appliance.

It needs to be given the following variable to work:

| Variable name      | Default |      Description        |
|--------------------|---------|:-----------------------:|
| `DISTRO_NAME`      | None    | Eg, "bahmni-distro-c2c" |
| `DISTRO_VERSION`   | None    | Eg, "1.0.3"             |
| `DISTRO_REVISION`  | None    | Eg, "1.0.3"             |
| `K8S_DESCRIPTION_FILES_GIT_REF`  | `master`   | The Git revision of the K8s files to be used for deployment. Eg, "7a1e77398560b914ba4a02e19f2b066d55c1347f"             |


### Dependencies

- yq
- skopeo
- helm
- openssl
