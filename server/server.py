from flask import Flask
import psycopg2
from database.db_init import create_db
from database.keys import *
import datetime

app = Flask(__name__)

def connect_db():
    """
    Connect to the PostgreSQL database.  Returns a database connection.
    """
    try:
        conn =  psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USERNAME,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT)
    except (Exception, psycopg2.DatabaseError) as error:
        return 'Unable to connect to database. Reason: %s' % (error)
    
    return conn

conn = connect_db()

## defining api endpoints
@app.route('/')
def index():
    cur = conn.cursor()



