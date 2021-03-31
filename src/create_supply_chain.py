from db import db
with open('db_init_shallow_dvd_sc.sql', 'r') as file:
    db.runSQLFile(file)
db.runQuery('CALL sc.build_shallow_vg_sc(10,10,10)')

