#!/bin/sh
ALTISCALE_RELEASE=${ALTISCALE_RELEASE:-0.1.0}

mkdir -p --mode=0755 ${INSTALL_DIR}/opt
cd ${INSTALL_DIR}/opt
tar -xvzpf ${WORKSPACE}/hcatalog/build/hcatalog-${ARTIFACT_VERSION}.tar.gz

#replace the contents of hcat_server_install.sh

cd ${INSTALL_DIR}/opt/hcatalog-${ARTIFACT_VERSION}/share/hcatalog
ln -s ../../etc/hcatalog conf

export RPM_NAME=vcc-hcatalog-${ARTIFACT_VERSION}

cd ${RPM_DIR}

fpm --verbose \
--maintainer ops@verticloud.com \
--vendor VertiCloud \
--provides ${RPM_NAME} \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${ALTISCALE_RELEASE} \
--description "${DESCRIPTION}" \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--url https://github.com/VertiPub/hcatalogbuild \
--config-files opt/hcatalog-${ARTIFACT_VERSION}/sbin/hcat_server.sh \
-C ${INSTALL_DIR} \
opt
