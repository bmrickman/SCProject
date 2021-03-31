## Db object is one directory higher
import os, sys
currentdir = os.path.dirname(os.path.realpath(__file__))
parentdir = os.path.dirname(currentdir)
sys.path.append(parentdir)

## import db object
from db import db

## Drop the database
db.runQuery('DROP DATABASE IF EXISTS sc')
## Pass .SQL file to create database
with open('../db_init_shallow_dvd_sc.sql', 'r') as file:
    db.runSQLFile(file)
# Calling procedure to rebuild database
db.runQuery('CALL sc.build_shallow_vg_sc(10,10,10)')
# Pulling data from DB
db.fetchAll("SELECT * FROM sc.products")
# Should display only if all above processes worked
print(db.rows)