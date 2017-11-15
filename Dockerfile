FROM knowagelabs/knowage-server-docker:6.1.1

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

COPY ./entrypoint.sh ./

RUN chmod +x *.sh
