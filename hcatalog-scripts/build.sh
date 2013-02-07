#!/bin/sh
# clean up any previous artifacts
rm -rf ${WORKSPACE}/hcatalog-*.tar.gz hcatalog_install-*

# set up env variables
export DATE_STRING=`date +"%Y%m%d%H%M"`
export RPM_VERSION=0.1.0
export HCATALOG_VERSION=0.4.0

# deal with the submodule

cd ${WORKSPACE}
git submodule init
git submodule update
cd ${WORKSPACE}/hcatalog
git checkout -b tobebuilt release-0.4.0

# build the tarball using ant

# you have to make this directory because git doesn't create it automatically
rm -rf lib
mkdir lib
ant -Dhcatalog.version=0.4.0 -Dforrest.home=$FORREST_HOME tar

# convert each tarball into an RPM
DEST_DIR=${WORKSPACE}/hcatalog_install-${BUILD_NUMBER}/opt/
mkdir --mode=0755 -p ${DEST_DIR}
cd ${DEST_DIR}
tar -xvzpf ${WORKSPACE}/hcatalog/build/hcatalog-${HCATALOG_VERSION}.tar.gz

export RPM_NAME=`echo vcc-hcatalog-${HCATALOG_VERSION}`
fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${RPM_VERSION} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${WORKSPACE}/hcatalog_install-${BUILD_NUMBER} \
opt

