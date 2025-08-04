#!/bin/bash

forge init $FORGE_PROJECT_DIR
cd $FORGE_PROJECT_DIR

rm -rf src test script

cp /app/remappings.txt ./
cp -r /app/lib/* ./lib
cp -r /app/src ./src
cp -r /app/script ./script
forge build

cp -rf ./out /app/out/
