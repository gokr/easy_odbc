
# Easy ODBC
A trivial wrapper library of dart-odbc.

# Test
Make sure you have a Sqlite3 DSN configured called "internaldb", see below. Then run tests:

    pub run test

# A Sqlite3 DSN
You need to create the sqlite3 database file manually, then configure like below.

cat /etc/odbcinst.ini

    [SQLite3]
    Description=SQLite3 ODBC Driver
    Driver=libsqlite3odbc.so
    Setup=libsqlite3odbc.so
    UsageCount=1

cat /etc/odbc.ini

    [internaldb]
    Driver   = SQLite3
    Database = /var/db/internal.db