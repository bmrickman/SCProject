# 3rd part imports
import mysql.connector
from mysql.connector import errorcode
# imports
from mysql_cfg import mysql_cfg



class db:

    def __init__(self):
        self.mysql_cfg = mysql_cfg
        self.query = None
        self.cnx = None
        self.cursor = None
        self.row = None

    # Used to wrap all methods in connect -> method -> disconnect pattern
    def try_connect(method):
        def inner(self,*params):
            try:
                self.cnx = mysql.connector.connect(**self.mysql_cfg)
                self.cursor = self.cnx.cursor()
                res = method(self, *params)
                self.cnx.close()
                return(res)

            except mysql.connector.Error as err:
                if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                    print("Something is wrong with your user name or password")
                elif err.errno == errorcode.ER_BAD_DB_ERROR:
                    print("Database does not exist")
                # elif my errors - handled here - but how setup error codes with mysql.connector.errorcode?
                else:
                    print(err)
        return inner

    @try_connect
    def runSQLFile(self, fileHandle):
        self.fileHandle = fileHandle
        result_iterator = self.cursor.execute(fileHandle.read(), multi=True)
        for res in result_iterator:
            print("Running query: ", res)  # Will print out a short representation of the query
            print(f"Affected {res.rowcount} rows")
        self.cnx.commit()

    @try_connect
    def runQuery(self, query):
        self.query = query
        self.cursor.execute(query)                                    # Query execution
        self.rows = self.cursor.fetchall()

    @try_connect
    def fetchAll(self, query):
        # If queries get too big to hold in python memory, we can store results on DB side and pull ass needed using fetchMany
        # https://www.mysqltutorial.org/python-mysql-query/
        self.runQuery(query)
        self.rowListToRowDict()
        return(self.rows)

    @try_connect
    def executemany(self, stmt, rows):
        self.cursor.executemany(stmt, rows)

    def rowListToRowDict(self):
        columns = [d[0] for d in self.cursor.description]
        for i, row in enumerate(self.rows):
            self.rows[i] = dict(zip(columns, row))


db = db()



