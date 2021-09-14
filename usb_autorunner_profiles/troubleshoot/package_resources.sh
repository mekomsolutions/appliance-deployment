#!/usr/bin/env bash

PWD=$(dirname "$0")
RESOURCES_DIR=$PWD/target/resources

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

echo "⚙️ Copy 'run.sh'"
cp -R $PWD/script/run.sh $RESOURCES_DIR/
