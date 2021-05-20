#!/usr/bin/env bash
set -e

PWD=$(dirname "$0")
RESOURCES_DIR=$PWD/target/resources
FILE=$PWD/dump.sql

rm -rf $RESOURCES_DIR
mkdir -p $RESOURCES_DIR

if [[ -f "$FILE" ]]; then
    echo "$FILE exists."
else
  echo "⚠️ $FILE is missing. Please drop the 'dump.sql' file in $PWD/ folder"
  echo "🚫 Abort."
  exit 1
fi

echo "⚙️ Copy SQL files"
cp $PWD/*.sql $RESOURCES_DIR/

echo "⚙️ Copy 'run.sh'"
cp -R $PWD/run.sh $RESOURCES_DIR/
