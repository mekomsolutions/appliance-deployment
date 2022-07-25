#!/usr/bin/env bash

# Fail on first error:
set -e

DISTRO_VERSION=${DISTRO_VERSION}
ARTIFACT_GROUP=${ARTIFACT_GROUP:-net.mekomsolutions}

PVC_MOUNTER_IMAGE=mdlh/alpine-rsync:3.11-3.1-1

BASE_DIR=$(dirname "$0")
BUILD_DIR=$BASE_DIR/target/build
RESOURCES_DIR=$BASE_DIR/target/resources
PACKAGING_UTILS_DIR=$PWD/resources/packaging_utils
IMAGES_FILE=$BUILD_DIR/images.txt

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

echo "⚙️ Run Helm to substitute custom values..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm pull prometheus-community/prometheus --version 15.10.3 --untar --untardir $BUILD_DIR
helm template -f $BASE_DIR/monitoring-values.yml prometheus $BUILD_DIR/prometheus --output-dir $RESOURCES_DIR/k8s --namespace monitoring

# Get container images
cat /dev/null > $IMAGES_FILE
echo "⚙️ Add the $PVC_MOUNTER_IMAGE image"
echo "docker.io/$PVC_MOUNTER_IMAGE" >> $IMAGES_FILE

echo "⚙️ Parse the list of container images..."
grep -ri "image:" $RESOURCES_DIR/k8s  | awk -F': ' '{print $3}' | xargs | tr " " "\n" >> $IMAGES_FILE

temp_file=$(mktemp)
cp $IMAGES_FILE $temp_file
echo "⚙️ Remove duplicates..."
sort $temp_file | uniq > $IMAGES_FILE
rm ${temp_file}
echo "ℹ️ Images to be downloaded:"
cat $IMAGES_FILE

echo "🚀 Download container images..."
set +e
mkdir -p $BUILD_DIR/images
cat $IMAGES_FILE | $PACKAGING_UTILS_DIR/download-images.sh $BUILD_DIR/images
set -e

# Copy resources
echo "⚙️ Copy 'run.sh' and 'utils/'..."
cp -R $BASE_DIR/run.sh $BASE_DIR/monitoring-pvc.yml $BASE_DIR/utils $BUILD_DIR/images $RESOURCES_DIR/
