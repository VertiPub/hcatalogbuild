#!/bin/sh -ex

# you have to make this directory because git doesn't create it automatically
rm -rf ${WORKSPACE}/hcatalog/lib
mkdir ${WORKSPACE}/hcatalog/lib
ant -Dhcatalog.version=${ARTIFACT_VERSION} -Dforrest.home=$FORREST_HOME tar
