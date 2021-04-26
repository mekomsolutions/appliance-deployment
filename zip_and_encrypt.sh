#!/usr/bin/env bash -e

PROFILE_NAME=$1
PROFILE_RESOURCES_DIR=$PROFILE_NAME/target/resources
PROJECT_DIR=$(pwd)
TARGET_DIR=$PROJECT_DIR/target
BUILD_DIR=$TARGET_DIR/build

rm -rf $TARGET_DIR
mkdir -p $BUILD_DIR

echo "⚙️ Run 'package_resources.sh'..."
bash $PROFILE_NAME/package_resources.sh

echo "⚙️ Compress resources into 'autorun.zip' file..."
cd $PROFILE_RESOURCES_DIR/ && zip $BUILD_DIR/autorun.zip -r ./* && cd $PWD

echo "⚙️ Generate a random secret key..."
openssl rand -base64 32 > $BUILD_DIR/secret.key

echo "⚙️ Encrypt the random secret key..."
openssl rsautl -encrypt -oaep -pubin -inkey $PROJECT_DIR/certificates/public.pem -in $BUILD_DIR/secret.key -out $TARGET_DIR/secret.key.enc

echo "🔐 Encrypt 'autorun.zip' file..."
openssl enc -aes-256-cbc -md sha256 -in $BUILD_DIR/autorun.zip -out $TARGET_DIR/autorun.zip.enc -pass file:$BUILD_DIR/secret.key

echo "✅ USB Autorunner packagaging is done successfully."
echo "ℹ️ Files can be found in '$BUILD_DIR/'"
ls $TARGET_DIR/*enc
