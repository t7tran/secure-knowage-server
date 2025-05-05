# patch from previous image ghcr.io/t7tran/secure-knowage-server:6.1.1-13
# as knowagelabs/knowage-server-docker:6.1.1 is no longer available
FROM ghcr.io/t7tran/secure-knowage-server:6.1.1-13

RUN cd /home/knowage/apache-tomcat-7.0.57/lib && \
    rm -rf ./*mysql-connector-java* && \
    curl -fsSLo ./mysql-connector-j-8.4.0.jar https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar
