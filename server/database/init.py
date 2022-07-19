import psycopg2
from keys import *
from subprocess import call

## initialise db instance
def connect_db(initialise=False):
    
    if initialise == 'True':
        username = input('Provide database username: ')
        password = input('Provide database password: ')
        try:
            call(['bash', 'create_db.sh', username, password])
        except Exception as e:
            return 'Unable to create database. Reason: %s' % (e)
        
        print('Created Database. Now initialising tables...')
    
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USERNAME,
        password=DB_PASSWORD)
    
    cur = conn.cursor()
    
    try:
        cur.execute(open("schema.sql", "r").read())
    except (Exception, psycopg2.DatabaseError) as e:
        return 'Unable to create tables. Reason: %s' % (e)
    
    print('Tables created.')
    
    return conn
    
    
