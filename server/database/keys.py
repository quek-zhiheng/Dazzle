import os

DB_NAME = os.environ.get('PGDATABASE', 'dazzle_db')
DB_HOST = os.environ.get('PGHOST', 'localhost')
DB_PORT = os.environ.get('PGPORT', '5432')
DB_USERNAME = os.environ.get('PGUSER', 'postgres')
DB_PASSWORD = os.environ.get('PGPASSWORD')
DB_RESET = os.environ.get('DB_RESET', 'False')