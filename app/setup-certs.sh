#!/usr/bin/env bash

set -e

#addon="$1"

#[ -z $addon ] && {
  #echo "addon is missing" >&2
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

#echo -n "${!client_key}" >> /etc/kafka/client_key.pem
#echo -n "${!client_cert}" >>  /etc/kafka/client_cert.pem
#echo -n "${!trusted_cert}" >  /etc/kafka/truststore.pem

echo -n "$client_key" >>   /etc/kafka/client_key.pem
echo -n "$client_cert" >>  /etc/kafka/client_cert.pem
echo -n "$trusted_cert" >  /etc/kafka/truststore.pem
echo -ne "test" > /etc/kafka/test.txt
touch /etc/kafka/test1.txt

if [ "$?" = "0" ]; then
  echo "No Error while creating .pem files"
else
  echo "Error while creating .pem files"
  exit 1
fi

echo "keystore - $ /etc/kafka/keystore.pem"
echo "trusted - $ /etc/kafka/truststore.pem"

keytool -importcert -file  /etc/kafka/truststore.pem -keystore  /etc/kafka/truststore.jks -deststorepass $TRUSTSTORE_PASSWORD -noprompt

openssl pkcs12 -export -in  /etc/kafka/client_cert.pem -inkey  /etc/kafka/client_key.pem -out  /etc/kafka/keystore.pkcs12 -password pass:$KEYSTORE_PASSWORD
keytool -importkeystore -srcstoretype PKCS12 \
    -destkeystore  /etc/kafka/keystore.jks -deststorepass $KEYSTORE_PASSWORD \
    -srckeystore  /etc/kafka/keystore.pkcs12 -srcstorepass $KEYSTORE_PASSWORD

#rm -f .{keystore,truststore}.{pem,pkcs12}
