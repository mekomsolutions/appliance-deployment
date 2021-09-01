#!/usr/bin/env bash
set -e

PWD=$(dirname "$0")
RESOURCES_DIR=$PWD/target/resources

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

echo "⚙️ Copy 'run.sh'"
cp -R $PWD/run.sh $RESOURCES_DIR/
