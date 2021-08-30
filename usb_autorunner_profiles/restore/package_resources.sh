#!/usr/bin/env bash
set -e

MAVEN_REPO=https://nexus.mekomsolutions.net/repository/maven-releases
DISTRO_URL=$MAVEN_REPO/net/mekomsolutions/$DISTRO_NAME/$DISTRO_VERSION/$DISTRO_NAME-$DISTRO_REVISION.zip

PVC_MOUNTER_IMAGE=mdlh/alpine-rsync:3.11-3.1-1

BASE_DIR=$(dirname "$0")
DEPLOY_RESOURCES=$PWD/resources
UTILS_PATH=$DEPLOY_RESOURCES/utils
BUILD_DIR=$BASE_DIR/target/build
ARCHIVE_PATH=$BASE_DIR/archive
RESOURCES_DIR=$BASE_DIR/target/resources
IMAGES_FILE=$BUILD_DIR/images.txt
VALUES_FILE=$BUILD_DIR/k8s-description-files/src/bahmni-helm/values.yaml
DEPLOYMENT_VALUES_FILE=$BASE_DIR/deployment-values.yml
: {K8S_DESCRIPTION_FILES_GIT_REF:=master}

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

# Fetch distro
echo "⚙️ Download $DISTRO_NAME distro..."
wget $DISTRO_URL -O $BUILD_DIR/bahmni-distro-c2c.zip
mkdir -p $BUILD_DIR/distro
unzip $BUILD_DIR/bahmni-distro-c2c.zip -d $BUILD_DIR/distro

# Fetch K8s files
echo "⚙️ Clone K8s description files GitHub repo and checkout '$K8S_DESCRIPTION_FILES_GIT_REF'..."
rm -rf $BUILD_DIR/k8s-description-files
git clone https://github.com/mekomsolutions/k8s-description-files.git $BUILD_DIR/k8s-description-files
dir1=$BASE_DIR
dir2=$PWD
cd $BUILD_DIR/k8s-description-files && git checkout $K8S_DESCRIPTION_FILES_GIT_REF && cd $dir2

cat $DEPLOYMENT_VALUES_FILE
echo "⚙️ Run Helm to substitute custom values..."
helm template `[ -f $DEPLOYMENT_VALUES_FILE ] && echo "-f $DEPLOYMENT_VALUES_FILE"` $DISTRO_NAME $BUILD_DIR/k8s-description-files/src/bahmni-helm --output-dir $BUILD_DIR/k8s

# Get container images
cat /dev/null > $IMAGES_FILE
echo "⚙️ Add the $PVC_MOUNTER_IMAGE image"
echo "docker.io/$PVC_MOUNTER_IMAGE" >> $IMAGES_FILE

echo "⚙️ Parse the list of container images..."
grep -ri "image:" $BUILD_DIR/k8s/bahmni-helm/templates/apps/mysql $BUILD_DIR/k8s/bahmni-helm/templates/apps/postgresql | awk -F': ' '{print $3}' | xargs | tr " " "\n" >> $IMAGES_FILE
cat $VALUES_FILE | yq '.apps.backup_services.apps.mysql.image' -r >> $IMAGES_FILE
cat $VALUES_FILE | yq '.apps.backup_services.apps.postgres.image' -r >> $IMAGES_FILE
cat $VALUES_FILE | yq '.apps.backup_services.apps.filestore.image' -r >> $IMAGES_FILE

echo "⚙️ Read registry address from '$DEPLOYMENT_VALUES_FILE'"
registry_ip=$(grep -ri "docker_registry:" $DEPLOYMENT_VALUES_FILE | awk -F': ' '{print $2}' | tr -d " ")

temp_file=$(mktemp)
cp $IMAGES_FILE $temp_file
echo "⚙️ Override '$registry_ip' by 'docker.io'"
sed -e "s/${registry_ip}/docker.io/g" $IMAGES_FILE > $temp_file
echo "⚙️ Remove duplicates..."
sort $temp_file | uniq > $IMAGES_FILE
rm ${temp_file}
echo "ℹ️ Images to be downloaded:"
cat $IMAGES_FILE

echo "🚀 Download container images..."
set +e
mkdir -p $RESOURCES_DIR/images
cat $IMAGES_FILE | $DEPLOY_RESOURCES/download-images.sh $BUILD_DIR/images
set -e

# Copy resources
mkdir -p $RESOURCES_DIR/db_resources
echo "⚙️ Copy K8s description files..."
cp -r $BUILD_DIR/k8s/bahmni-helm/templates/common/* $BUILD_DIR/k8s/bahmni-helm/templates/configs/* $BUILD_DIR/k8s/bahmni-helm/templates/apps/mysql $BUILD_DIR/k8s/bahmni-helm/templates/apps/postgresql $BUILD_DIR/k8s/bahmni-helm/templates/apps/odoo/odoo-config.yml $BUILD_DIR/k8s/bahmni-helm/templates/apps/openmrs/openmrs-configs.yml $BUILD_DIR/k8s/bahmni-helm/templates/apps/openelis/openelis-config.yaml $RESOURCES_DIR/db_resources
echo "⚙️ Copy 'run.sh' and 'utils/'..."
cp -R $BASE_DIR/run.sh $UTILS_PATH $BUILD_DIR/images $RESOURCES_DIR/
echo "⚙️ Copy archive files..."
cp -R $ARCHIVE_PATH $RESOURCES_DIR
