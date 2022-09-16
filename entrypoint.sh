#!/bin/bash
set -e

if [[ -z "$PUBLIC_ADDRESS" ]]; then
	#get the address of container
	#example : default via 172.17.42.1 dev eth0 172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.109
	PUBLIC_ADDRESS=`ip route | grep src | awk '{print $9}'`
fi

#replace the address of container inside server.xml
sed -i "s|http:\/\/.*:8080|http:\/\/${PUBLIC_ADDRESS}:8080|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
sed -i "s|http:\/\/.*:8080\/knowage|http:\/\/localhost:8080\/knowage|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
sed -i "s|http:\/\/localhost:8080|http:\/\/${PUBLIC_ADDRESS}:8080|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowage/WEB-INF/web.xml

### CUSTOM BEGIN ###

sed -i "s/it.eng.spagobi.services.common.FakeSsoService/${SSO_CLASS:-com.genix.protrack.saas.knowage.utils.addon.EncryptedUserIdSsoService}/g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
sed -i "s/it.eng.spagobi.commons.services.LoginModule/${LOGIN_MODULE_CLASS:-com.genix.protrack.saas.knowage.core.LoginModuleEx}/g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowage/WEB-INF/conf/webapp/modules.xml
sed -i "s/it.eng.spagobi.commons.services.LogoutAction/${LOGOUT_ACTION_CLASS:-com.genix.protrack.saas.knowage.core.LogoutActionEx}/g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps/knowage/WEB-INF/conf/webapp/actions.xml

if [[ -n "$GLOBAL_NAMING_RESOURCES" ]]; then
	replacement=$(printf '%s\n' "$GLOBAL_NAMING_RESOURCES" | sed 's/[\&"]/\\&/g' | tr '\n' ' ')
	sed -i "s|</GlobalNamingResources>|${replacement}</GlobalNamingResources>|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
fi

if [[ -n "$RESOURCE_LINKS" ]]; then
	replacement=$(printf '%s\n' "$RESOURCE_LINKS" | sed 's/[\&"]/\\&/g' | tr '\n' ' ')
	for ctx in `find ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/webapps -name 'context.xml'`; do
		sed -i "s|</Context>|${replacement}</Context>|g" $ctx
	done
fi

USESSL=
MYSQLCA=

if [[ -n "$SECURE_MYSQL" ]]; then
	USESSL='?useSSL=true\&amp;requireSSL=true'
	MYSQLCA="--ssl-ca=$CA_CERTIFICATE"
fi

if [[ -f "/keystore.jks" ]]; then
	sed -i 's|<!-- <Connector port="8443"|<Connector port="8443"|g' ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
	sed -i "s|sslProtocol=\"TLS\" /> -->|sslProtocol=\"TLS\" keystoreFile=\"/keystore.jks\" keystorePass=\"$STORE_PASS\"/>|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
fi

if [[ -z "$NO_LB" ]]; then
	# allow to run behind a load balancer with SSL termination
	sed -i "s|port=\"8080\" protocol=\"HTTP/1.1\" redirectPort=\"8443\"|port=\"8080\" protocol=\"HTTP/1.1\" redirectPort=\"8443\" proxyPort=\"443\" scheme=\"https\" secure=\"true\" URIEncoding=\"UTF-8\"|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
	if [[ -n "PUBLIC_LB_ADDRESS" ]]; then
		sed -i "s|http:\/\/${PUBLIC_ADDRESS}:8080|${PUBLIC_LB_ADDRESS}|g" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml
	fi
fi

#wait for mysql if it's a compose image
if [ -n "$WAIT_MYSQL" ]; then
	sleep 5
	while ! curl -fs http://$DB_PORT_3306_TCP_ADDR:$DB_PORT_3306_TCP_PORT/
	do
		echo "$(date) - still trying to connect to mysql"
		sleep 1
	done
fi

### CUSTOM END ###

# Get the database values from the relation.
DB_USER=$DB_ENV_MYSQL_USER
DB_DB=$DB_ENV_MYSQL_DATABASE
DB_PASS=$DB_ENV_MYSQL_PASSWORD
DB_HOST=$DB_PORT_3306_TCP_ADDR
DB_PORT=$DB_PORT_3306_TCP_PORT

#insert knowage metadata into db if it doesn't exist
result=`mysql $MYSQLCA -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_DB} -e "SHOW TABLES LIKE '%SBI_%';"`
if [ -z "$result" ]; then
	mysql $MYSQLCA -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_DB} --execute="source ${MYSQL_SCRIPT_DIRECTORY}/MySQL_create.sql"
	mysql $MYSQLCA -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_DB} --execute="source ${MYSQL_SCRIPT_DIRECTORY}/MySQL_create_quartz_schema.sql"
fi

#replace in server.xml
old_connection='url="jdbc:mysql://localhost:3306/knowagedb" username="knowageuser" password="knowagepassword"'
new_connection='url="jdbc:mysql://'${DB_HOST}':'${DB_PORT}'/'${DB_DB}${USESSL}'" username="'${DB_USER}'" password="'${DB_PASS}'"'
sed -i "s|${old_connection}|${new_connection}|" ${KNOWAGE_DIRECTORY}/${APACHE_TOMCAT_PACKAGE}/conf/server.xml

exec "$@"
