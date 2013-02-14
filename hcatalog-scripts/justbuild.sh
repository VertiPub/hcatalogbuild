#!/bin/sh -ex

# you have to make this directory because git doesn't create it automatically
pushd ${WORKSPACE}/hcatalog
git reset --hard
popd
rm -rf $WORKSPACE/hcatalog/lib
mkdir $WORKSPACE/hcatalog/lib
mvn versions:set -DnewVersion=${ARTIFACT_VERSION}
ant clean package -Dhcatalog.version=${ARTIFACT_VERSION} -Dmvn.hadoop.profile=hadoop23
