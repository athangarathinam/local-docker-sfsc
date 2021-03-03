# this is an official Python runtime, used as the parent image
#FROM confluentinc/cp-kafka-connect-base
FROM confluentinc/cp-kafka-connect:5.5.3

# Create plugin directory
RUN mkdir -p /usr/share/java/plugins \
&& mkdir -p /usr/share/java/kafka-connect-jdbc \
#RUN mkdir -p /etc/kafka/kafka-logs
&& mkdir -p /etc/kafka-connect/kafka-logs 

RUN confluent-hub install --no-prompt snowflakeinc/snowflake-kafka-connector:1.5.2 \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:latest  \
 && confluent-hub install --no-prompt confluentinc/kafka-connect-http:latest \
 ##&& confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.0.1 \
 && update-ca-certificates
 
ADD https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/1.0.2/bc-fips-1.0.2.jar /usr/share/java/kafka-connect-jdbc/bc-fips-1.0.2.jar
ADD https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/1.0.5/bcpkix-fips-1.0.5.jar /usr/share/java/kafka-connect-jdbc/bcpkix-fips-1.0.5.jar
ADD https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/1.0.2/bc-fips-1.0.2.jar /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bc-fips-1.0.2.jar
ADD https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/1.0.5/bcpkix-fips-1.0.5.jar /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bcpkix-fips-1.0.5.jar
ADD https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.17/snowflake-jdbc-3.12.17.jar /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-3.12.17.jar
ADD https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.12.17/snowflake-jdbc-3.12.17.jar /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-jdbc-3.12.17.jar


#ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/usr/share/java/kafka-connect-jdbc,/etc/kafka-connect"
ENV CONNECT_PLUGIN_PATH="/usr/share/java/kafka-connect-jdbc/*,/usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-kafka-connector-1.5.2.jar,/usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-jdbc-3.12.12.jar,/usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/*,/etc/kafka-connect/*"


#install vim and update 
#RUN dpkg -i debian-archive-keyring_2017.5~deb8u1_all.deb -y \
RUN sed -i 's;http://archive.debian.org/debian/;http://deb.debian.org/debian/;' /etc/apt/sources.list \
   && apt-get update \
   && apt-get install unzip \
   && apt-get install zip \
   && apt-get --yes --force-yes install -y --no-install-recommends apt-utils \
   vim
   
  
#Remove log4j.properties file
#RUN rm /etc/kafka/log4j.properties
#RUN rm /etc/kafka/connect-log4j.properties

#RUN rm /etc/kafka-connect/log4j.properties
#RUN rm /etc/kafka-connect/connect-log4j.properties

# Copy config and certs
#COPY .build/certs/*.crt /usr/local/share/ca-certificates/
#COPY app/connect-distributed.properties /etc/kafka/connect-distributed.properties
#COPY app/start.sh /etc/kafka/start.sh
#COPY app/setup-certs.sh /etc/kafka/setup-certs.sh
COPY app/log4j.properties /etc/kafka/log4j.properties
COPY app/connect-log4j.properties /etc/kafka/connect-log4j.properties
#COPY app/kafka-generate-ssl-automatic.sh /etc/kafka/kafka-generate-ssl-automatic.sh

COPY .build/certs/*.crt /usr/local/share/ca-certificates/
COPY app/connect-distributed.properties /etc/kafka-connect/connect-distributed.properties
COPY app/start.sh /etc/kafka-connect/start.sh
COPY app/start_test.sh /etc/kafka-connect/start_test.sh
COPY app/setup-certs.sh /etc/kafka-connect/setup-certs.sh
#COPY app/bc-fips-1.0.1.jar /usr/share/java/kafka-connect-jdbc/bc-fips-1.0.1.jar
#COPY app/bcpkix-fips-1.0.5.jar /usr/share/java/kafka-connect-jdbc/bcpkix-fips-1.0.5.jar
#COPY app/bc-fips-1.0.1.jar /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bc-fips-1.0.1.jar
#COPY app/bcpkix-fips-1.0.5.jar /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bcpkix-fips-1.0.5.jar
#COPY usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-kafka-connector-1.5.1.jar /usr/share/java/kafka-connect-jdbc/snowflake-kafka-connector-1.5.1.jar
#COPY usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-jdbc-3.12.12.jar /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-3.12.12.jar
#COPY app/log4j.properties /etc/kafka-connect/log4j.properties
#COPY app/connect-log4j.properties /etc/kafka-connect/connect-log4j.properties

#Config Log4j at Launching Place
#RUN chmod +x /etc/kafka-connect/log4j.properties
#RUN chmod +x /etc/kafka-connect/connect-log4j.properties

# Confluent Hub Config and Installs
#ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/etc/kafka"
#ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components,/etc/kafka-connect,/etc/kafka-connect/jar"


#RUN chmod +x /etc/kafka/start.sh
#RUN chmod +x /etc/kafka/setup-certs.sh
#RUN chmod +x /etc/kafka/connect-distributed.properties
RUN chmod +x /etc/kafka/log4j.properties \
&& chmod +x /etc/kafka/connect-log4j.properties \
&& chmod +x /etc/kafka-connect/start.sh \
&& chmod +x /etc/kafka-connect/start_test.sh \
&& chmod +x /etc/kafka-connect/setup-certs.sh \
&& chmod +x /etc/kafka-connect/connect-distributed.properties \
&& chmod +x /usr/share/java/kafka-connect-jdbc/bcpkix-fips-1.0.5.jar \
&& chmod +x /usr/share/java/kafka-connect-jdbc/bc-fips-1.0.2.jar \
&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bc-fips-1.0.2.jar \
&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bcpkix-fips-1.0.5.jar \
&& chmod +x /usr/share/java/kafka-connect-jdbc/snowflake-jdbc-3.12.17.jar \
&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/snowflake-jdbc-3.12.17.jar


#&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bcpkix-fips-1.0.3.jar \
#&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bc-fips-1.0.2.jar
#&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bcpkix-fips-1.0.5.jar \
#&& chmod +x /usr/share/confluent-hub-components/snowflakeinc-snowflake-kafka-connector/lib/bc-fips-1.0.1.jar 
#&& chmod +x /usr/share/confluent-hub-components/kafka-connect-jdbc-5.5.3.jar


#RUN chmod +x /etc/kafka/kafka-generate-ssl-automatic.sh
#ENTRYPOINT ["source", "/etc/kafka/start.sh"]
#RUN /etc/kafka/setup-certs.sh
#CMD ["/etc/kafka/start.sh"]
CMD ["/etc/kafka-connect/start.sh"]


#CMD ["/etc/kafka-connect/start_test.sh"]

#CMD curl -vvv -X POST -H "Content-Type: application/json" --data /etc/kafka/connect-distributed.properties https://sfsc-kafka-c1-test.herokuapp.com:443/connectors ; 'bash'

