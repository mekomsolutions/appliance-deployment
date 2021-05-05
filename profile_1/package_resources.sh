#!/usr/bin/env bash
set -e

PWD=$(dirname "$0")
DISTRO_NAME=c2c
DISTRO_VERSION=1.0.0-SNAPSHOT
DISTRO_REVISION=1.0.0-20210427.115038-60
BUILD_DIR=$PWD/target/build
RESOURCES_DIR=$PWD/target/resources
IMAGES_FILE=./$BUILD_DIR/images.txt
VALUES_FILE=$BUILD_DIR/k8s-description-files/src/bahmni-helm/values.yaml
DISTRO_VALUES_FILE=$PWD/custom-values.yml
DEPLOYMENT_VALUES_FILE=$PWD/deployment-values.yml

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

# Fetch distro
echo "⚙️ Download $DISTRO_NAME distro..."
wget https://nexus.mekomsolutions.net/repository/maven-snapshots/net/mekomsolutions/bahmni-distro-$DISTRO_NAME/$DISTRO_VERSION/bahmni-distro-$DISTRO_NAME-$DISTRO_REVISION.zip -O $BUILD_DIR/bahmni-distro-c2c.zip
mkdir -p $RESOURCES_DIR/distro
unzip $BUILD_DIR/bahmni-distro-c2c.zip -d $RESOURCES_DIR/distro

# Fetch K8s files
echo "⚙️ Fetch K8s description files..."
rm -rf ./$BUILD_DIR/k8s-description-files
git clone https://github.com/mekomsolutions/k8s-description-files.git $BUILD_DIR/k8s-description-files

echo "⚙️ Run Helm to substitute custom values..."
helm template `[ -f $DISTRO_VALUES_FILE ] && echo "-f $DISTRO_VALUES_FILE"` `[ -f $DEPLOYMENT_VALUES_FILE ] && echo "-f $DEPLOYMENT_VALUES_FILE"` $DISTRO_NAME ./$BUILD_DIR/k8s-description-files/src/bahmni-helm --output-dir $RESOURCES_DIR/k8s

echo "⚙️ Read container images from '$DISTRO_VALUES_FILE' and '$VALUES_FILE'..."
cat /dev/null > $IMAGES_FILE
apps=`yq e -j '.apps' $DISTRO_VALUES_FILE | jq 'keys'`
for app in ${apps//,/ }
do
    enabled=false
    if [[ $app == \"* ]] ;
    then
        enabled=`yq e -j $DISTRO_VALUES_FILE | jq ".apps[${app}].enabled"`
        if [ $enabled ]  ; then
            image=`yq e -j $VALUES_FILE | jq ".apps[${app}].image"`
            if [[ $image != *":"* ]] ; then
              image="${image}:latest"
            fi
            echo "Image: " $image
            echo $image | sed 's/\"//g'>> $IMAGES_FILE
            # Scan for initImage too
            initImage=`yq e -j $VALUES_FILE | jq ".apps[${app}].initImage"`
            if [ $initImage != "null" ]  ; then
                if [[ $initImage != *":"* ]] ; then
                    initImage="${initImage}:latest"
                fi
              echo "Init Image: " $initImage
              echo $initImage | sed 's/\"//g'>> $IMAGES_FILE
            fi
            # Scan for backup services images too
            backupImagesJSON=`yq e -j $VALUES_FILE | jq ".apps[${app}].apps"`
            if [ "$backupImagesJSON" != "null" ]  ; then
              backupApps=$(echo "$backupImagesJSON" | jq 'keys')
              for backupApp in ${backupApps//,/ }
              do
                if [[ $backupApp == \"* ]] ; then
                  backupImage=$(echo "$backupImagesJSON" | jq ".[${backupApp}].image")
                  echo "Backup Image: $backupImage"
                  if [[ $backupImage != *":"* ]] ; then
                      backupImage="${backupImage}:latest"
                  fi
                  echo "Backup Image: " $backupImage
                  echo $backupImage | sed 's/\"//g'>> $IMAGES_FILE
                fi
              done
            fi
            # Scan for logging images too
            loggingImage=`yq e -j $VALUES_FILE | jq ".apps[${app}].loggingImage"`
            if [ $loggingImage != "null" ]  ; then
                if [[ $loggingImage != *":"* ]] ; then
                    loggingImage="${loggingImage}:latest"
                fi
              echo "Logging Image: " $loggingImage
              echo $loggingImage | sed 's/\"//g'>> $IMAGES_FILE
            fi
        fi
    fi
done

echo "🚀 Download container images..."
set +e
cat $IMAGES_FILE | $PWD/download-images.sh $RESOURCES_DIR/images
set -e

echo "⚙️ Copy 'run.sh' and 'utils/'..."
cp -R $PWD/run.sh $PWD/utils $RESOURCES_DIR/
