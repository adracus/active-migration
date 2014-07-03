/*import '../../PostgresAdapter/lib/postgres_adapter.dart';
import 'package:unittest/unittest.dart';
import 'package:activerecord/activerecord.dart';

class MyCollection extends Collection {
  get variables => ["name", "haircolor"];
}

main() {
  var p = new PostgresAdapter.fromUri("url");
  var c = new MyCollection();
  
  test("Test drop table statement generation", () {
    var s = p.buildDropTableStatement("MyTable");
    expect(s.sql, equals("DROP TABLE IF EXISTS @tableName"));
    expect(s.values["tableName"], equals("MyTable"));
  });
  
  test("Test findModelsByVariable statement generation", () {
    var s = p.buildFindModelsByVariablesStatement(c.schema,
        {new Variable("myvar"): "myvalue"}, null, null);
    expect(s.sql, equals("SELECT * FROM MyCollection WHERE myvar=@value1"));
    s = p.buildFindModelsByVariablesStatement(c.schema,
        {new Variable("myvar"): "myvalue", new Variable("another") : "aval"},
        1, null);
    expect(s.sql, equals("SELECT * FROM MyCollection WHERE myvar=@value1 " +
                         "AND another=@value2 LIMIT 1"));
    expect(s.values.containsValue("aval"), isTrue);
    expect(s.values.containsValue("myvalue"), isTrue);
  });
}*/