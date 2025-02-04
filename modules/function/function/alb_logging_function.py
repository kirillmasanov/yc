import os
import logging
import mysql.connector
import json

from datetime import datetime

# Преобразование строки времени в формат, который MySQL понимает
def convert_to_mysql_datetime(time_string):
    # Преобразуем строку в datetime объект
    dt = datetime.strptime(time_string, '%Y-%m-%dT%H:%M:%SZ')
    # Возвращаем в строковом формате для MySQL
    return dt.strftime('%Y-%m-%d %H:%M:%S')


logger = logging.getLogger()
logger.setLevel(logging.INFO)
verboseLogging = eval(os.environ['VERBOSE_LOG'])
if verboseLogging:
    logger.info('Loading handler function')

def handler(event, context):
    statusCode = 500
    
    if verboseLogging:
        logger.info(event)
        logger.info(context)
    
    ssl_cert_path = os.environ.get('DB_SSL_CA', 'root.crt')

    connection_params = {
        'host': os.environ['DB_HOSTNAME'],
        'port': int(os.environ['DB_PORT']),
        'database': os.environ['DB_NAME'],
        'user': os.environ['DB_USER'],
        'password': os.environ['DB_PASSWORD'],
        'ssl_ca': ssl_cert_path if os.path.exists(ssl_cert_path) else None,  # Проверка существования файла сертификата
        'ssl_disabled': os.environ.get('SSL_DISABLED', 'False').lower() == 'true'
    }
    
    if verboseLogging:
        logger.info(f'Connecting to MySQL: {connection_params}')
    
    try:
        conn = mysql.connector.connect(**connection_params)
        cursor = conn.cursor()
        
        messages = event['messages'][0]['details']['messages']
        
        for message in messages:
            alb_message = message['json_payload']
            alb_message['table_name'] = 'load_balancer_requests'
            
            insert_statement = (
                'INSERT INTO {table_name} ' 
                '(type, request_time, http_status, backend_ip, response_time) ' 
                'VALUES (%s, %s, %s, %s, %s)'
            ).format(table_name=alb_message['table_name'])
            
            values = (
                alb_message['type'],
                convert_to_mysql_datetime(alb_message['time']),
                alb_message['http_status'],
                alb_message['backend_ip'],
                alb_message['request_processing_times']['response_processing_time']
            )
            
            if verboseLogging:
                logger.info(f'Exec: {insert_statement} {values}')
            
            try:
                cursor.execute(insert_statement, values)
                statusCode = 200
            except Exception as error:
                logger.error(error)
            
            conn.commit()
        
    except mysql.connector.Error as err:
        logger.error(f'MySQL error: {err}')
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
    
    return {
        'statusCode': statusCode,
        'headers': {
            'Content-Type': 'text/plain'
        }
    }
