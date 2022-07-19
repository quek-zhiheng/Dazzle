#! /bin/bash

# defining parameters
db_name="dazzle_db"
username=$1
password=$2


# Creating database
postgres psql -c "CREATE DATABASE ${db_name} WITH ENCODING 'UTF8'"

# creating admin account for server admin
CREATE USER $1 WITH ENCRYPTED PASSWORD $2;
GRANT ALL PRIVELEGES ON DATABASE ${db_name} TO $1;

\q

export PGUSER=$1
export PGPASSWORD=$2
export DB_RESET="False"


