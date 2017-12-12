FROM knowagelabs/knowage-server-docker:6.1.1

ENV TZ Australia/Melbourne

COPY ./entrypoint.sh ./

WORKDIR ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/bin

RUN apt-get update && apt-get upgrade -y && apt-get install -y tzdata && \
    useradd -d ${KNOWAGE_DIRECTORY} -s /bin/false knowage && \
    rm -rf ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/* && \
    echo '<% response.sendRedirect("/knowage"); %>' > ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/ROOT/index.jsp && \
    chown -R knowage:knowage ${KNOWAGE_DIRECTORY} && \
    chmod u+x *.sh && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["./entrypoint.sh"]
CMD ["su", "-s", "/bin/bash", "-m", "-c", "./startup.sh", "knowage"]
