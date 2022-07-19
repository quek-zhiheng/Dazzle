from keys import *
from subprocess import call

## initialise db instance
def create_db():
    username = input('Provide database username: ')
    password = input('Provide database password: ')
    
    print('Creating database...')
    
    try:
        call(['bash', 'create_db.sh', username, password])
    except Exception as e:
        return 'Unable to create database. Reason: %s' % (e)
    
    print('Created Database. Now initialising tables...')
    

    
    
