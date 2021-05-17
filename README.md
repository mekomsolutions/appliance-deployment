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

### Dependencies

- yq
- skopeo
- helm
- openssl
