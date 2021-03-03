import snowflake.connector
import os
import json
import ssl
import kafka_helper
import psycopg2
from kafka import KafkaProducer   ,  KafkaConsumer

V_KAFKA_URL = os.environ.get('KAFKA_URL')
V_KAFKA_TRUSTED_CERT = os.environ.get('KAFKA_TRUSTED_CERT')
print("Kafka URL" , V_KAFKA_URL)
print("Kafka T_CERT", V_KAFKA_TRUSTED_CERT)
V_SSL_CONTEXT = kafka_helper.get_kafka_ssl_context()
print("SSL Context",V_SSL_CONTEXT)

KAFKA_TOPIC = 'salfrs_kafka_snowflake'

# Create Producer Properties
def fn_kafka_producer(acks='all',
                      value_serializer=lambda v: json.dumps(v).encode('utf-8')):
    kafkaprod = KafkaProducer(
        bootstrap_servers=V_KAFKA_URL.split(",")[0].replace("kafka+ssl://",""),
        # key_serializer=key_serializer,
        value_serializer=value_serializer,
        ssl_context=V_SSL_CONTEXT,
        acks=acks,
        security_protocol="SSL"
    )
    return kafkaprod
  
def get_kafka_consumer(topic=None,
                       value_deserializer=lambda v: json.loads(v.decode('utf-8'))):
    """
    Return a KafkaConsumer that uses the SSLContext created with create_ssl_context.
    """

    # Create the KafkaConsumer connected to the specified brokers. Use the
    # SSLContext that is created with create_ssl_context.
    print("Topic Used - ---",  topic)
    consumer = KafkaConsumer(
        topic,
        #bootstrap_servers=get_kafka_brokers(),
        bootstrap_servers=V_KAFKA_URL.split(",")[0].replace("kafka+ssl://",""),
        security_protocol='SSL',
        ssl_context=V_SSL_CONTEXT,
        value_deserializer=value_deserializer
    )

    return consumer
  
def get_postgres_data():
  
  try:
    DATABASE_URL = os.environ['DATABASE_URL']
    connection = psycopg2.connect(DATABASE_URL, sslmode='require')
    cursor = connection.cursor()
    print(connection.get_dsn_parameters(), "\n")
    #postgreSQL_select_Query = "select * from salesforce.period where startdate='''2010-01-01'''"
    postgreSQL_select_Query = "SELECT array_to_json(array_agg(row_to_json(prd))) FROM salesforce.period prd where startdate='''2010-01-01'''"
    print("The value of postgreSQL_select_Query is -", postgreSQL_select_Query)

    cursor.execute(postgreSQL_select_Query)

    period_records = cursor.fetchall()
    print("The value of period_records",period_records)

    #period_JSON = '{{{}}}'.format(
     # ','.join(['{}:{}'.format(json.dumps(k), json.dumps(v)) for k, v in period_records]))
    
    #print("Period JSON", period_JSON)

    #for row in period_records:
     # print("Id =", row[3], "\n")
      #print("IsForecastPeriod =", row[4])
      #print("PeriodLabel =", row[6], "\n")
      #print("QuarterLabel =", row[7], "\n")

    return period_records

  except (Exception, psycopg2.Error) as error:
      print("Error while connecting to PostgreSQL", error)

if __name__ == '__main__':
  print("Hi Main")
  # Create the Producer
  PRODUCER = fn_kafka_producer()
  print("KAFKA PRODUCER -", type(PRODUCER))

  # Create a producer Record
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!12')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!123')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!1234')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Heroku!!12345')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!12')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!123')
#   PRODUCER.send(KAFKA_TOPIC, 'Hello Pstgres!!1234')

  V_KAFKA_TOPIC = 'salfrs_kafka_snowflake'

  v_postgres_tbl_data = get_postgres_data()
  print("The value of postgres data is",  v_postgres_tbl_data)
  PRODUCER.send(V_KAFKA_TOPIC, v_postgres_tbl_data)
  PRODUCER.close()
    
  print("Consumer Test First @@@@@@@@@@@@@@ -- 123456789")
  #Create the Consumer
  V_CONSUMER = get_kafka_consumer(topic='salfrs_kafka_snowflake')
  print("Consumer Test @@@@@@@@@@@@@@ -- 123456789")
  #CONSUMER.flush()
  
  print( "CONSUMER IS -", str(V_CONSUMER))
  
  try:
    #with open("/opt/consumerdata/period.json","w") as snowstg:
    with open("/tmp/period.json","w") as snowstg:
      snowstg.write(V_CONSUMER)
  except (IOError, ValueError, EOFError) as e:
    print("Error as IOError, ValueError, EOFError", e)
  except OSError as err:
    print("OS error: {0}".format(err))
  finally:
    print("Finally Error")
   
                         
    #json.dumps(V_CONSUMER, snowstg)
   
#   for message in V_CONSUMER:
#     print("Consumer Test Inside FOr loop @@@@@@@@@@@@@@ -- 123456789")
#     print ("%s:%d:%d: key=%s value=%s" % (message.topic, message.partition,
#                                           message.offset, message.key,
#                                           message.value))
#     print("Consumer Test After For loop @@@@@@@@@@@@@@ -- 123456789")
#     print(message.value['Body'])  
#     print("Consumer Test After Body Print @@@@@@@@@@@@@@ -- 123456789")
    
#     # Connect Snowflake
#     conn= snowflake.connector.connect(
#       account = 'wda05749',
#       user = 'ATHANGARATHINAM',
#       password = 'Pradev2023',
#       database = 'SALES_FORCE_POC',
#       schema = 'PUBLIC',
#       warehouse = 'WH_SF_KAFKA_POC')
#     cur = conn.cursor()
#     tablval = cur.execute("select * from test1").fetchall()
#     print(tablval)
