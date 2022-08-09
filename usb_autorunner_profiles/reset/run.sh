#!/usr/bin/env bash

kubectl_bin="/usr/local/bin/k3s kubectl"
DISK_MOUNT_POINT="/mnt/disks/ssd1/"
APP_NAMESPACE="default"
# Get NFS IP address
registry_ip=`$kubectl get svc registry-service -o json -n appliance -o custom-columns=:.spec.loadBalancerIP --no-headers`
# Get USB mount point
usb_mount_point=`grep "mount_point" /opt/autorunner/usbinfo | cut -d'=' -f2 | tr -d '"'`
sysinfo_folder=${usb_mount_point}/sysinfo
mkdir -p ${sysinfo_folder}

# Delete K8s resources in default namespace
echo "⚙️ Delete K8s deployments..."
$kubectl_bin delete deployments --all -n $APP_NAMESPACE
echo "⚙️ Delete K8s jobs..."
$kubectl_bin delete jobs --all -n $APP_NAMESPACE
echo "⚙️ Delete K8s pods..."
$kubectl_bin delete pods --all -n $APP_NAMESPACE
# Wipe storage folder
echo "⚙️ Delete the content of the storage device"
rm -rf $DISK_MOUNT_POINT/* -v !($DISK_MOUNT_POINT/registry)

# Create initial storage folders
echo "⚙️ Create initial folders"
# Create data volumes
mkdir -p $DISK_MOUNT_POINT/data/postgresql
mkdir -p $DISK_MOUNT_POINT/data/mysql
# Create entrypoint-db volume
mkdir -p $DISK_MOUNT_POINT/data/entrypoint-db
# Create backup folder
mkdir -p $DISK_MOUNT_POINT/backup
# Create logging folder
mkdir -p $DISK_MOUNT_POINT/logging
# Create nfs folder
mkdir -p $DISK_MOUNT_POINT/nfs

echo "✅ Done."
