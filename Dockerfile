# patch from previous image ghcr.io/t7tran/secure-knowage-server:6.1.1-13
# as knowagelabs/knowage-server-docker:6.1.1 is no longer available
FROM ghcr.io/t7tran/secure-knowage-server:6.1.1-13 AS source

RUN cd /home/knowage/apache-tomcat-7.0.57/lib && \
    rm -rf ./*mysql-connector-java* && \
    curl -fsSLo ./mysql-connector-j-8.4.0.jar https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar

FROM eclipse-temurin:8u452-b09-jre-noble

ENV KNOWAGE_DIRECTORY=/home/knowage \
    MYSQL_SCRIPT_DIRECTORY=/home/knowage/mysql \
    APACHE_TOMCAT_VERSION=7.0.57 \
    APACHE_TOMCAT_PACKAGE=apache-tomcat-7.0.57

RUN apt update && apt install -y \
                                 tzdata \
                                 iproute2 \
                                 mysql-client \
                                 && \
    userdel ubuntu && \
    useradd -d ${KNOWAGE_DIRECTORY} -s /bin/false knowage && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --chown=knowage:knowage --from=source /home/knowage /home/knowage
COPY --chown=knowage:knowage /rootfs /

USER knowage

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["./startup.sh"]