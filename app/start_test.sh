#!/usr/bin/env bash

echo " Hi, Enabling Heroku Error Debug Mode"

echo $APP_NAME

echo "======== $APP_NAME ====="
SERVER_HOST="$(APP_NAME).herokuapp.com
#SERVER_URL=https://$SERVER_HOST
SERVER_URL=http://$SERVER_HOST
#client_key=os.environ.get('KAFKA_CLIENT_CERT_KEY')
#client_cert=os.environ.get('KAFKA_CLIENT_CERT')
#trusted_cert=os.environ.get('KAFKA_TRUSTED_CERT')
#source /certs/setup-certs.sh
#/etc/kafka/setup-certs.sh
#./etc/kafka/kafka-generate-ssl-automatic.sh
#echo "======== Before PORT =====" 
#export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 
#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 
#echo "======== After PORT ====="
#[ -z $addon ] && {
 # echo "addon is missing" >&2
  #exit 1
#}
#client_key="$(echo $addon)_CLIENT_CERT_KEY"
#client_cert="$(echo $addon)_CLIENT_CERT"
#trusted_cert="$(echo $addon)_TRUSTED_CERT"
client_key=$KAFKA_CLIENT_CERT_KEY
client_cert=$KAFKA_CLIENT_CERT
trusted_cert=$KAFKA_TRUSTED_CERT

[ -z $TRUSTSTORE_PASSWORD ] && {
  echo "TRUSTSTORE_PASSWORD is missing" >&2
  exit 1
}
[ -z $KEYSTORE_PASSWORD ] && {
  echo "KEYSTORE_PASSWORD is missing" >&2
  exit 1
}
rm -f .{keystore,truststore}.{pem,pkcs12,jks}
rm -f .cacerts
#echo -n "${!client_key}" >> /etc/kafka-connect/client_key.pem
#echo -n "${!client_cert}" >>  /etc/kafka-connect/client_cert.pem
#echo -n "${!trusted_cert}" >  /etc/kafka-connect/truststore.pem
echo -n "$client_key" >>   /etc/kafka-connect/client_key.pem
echo -n "$client_cert" >>  /etc/kafka-connect/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka-connect/truststore.pem

if [ "$?" = "0" ]; then
  echo "No Error while creating .pem files"
else
  echo "Error while creating .pem files"
  exit 1
fi

echo "keystore - $ /etc/kafka-connect/client_key.pem"
echo "trusted - $ /etc/kafka-connecta/client_cert.pem"
echo "trusted - $ /etc/kafka-connecta/truststore.pem"

keytool -importcert -file  /etc/kafka-connect/truststore.pem -keystore  /etc/kafka-connect/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka-connect/client_cert.pem -inkey  /etc/kafka-connect/client_key.pem -out  /etc/kafka-connect/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD

keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka-connect/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka-connect/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD
    
echo "Client Cert Key: CK-$client_key"
echo "Client Cert: TP-$client_cert" 
echo "Trusted Cert: KP-$trusted_cert"

#kafka_addon_name=${KAFKA_ADDON:-KAFKA}
#prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
#kafka_prefix=$(echo ${!prefix_env_var})
#kafka_url_env_var="$(echo $kafka_addon_name)_URL"
#postgres_addon_name=${POSTGRES_ADDON:-DATABASE}
kafka_addon_name=$KAFKA_ADDON:-KAFKA
prefix_env_var="$(echo $kafka_addon_name)_PREFIX"
kafka_prefix=$(echo $prefix_env_var)
kafka_url_env_var="$(echo $kafka_addon_name)_URL"
postgres_addon_name=$POSTGRES_ADDON:-DATABASE
export CONNECT_PRODUCER_SECURITY_PROTOCOL=SSL
export CONNECT_PRODUCER_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_PRODUCER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_PRODUCER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_PRODUCER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=
export CONNECT_CONSUMER_SECURITY_PROTOCOL=SSL
export CONNECT_CONSUMER_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_CONSUMER_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_CONSUMER_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_CONSUMER_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=
export CONNECT_SECURITY_PROTOCOL=SSL
export CONNECT_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=
echo "Variables: $kafka_addon_name $prefix_env_var $kafka_prefix $kafka_url_env_var $postgres_addon_name "
echo "Secuirty protocal: H-$HOME TP-$TRUSTSTORE_PASSWORD KP-$KEYSTORE_PASSWORD"
echo "======== After postgres_addon_name ====="
#export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
export CONNECT_GROUP_ID=$(echo $kafka_addon_name)connect-cluster
#GROUP_ID=$(echo $kafka_prefix)connect-cluster
export CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_OFFSET_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-offsets
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=3
#OFFSET_STORAGE_TOPIC=$(echo $kafka_prefix)connect-offsets
export CONNECT_CONFIG_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-configs
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=3
#CONFIG_STORAGE_TOPIC=$(echo $kafka_prefix)connect-configs
export CONNECT_STATUS_STORAGE_TOPIC=$(echo $kafka_addon_name)connect-status
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=3
#STATUS_STORAGE_TOPIC=$(echo $kafka_prefix)connect-status
export CONNECT_OFFSET_FLUSH_INTERVAL_MS=10000
echo "======== After CONNECT_STATUS_STORAGE_TOPIC ====="
echo "======== Before PORT =====" 
#export PORT=$PORT:9092
export CONNECT_REST_PORT=$PORT
#export CONNECT_REST_PORT=9092
#export CONNECT_REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 
#export REST_PORT=$PORT
#export REST_ADVERTISED_HOST_NAME="$SERVER_HOST" 
echo "======== After PORT ====="
echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS "

curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties http://SERVER_HOST
sleep infinity
