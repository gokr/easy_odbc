import "package:easy_odbc/odbc.dart";
import "package:test/test.dart";

void main() {
  test("Can connect and disconnect", () {
    var conn = OdbcConnection("internaldb");
    conn.disconnect();
  });

  test("Fails connecting to bad DSN", () {
    expect(() => OdbcConnection("bogus"), throwsA(TypeMatcher<String>()));
  });

  test("Fail disconnecting twice", () {
    var conn = OdbcConnection("internaldb");
    conn.disconnect();
    expect(() => conn.disconnect(), throwsA(TypeMatcher<String>()));
  });

  test("Can create table", () {
    var conn = OdbcConnection("internaldb");
    conn.execute(
        "drop table gurka; create table gurka (id int, name varchar);");
    conn.disconnect();
  });

  test("Fail bad SQL", () {
    var conn = OdbcConnection("internaldb");
    expect(() => conn.execute("drop tabllllee gurka;"),
        throwsA(TypeMatcher<String>()));
    conn.disconnect();
  });

  test("Trivial select works", () {
    var conn = OdbcConnection("internaldb");
    conn
        .execute("drop table gurka; create table gurka (id int, name varchar);")
        .free();
    conn.execute("insert into gurka values (99, 'banana');").free();
    conn.execute("insert into gurka values (100, 'orange');").free();
    var stmt = conn.prepare("select * from gurka;");
    stmt..addColumn(10)..addColumn(100);
    stmt.execute();
    var res = stmt.resultSet;
    stmt.fetch();
    expect(res.values(), equals(['99', "banana"]));
    stmt.fetch();
    expect(res.values(), equals(['100', "orange"]));
    stmt.free();
    conn.disconnect();
  });
}
