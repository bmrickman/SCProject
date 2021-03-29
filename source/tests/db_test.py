import os, sys
currentdir = os.path.dirname(os.path.realpath(__file__))
parentdir = os.path.dirname(currentdir)
sys.path.append(parentdir)


from db import db
db.runSQLFile('../dummy_db_init_script.sql')
db.fetchAll("SELECT * FROM sc.products")
print(db.rows)