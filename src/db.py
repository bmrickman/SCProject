# 3rd part imports
import mysql.connector
from mysql.connector import errorcode
# imports
from mysql_cfg import mysql_cfg



class db:
    def __init__(self):
        self.mysql_cfg = mysql_cfg

    def runQuery(self, query):
        try:
            self.query = query
            self.cnx = mysql.connector.connect(**self.mysql_cfg)   # attempt connect
            self.cursor = self.cnx.cursor()
            self.cursor.execute(query)                              # Query execution
            self.rows = self.cursor.fetchall()
            self.cnx.close()                                        # Close connection

        except mysql.connector.Error as err:
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                print("Something is wrong with your user name or password")
            elif err.errno == errorcode.ER_BAD_DB_ERROR:
                print("Database does not exist")
            # elif my errors - handled here - but how setup error codes with mysql.connector.errorcode?
            else:
                print(err)

    # 03/28/2021 - New, may be broken
    def runSQLFile(self, filePath):
        self.filePath = filePath
        self.cnx = mysql.connector.connect(**self.mysql_cfg)  # attempt connect
        self.cursor = self.cnx.cursor()

        with open(filePath, 'r') as f:
            result_iterator = self.cursor.execute(f.read(), multi=True)  # returns immediately, but we need a proise that things are complete, don't we?

            for res in result_iterator:
                print("Running query: ", res)  # Will print out a short representation of the query
                print(f"Affected {res.rowcount} rows")

            self.cnx.commit()
        self.cnx.close()


            # should be O(n)
    def rowListToRowDict(self):
        columns = [d[0] for d in self.cursor.description]
        for i, row in enumerate(self.rows):
            self.rows[i] = dict(zip(columns, row))

    def fetchAll(self, query):
        # If queries get too big to hold in python memory, we can store results on DB side and pull ass needed using fetchMany
        # https://www.mysqltutorial.org/python-mysql-query/
        self.runQuery(query)
        self.rowListToRowDict()



db = db()


