FROM knowagelabs/knowage-server-docker:latest

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

COPY ./entrypoint.sh ./

RUN chmod +x *.sh
