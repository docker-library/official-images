#!/bin/bash

# Jenkins build steps
cd bashbrew/

# Build all node images
./bashbrew.sh build $LIBRARY --library=../library --namespaces=resin

# Push all images
./bashbrew.sh push $LIBRARY --library=../library --namespaces=resin
