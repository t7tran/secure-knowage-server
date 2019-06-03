FROM coolersport/knowage-server-docker:6.4.0

ENV TZ=Australia/Melbourne \
    STORE_PASS=changme \
    KEY_PASS=changme

COPY ./entrypoint.sh ./

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

    # additional configuration to install fonts on stretch-slim
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    echo 'deb http://deb.debian.org/debian stretch main contrib non-free' > /etc/apt/sources.list && \
    echo 'deb http://deb.debian.org/debian stretch-updates main contrib non-free' >> /etc/apt/sources.list && \
    echo 'deb http://security.debian.org stretch/updates main contrib non-free' >> /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && apt-get install -y tzdata curl && \
    # install fonts for export
    apt install -y xfonts-base ttf-mscorefonts-installer fontconfig && fc-cache -f && \
    useradd -d ${KNOWAGE_DIRECTORY} -s /bin/false knowage && \
    # install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
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
    wget http://repo1.maven.org/maven2/org/encryptor4j/encryptor4j/0.1.2/encryptor4j-0.1.2.jar && \
    find ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps -name "knowage-utils-${KNOWAGE_REPO_VERSION}.jar" -exec bash -c 'cp encryptor4j-0.1.2.jar `dirname {}`' ';' && \
    # knowage patched jars
    wget https://github.com/coolersport/knowage-addon/releases/download/0.6/knowage-core-${KNOWAGE_REPO_VERSION}.jar && \
    wget https://github.com/coolersport/knowage-addon/releases/download/0.6/knowage-utils-${KNOWAGE_REPO_VERSION}.jar && \
    for jar in `ls *.jar`; do \
        find ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps -name $jar -exec cp $jar {} ';'; \
    done && \
    # fixed mismatched poi jar in birtengine
    rm ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowagebirtreportengine/WEB-INF/lib/poi-ooxml-3.7.jar && \
    wget https://repo1.maven.org/maven2/org/apache/poi/poi-ooxml/3.9/poi-ooxml-3.9.jar \
        -O ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowagebirtreportengine/WEB-INF/lib/poi-ooxml-3.9.jar && \
    chown -R knowage:knowage ${KNOWAGE_DIRECTORY} && \
    chown -R knowage:knowage ${MYSQL_SCRIPT_DIRECTORY}/*.sql && \
    chmod u+x ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin/*.sh && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENTRYPOINT ["./entrypoint.sh"]
CMD ["gosu", "knowage", "./startup.sh"]
