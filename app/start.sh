#!/usr/bin/env bash

echo $APP_NAME

echo "======== $APP_NAME ====="
SERVER_HOST="$(echo $APP_NAME).herokuapp.com"
#SERVER_URL=https://$SERVER_HOST
SERVER_URL=http://$SERVER_HOST
export CONNECT_REST_ADVERTISED_HOST_NAME=$(echo $APP_NAME).herokuapp.com
export CONNECT_KAFKA_HEAP_OPTS="-Xms256M -Xmx2G"
KAFKA_HEAP_OPTS="-Xms256M -Xmx1G"

export RANDFILE=/etc/kafka-connect/.rnd
#set RANDFILE=.rnd

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

echo -n "$client_key" >   /etc/kafka-connect/client_key.pem
echo -n "$client_cert" >  /etc/kafka-connect/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka-connect/truststore.pem

echo "Cat client_key.pem"
echo ""
cat /etc/kafka-connect/client_key.pem
echo "Cat client_cert.pem"
echo ""
cat /etc/kafka-connect/client_cert.pem
echo "Cat truststore.pem"
echo ""
cat /etc/kafka-connect/truststore.pem
echo ""

if [ "$?" = "0" ]; then
  echo "No Error while creating .pem files"
else
  echo "Error while creating .pem files"
  exit 1
fi

echo "keystore - $ /etc/kafka-connect/client_key.pem"
echo "trusted - $ /etc/kafka-connect/client_cert.pem"
echo "trusted - $ /etc/kafka-connect/truststore.pem"

keytool -importcert -file  /etc/kafka-connect/truststore.pem -keystore  /etc/kafka-connect/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka-connect/client_cert.pem -inkey  /etc/kafka-connect/client_key.pem -out  /etc/kafka-connect/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD
keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka-connect/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka-connect/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD

#rm -f .{keystore,truststore}.{pem,pkcs12}

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

#For log4j 
#export CONNECT_LOG4J_LOGGERS=TRACE, file, stdout, stderr, kafkaAppender, connectAppender, INFO
#export CONNECT_LOG4J_ROOT_LOGLEVEL=TRACE, file, stdout, stderr, kafkaAppender, connectAppender, INFO

export CONNECT_LOG4J_LOGGERS="io.confluent.connect=DEBUG"
#export CONNECT_LOG4J_LOGGERS="io.confluent.connect.jdbc=DEBUG"


export CONNECT_SECURITY_PROTOCOL=SSL
export CONNECT_SSL_TRUSTSTORE_LOCATION=/etc/kafka-connect/truststore.jks
export CONNECT_SSL_TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD
export CONNECT_SSL_KEYSTORE_LOCATION=/etc/kafka-connect/keystore.jks
export CONNECT_SSL_KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_KEY_PASSWORD=$KEYSTORE_PASSWORD
export CONNECT_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=

echo "Variables: $kafka_addon_name $prefix_env_var $kafka_prefix $kafka_url_env_var $postgres_addon_name "

echo "Secuirty protocal: H-$HOME TP-$TRUSTSTORE_PASSWORD KP-$KEYSTORE_PASSWORD"

echo "======== After postgres_addon_name ========"

#export CONNECT_BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}
#BOOTSTRAP_SERVERS=${!kafka_url_env_var//kafka+ssl:\/\//}

export CONNECT_GROUP_ID=kafka-snowflake-connect-cluster
#export CONNECT_GROUP_ID="kafka-dimensional-99909_PREFIX"
#GROUP_ID=$(echo $kafka_prefix)connect-cluster

export CONNECT_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_KEY_CONVERTER="org.apache.kafka.connect.json.JsonConverter"
export CONNECT_INTERNAL_VALUE_CONVERTER="org.apache.kafka.connect.json.JsonConverter"

export CONNECT_OFFSET_STORAGE_TOPIC="sf_kafka_sf_offset"
export CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=3

export CONNECT_CONFIG_STORAGE_TOPIC="sf_kafka_sf_config"
export CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=3

export CONNECT_STATUS_STORAGE_TOPIC="sf_kafka_sf_status"
export CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=3

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
echo "Bootstrap Values: $CONNECT_BOOTSTRAP_SERVERS"

echo "======== After CONNECT_PLUGIN_PATH ====="
echo "============Starting Process========= "
 /etc/confluent/docker/run &
echo " Server URL $SERVER_URL "

echo "Heroku Port - $CONNECT_REST_PORT"

#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties $SERVER_URL/connectors
#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com
#curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka-connect/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com/connectors

#curl -vvv -X POST https://sfsc-kafka-c1-test.herokuapp.com:$PORT/salesforce-kafka-snowflakes -H "Content-Type: application/json" --data '{
curl -vvv -X POST https://sfsc-kafka-c1-test.herokuapp.com/connectors -H "Content-Type: application/json" --data '{
    "name":"KafkaSinkConnectortoSnowflakes",
	"config":{
		"connector.class":"com.snowflake.kafka.connector.SnowflakeSinkConnector",
		"tasks.max":"8",
		"topics":"salesforce_kafka_snowflakes.salesforce.period",
		"snowflake.topic2table.map": "salesforce_kafka_snowflakes.salesforce.period:PERIOD",
		"buffer.count.records":"10000",
		"buffer.flush.time":"60",
		"buffer.size.bytes":"5000000",
		"snowflake.url.name":"https://wda05749.snowflakecomputing.com:443",
		"snowflake.user.name":"MMUSAPETA",
		"snowflake.private.key":"MIIFLTBXBgkqhkiG9w0BBQ0wSjApBgkqhkiG9w0BBQwwHAQIvykkL/zxtrUCAggAMAwGCCqGSIb3DQIJBQAwHQYJYIZIAWUDBAEqBBBcDpE9qT6i89KKeBz90a7tBIIE0P13tDDvw0fcBsDBR2TE7B7II1xU0R+4dsjsEY1CAqvwoJPJAqwN5QDaI2By+gKcFzAvp5NXNVuGCT6DuVWXlCNZFz2C3BePyFAzAt9fltuRbiDkl2z19IGXzWt91rvcT028r28I3QiKpwTVSdcQTgCrBSzJoIpp86j7/kNsHq5ldS8rKosK55t5gd+CVwOMiEcJkfOItmoZNrhJHx5d9LRZ8EYqffftHF1FbK3S9vL9rGZXt1xpNSCY34Tjl3pAsXfuUlcuO37Q8O7d9ZKt1stcQ1q7+eXtU10Q3Nk1CFS0CSzH7uNXeKR1DbuEHV3rJd+n9DngJKaShL1vxJEVfpAplRjN9TTPc6gtL0ZxB6vrwDER99Q+tLjVExEN8z1BqAFqsqzk03nmEw4D/MSQrSzgkb3QtO1o4iWSrQWDo2fp25vuwevyaU5dfD05rf0sW9YiaF4n6BTS+yZg+AbKL9PQ4+d6p0bDRfWdDPW91vwdrMpsXjGPnUCx5bOP+qjp7/n+QRgr2UIb7JpK2++7EqCMsw4Wkem7uY21ygtJgZPtjNTd2LB0TBMjmtWBLK7PU1mNAUSw0gLJBQPu7REgpPrvyYNSHONB0otQO6JUStzJZ00LrWwj6b4FkgU4uR3MKVTZLaCUca0Do1Rgw6VBEQLFGNxeBDRutGI4MMmJEQlHYZPfiZIkjsfloqa/8kESt/CIGaphKCTZFGDVRUzU8JJ51WXs3rGcZOGxV1DPlahaEsOI08i/KMyJMYItWWgtKtCUvZJ/ATjog4XCN/UTq57LBfW5SSVBA/pLPbqYqL4JSxJjM21fOSLfU6L2q0xnpRSM5Ft67iLXRjM7GYKBgnfwE6XEPOGVDAtRowIoGEprWPiOnX15cIaZvott0Fbr6RtzGjt2uXePHz+LvpRyrOjSl9e9fGeUZmZoxW37NpLYkLLBqMNZGAgKn5tnr6029Cy6x1R8tngKa+VTNYgXxclGx2WIiYeNT+OQ3KXtaPGHQA8tvrJpmx5ibolqLJxVJgzU9f8G6+Irtru4cjCZRQUFgOUac3cne3NupAIW3bMNWxYfRxWikhJua1ilj/RdKZ2RMb7gCqB3doW3epGyBpj4p9pQPoELC5DP7pxZ+a0brD4I8AaQ8iBdDj67w98kRifDxfofaEnidx57gvt/dWgouRxMHxtLPkUbbCucvL0LBwzwOBb7AK4STsm6D1NXunIpdqZCmlqIN+P43WlPB0YhUhW8hPcZARptr92AMzddTU3Hz3P0pnNCI9PE1gHkfKWnJyR0gPm297aGAtW1YGlmVDa/Ct3SncuC6HBM6vWX8p71JF77tdqfNOk7+inybv50q8oIn03yOTWvMVOKYn6hGUjAfPB5a90ckZs9BsWjx89zbqa5Zaqw/mr2V5Zfz12RpBUazfsSpURV+ZaM5/oqi5LqZztd5vhoYqU9OmR9gyUVcB+3yAJ+K+2EBbtuaipqKr4KKad9kfHC1/IXwgEAakJy/iGcZJglueDxXtojBJyjzXUFKJBf5gswdISSGZNqLQ/rl5N8tKhPRxKCPw6MGDdYiw4sBre1dqJGfwWLT1h1z5IsmtjggJWKrk3XzY0PckmCDn1s0z0GNOyjnFFCpqYHvcPqNN1QbJPjvb8",
		"snowflake.private.key.passphrase":"MNjklpo0897",
		"snowflake.database.name":"SF_KAFKA_SF",
		"snowflake.schema.name":"SF_KAFKA",
		"key.converter":"org.apache.kafka.connect.storage.StringConverter",
		"value.converter":"com.snowflake.kafka.connector.records.SnowflakeJsonConverter"
		}
		}'
sleep infinity
 #KAFKA_HEAP_OPTS="-Xms256M -Xmx256M " /usr/bin/connect-distributed /etc/kafka-connect/connect-distributed.properties
#exec /etc/confluent/docker/run
