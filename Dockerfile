FROM knowagelabs/knowage-server-docker:6.1.1

ENV TZ Australia/Melbourne

COPY ./entrypoint.sh ./

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

RUN apt-get update && apt-get upgrade -y && apt-get install -y tzdata && \
    useradd -d ${KNOWAGE_DIRECTORY} -s /bin/false knowage && \
    # install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    # complete gosu
    rm -rf ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/* && \
    echo '<% response.sendRedirect("/knowage"); %>' > ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/index.jsp && \
    chown -R knowage:knowage ${KNOWAGE_DIRECTORY} && \
    chmod u+x *.sh && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["./entrypoint.sh"]
CMD ["gosu", "knowage", "./startup.sh"]
