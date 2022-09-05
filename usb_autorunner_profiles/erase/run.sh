#!/usr/bin/env bash

kubectl_bin="/usr/local/bin/k3s kubectl"
DISK_MOUNT_POINT="/mnt/disks/ssd1/"
APP_NAMESPACE="default"

# Delete K8s resources in default namespace
echo "⚙️ Delete K8s deployments..."
$kubectl_bin delete deployments --all -n $APP_NAMESPACE
echo "⚙️ Delete K8s jobs..."
$kubectl_bin delete jobs --all -n $APP_NAMESPACE
echo "⚙️ Delete K8s pods..."
$kubectl_bin delete pods --all -n $APP_NAMESPACE
echo "⚙️ Delete K8s PVCs"
$kubectl_bin delete pvc --all -n $APP_NAMESPACE
# Wipe storage folder
echo "⚙️ Delete the content of the storage device"
rm -rf $DISK_MOUNT_POINT/data
rm -rf $DISK_MOUNT_POINT/logging
rm -rf $DISK_MOUNT_POINT/backup

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
