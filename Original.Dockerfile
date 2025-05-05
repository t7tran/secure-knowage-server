FROM knowagelabs/knowage-server-docker:6.1.1

ENV TZ=Australia/Melbourne \
    STORE_PASS=changme \
    KEY_PASS=changme

COPY --chown=knowage:knowage ./rootfs /

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

RUN sed -i 's/deb.debian/archive.debian/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org\/debian-security/' /etc/apt/sources.list && \
    sed -i '/jessie-updates/ d' /etc/apt/sources.list && \
    sed -i 's/deb.debian/archive.debian/' /etc/apt/sources.list.d/jessie-backports.list && \
    sed -i 's/deb /deb [check-valid-until=no] /g' /etc/apt/sources.list && \
    sed -i 's/deb /deb [check-valid-until=no] /g' /etc/apt/sources.list.d/jessie-backports.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && apt-get upgrade -y --force-yes && apt-get install -y --force-yes tzdata && \
    useradd -d ${KNOWAGE_DIRECTORY} -s /bin/false knowage && \
    # install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.14/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    # complete gosu
    rm -rf ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/* && \
    echo '<% response.sendRedirect("/knowage"); %>' > ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/index.jsp && \
    for d in docs examples host-manager manager; do \
        rm -rf ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/$d; \
    done && \
    cd /tmp && \
    # adding dependencies for add-on code in patched jars
    wget https://repo1.maven.org/maven2/org/encryptor4j/encryptor4j/0.1.2/encryptor4j-0.1.2.jar && \
    find ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps -name 'knowage-utils-6.1.1.jar' -exec bash -c 'cp encryptor4j-0.1.2.jar `dirname {}`' ';' && \
    # knowage patched jars
    wget https://github.com/t7tran/knowage-addon/releases/download/0.5/knowage-core-6.1.1.jar && \
    wget https://github.com/t7tran/knowage-addon/releases/download/0.5/knowage-utils-6.1.1.jar && \
    for jar in `ls *.jar`; do \
        find ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps -name $jar -exec cp $jar {} ';'; \
    done && \
    # fixed mismatched poi jar in birtengine
    rm ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowagebirtreportengine/WEB-INF/lib/poi-3.7.jar && \
    wget https://repo1.maven.org/maven2/org/apache/poi/poi/3.9/poi-3.9.jar \
        -O ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowagebirtreportengine/WEB-INF/lib/poi-3.9.jar && \
    chown -R knowage:knowage ${KNOWAGE_DIRECTORY} && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

USER knowage

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./startup.sh"]
