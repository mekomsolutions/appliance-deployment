#!/bin/bash

DISTRO_NAME=c2c
DISTRO_VERSION=1.0.0-SNAPSHOT
DISTRO_REVISION=1.0.0-20210407.143106-41
IMAGES_FILE=images.txt
DISTRO_VALUES_FILE=custom-values.yml
DEPLOYMENT_VALUES_FILE=deployment-values.yml

# Fetch distro
wget https://nexus.mekomsolutions.net/repository/maven-snapshots/net/mekomsolutions/bahmni-distro-$DISTRO_NAME/$DISTRO_VERSION/bahmni-distro-$DISTRO_NAME-$DISTRO_REVISION.zip -O ./autorun_profile/bahmni-distro-c2c.zip

unzip bahmni-distro-c2c.zip -d ./bahmni-distro-c2c

rm -rf ./k8s-description-files

# # Fetch K8s files
git clone https://github.com/mekomsolutions/k8s-description-files.git ./k8s-description-files

cat /dev/null > $IMAGES_FILE

apps=`cat ${DISTRO_VALUES_FILE} | yq '.apps' | jq 'keys'`

echo $apps

for app in ${apps//,/ }
do
    enabled=false
    if [[ $app == \"* ]] ;
    then
        enabled=`cat custom-values.yml | yq | jq ".apps[${app}].enabled"`
        if [ $enabled ]  ; then
            image=`cat k8s-description-files/src/bahmni-helm/values.yaml | yq | jq ".apps[${app}].image"`
            echo $image | sed 's/\"//g'>> $IMAGES_FILE
        fi
    fi
done

cat ./images.txt | ./download-images.sh ./autorun_profile/images

helm template `[ -f $DISTRO_VALUES_FILE ] && echo "-f $DISTRO_VALUES_FILE"` `[ -f $DEPLOYMENT_VALUES_FILE ] && echo "-f $DEPLOYMENT_VALUES_FILE"` $DISTRO_NAME ./k8s-description-files/src/bahmni-helm --output-dir ./autorun_profile/$DISTRO_NAME-distro
