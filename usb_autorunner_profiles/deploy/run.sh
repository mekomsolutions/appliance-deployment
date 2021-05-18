#!/usr/bin/env bash

PWD=$(dirname "$0")
DISTRO_NAME=c2c
REGISTRY_IP=${REGISTRY_IP:-10.0.90.99}
SSD_MOUNT_POINT=/mnt/disks/ssd1/
kubectl_bin="/usr/local/bin/k3s kubectl"
: "${NAMESPACE:=default}"

echo "⚙️  Upload container images to the registry at $REGISTRY_IP..."
# Ensure registry directory exists
mkdir -p $SSD_MOUNT_POINT/registry
POD_NAME=$($kubectl_bin get pod -l app=registry -o jsonpath="{.items[0].metadata.name}" -n $NAMESPACE)
$kubectl_bin wait --for=condition=ready --timeout=120s pod $POD_NAME -n $NAMESPACE

# sync images to registry
skopeo sync --scoped --dest-tls-verify=false --src dir --dest docker $PWD/images/docker.io $REGISTRY_IP

echo "⚙️  Apply K8s description files: config/ ..."
# Apply config
$kubectl_bin apply -f $PWD/k8s/bahmni-helm/templates/configs

echo "⚙️  Upload the distro..."
# Sending distro to volume
$PWD/utils/upload-files.sh $REGISTRY_IP/mdlh/alpine-rsync:3.11-3.1-1 $PWD/distro/ distro-pvc

# Create data volumes
mkdir -p $SSD_MOUNT_POINT/data/postgresql
mkdir -p $SSD_MOUNT_POINT/data/mysql
# Create backup folder
mkdir -p $SSD_MOUNT_POINT/backup

# Apply K8s description files
echo "⚙️  Apply K8s description files: common/ ..."
$kubectl_bin apply -f $PWD/k8s/bahmni-helm/templates/common
echo "⚙️  Apply K8s description files: configs/ ..."
$kubectl_bin apply -f $PWD/k8s/bahmni-helm/templates/configs
echo "⚙️  Apply K8s description files: apps/ ..."
$kubectl_bin apply -f $PWD/k8s/bahmni-helm/templates/apps/ -R

echo "✅  Done."
