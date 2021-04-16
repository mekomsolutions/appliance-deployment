#!/usr/bin/env bash

DISTRO_NAME=c2c
REGISTRY_IP=${REGISTRY_IP:-10.0.0.21}

# Ensure registry directory exists
mkdir -p /mnt/disks/ssd1/registry

# sync images to registry  
skopeo sync --dest-tls-verify=false --src dir --dest docker ./images/ $REGISTRY_IP

# Apply config
k3s kubectl apply -f ./configs

# Ensure distro directory exists
mkdir -p $ssd_mount_point/distro

# Sending distro to volume 
./upload-files.sh mdlh/alpine-rsync  ./distro/ c2c-distro-pvc

# Apply K8s description files
k3s kubectl apply -f ./$DISTRO_NAME-distro/common
k3s kubectl apply -f ./$DISTRO_NAME-distro/resources
k3s kubectl apply -f ./$DISTRO_NAME-distro/apps/ -R

sleep 100
export POD_NAME=$(kubectl get pods -l name=c2c-update-container -o=jsonpath='{.items..metadata.name}')
./krsync -av --progress --stats distro/  $POD_NAME:/distro/