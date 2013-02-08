#!/bin/sh

mkdir -p --mode=0755 ${INSTALL_DIR}/opt
cd ${INSTALL_DIR}/opt
tar -xvzpf ${WORKSPACE}/hcatalog/build/hcatalog-${ARTIFACT_VERSION}.tar.gz

export RPM_NAME=vcc-hcatalog-${ARTIFACT_VERSION}
export RPM_VERSION=0.1.0

cd ${RPM_DIR}

fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${RPM_VERSION} \
--description "${DESCRIPTION}" \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
-C ${INSTALL_DIR} \
opt
