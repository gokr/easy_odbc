import 'package:odbc/odbc.dart';

class ResultSet {
  var columns = List<ResultColumn>();

  addColumn(ResultColumn column) {
    columns.add(column);
  }

  /// Bind my columns
  bind(OdbcSQLStatement statement) {
    for (var i = 0; i < columns.length; i++) {
      statement.bind(columns[i], i);
    }
  }

  /// Return current values of one row
  List<String> values() {
    return columns.map((c) => c.peek(0)).toList();
  }
}

class ResultColumn {
  int index;
  SqlStringBuffer value;
  final flags = SqlIntBuffer();

  ResultColumn(this.index, int size) {
    value = SqlStringBuffer(300);
  }

  String peek(int row) {
    return value.peek(row, 0);
  }
}

class DiagRec {
  OdbcSQLStatement statement;

  final _state = new SqlString(SQLSTATE);
  final _nativeError = new SqlInt();
  final _message = new SqlString(256);

  String get state => _state.value;
  int get error => _nativeError.value;
  String get message => _message.value;

  DiagRec(this.statement) {
    sqlGetDiagRec(SQL_HANDLE_STMT, statement.handle, 1, _state, _nativeError,
        _message, _message.length, null);
  }
}

class OdbcSQLStatement {
  OdbcConnection connection;
  SqlHandle handle;
  String sql;

  ResultSet resultSet = ResultSet();

  OdbcSQLStatement(this.connection, this.sql) {
    handle = SqlHandle();
    sqlAllocHandle(SQL_HANDLE_STMT, connection.conn, handle);

    // Prepare statement.
    var res = sqlPrepare(handle, sql, SQL_NTS);
  }

  /// Add a result set column.
  ResultColumn addColumn(int size) {
    var column = ResultColumn(resultSet.columns.length + 1, size);
    resultSet.addColumn(column);
    return column;
  }

  // Bind parameters.
  // var objId = new SqlIntBuffer()..poke(6); // "Customer Document"
  // sqlBindParameter(hStmt, 1, SQL_PARAM_INPUT, objId.ctype(), SQL_INTEGER, 0,
  //    0, objId.address(), 0, null);

  /// Bind a result set column, we count from 0 but dart-odbc counts from 1
  void bind(ResultColumn column, int i) {
    sqlBindCol(handle, i + 1, column.value.ctype(), column.value.address(),
        column.value.length(), column.flags.address());
  }

  int execute() {
    resultSet.bind(this);
    var res = sqlExecute(handle);
    if (res != 0) {
      throw "Failed to execute SQL: $sql";
    }
    return res;
  }

  int fetch() {
    return sqlFetch(handle);
  }

  DiagRec diagnose() {
    return DiagRec(this);
  }

  printDiagnose() {
    var rec = diagnose();
    print("State ${rec.state}");
    print("Error ${rec.error}");
    print("Message ${rec.message}");
  }

  free() {
    sqlFreeHandle(SQL_HANDLE_STMT, handle);
  }
}

class OdbcConnection {
  String dsn;
  String username;
  String password;
  String database;

  SqlHandle env;
  SqlHandle conn;

  OdbcConnection(this.dsn, [this.username, this.password]) {
    env = _createEnv();
    conn = _connect();
  }

  SqlHandle _connect() {
    // Set ODBC version to be used.
    var version = new SqlPointer()..value = SQL_OV_ODBC3;
    sqlSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, version, 0);

    // Allocate a connection handle.
    var hConn = SqlHandle();
    sqlAllocHandle(SQL_HANDLE_DBC, env, hConn);

    // Connect.
    var res =
        sqlConnect(hConn, dsn, SQL_NTS, username, SQL_NTS, password, SQL_NTS);
    if (res != 0) {
      throw "Failed to connect to DSN: $dsn username: $username password: $password";
    }
    return hConn;
  }

  /// Prepare an SQL statement
  OdbcSQLStatement prepare(String sql) {
    return OdbcSQLStatement(this, sql);
  }

  /// Execure an SQL statement directly
  OdbcSQLStatement execute(String sql) {
    var stmt = OdbcSQLStatement(this, sql);
    stmt.execute();
    return stmt;
  }

  /// Allocate an environment handle.
  SqlHandle _createEnv() {
    var env = new SqlHandle();
    sqlAllocHandle(SQL_HANDLE_ENV, null, env);
    return env;
  }

  /// Disconnect
  disconnect() {
    var res = sqlDisconnect(conn);
    if (res != 0) {
      throw "Failed to disconnect";
    }
    sqlFreeHandle(SQL_HANDLE_DBC, conn);
    sqlFreeHandle(SQL_HANDLE_ENV, env);
  }
}
