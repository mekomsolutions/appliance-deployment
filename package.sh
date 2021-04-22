#!/usr/bin/env bash

PROFILE_NAME=${1:-profile_1}
DISTRO_NAME=c2c
DISTRO_VERSION=1.0.0-SNAPSHOT
DISTRO_REVISION=1.0.0-20210416.142111-53
BUILD_PATH=target/build
IMAGES_FILE=./$BUILD_PATH/images.txt
DISTRO_VALUES_FILE=custom-values.yml
DEPLOYMENT_VALUES_FILE=deployment-values.yml

# Fetch distro
mkdir -p $BUILD_PATH
echo "Downloading $DISTRO_NAME distro..."
wget https://nexus.mekomsolutions.net/repository/maven-snapshots/net/mekomsolutions/bahmni-distro-$DISTRO_NAME/$DISTRO_VERSION/bahmni-distro-$DISTRO_NAME-$DISTRO_REVISION.zip -O $BUILD_PATH/bahmni-distro-c2c.zip
unzip $BUILD_PATH/bahmni-distro-c2c.zip -d ./$BUILD_PATH/distro
# Fetch K8s files
echo "Fetching K8s description files"
rm -rf ./$BUILD_PATH/k8s-description-files
git clone https://github.com/mekomsolutions/k8s-description-files.git $BUILD_PATH/k8s-description-files

helm template `[ -f $DISTRO_VALUES_FILE ] && echo "-f $DISTRO_VALUES_FILE"` `[ -f $DEPLOYMENT_VALUES_FILE ] && echo "-f $DEPLOYMENT_VALUES_FILE"` $DISTRO_NAME ./$BUILD_PATH/k8s-description-files/src/bahmni-helm --output-dir ./$BUILD_PATH/k8s

cat /dev/null > $IMAGES_FILE
apps=`yq e -j '.apps' $DISTRO_VALUES_FILE | jq 'keys'`
echo $apps

for app in ${apps//,/ }
do
    enabled=false
    if [[ $app == \"* ]] ;
    then
        enabled=`yq e -j $DISTRO_VALUES_FILE | jq ".apps[${app}].enabled"`
        if [ $enabled ]  ; then
            image=`yq e -j $BUILD_PATH/k8s-description-files/src/bahmni-helm/values.yaml | jq ".apps[${app}].image"`
            if [[ $image != *":"* ]] ; then 
            image="${image}:latest"
            fi
            echo "Image: " $image
            echo $image | sed 's/\"//g'>> $IMAGES_FILE
            initImage=`yq e -j $BUILD_PATH/k8s-description-files/src/bahmni-helm/values.yaml | jq ".apps[${app}].initImage"`
            # Scan for initImage too
            if [ $initImage != "null" ]  ; then
                echo "here"
                if [[ $initImage != *":"* ]] ; then
                    $initImage = "${initImage}:latest"
                fi
              echo "Init Image: " $initImage
              echo $initImage | sed 's/\"//g'>> $IMAGES_FILE
            fi
        fi
    fi
done
echo "Downloading images"
cat $IMAGES_FILE | ./download-images.sh ./$BUILD_PATH/images

# Start packaging the 'usb_autorunner' profile
echo "Generating 'autorun.zip' file"
mkdir -p $BUILD_PATH/tmp && rm -rf $BUILD_PATH/tmp/* 
project_dir=`pwd`
cp -R $BUILD_PATH/k8s $BUILD_PATH/images $BUILD_PATH/distro $PROFILE_NAME/* $BUILD_PATH/tmp/
cd $BUILD_PATH/tmp && zip $project_dir/$BUILD_PATH/autorun.zip -r ./* && cd $project_dir

echo "Generating random secret key"
openssl rand -base64 32 > $BUILD_PATH/secret.key

echo "Encrypting random secret key"
openssl rsautl -encrypt -oaep -pubin -inkey certificates/public.pem -in $BUILD_PATH/secret.key -out target/secret.key.enc

echo "Encrypting 'autorun.zip' file"
openssl aes-256-cbc -pbkdf2 -in $BUILD_PATH/autorun.zip -out target/autorun.zip.enc -pass file:$BUILD_PATH/secret.key
echo "Packagaging 'usb autorunner' files is done successfully."
