library postgresadapter;
import 'dart:async';
import '../activemigration.dart';
import 'package:activerecord/activerecord.dart' as ar;
import 'package:postgresql/postgresql.dart';

class PostgresAdapter extends DatabaseAdapter {
  String _uri;
  
  PostgresAdapter(config) : super(config) {
    _uri = "postgres://${config["username"]}:${config["password"]}" +
        "@${config["host"]}:${config["port"]}/${config["database"]}";
  }
  
  PostgresAdapter.fromUri(this._uri) : super(null);
  
  Future statementExec(Statement s) =>
      connect(_uri).then((conn) {
        ar.log.info("Executing: ${s.sql}");
        return conn.execute(s.sql, s.values).whenComplete(() => conn.close());
      });
  
  Future statementQuery(Statement s) =>
      connect(_uri).then((conn) {
        ar.log.info("Executing: ${s.sql}");
        return conn.query(s.sql, s.values).toList().whenComplete(() =>
            conn.close());
      });
  
  Future<bool> boolStatementExec(Statement s) =>
        statementExec(s).then((_) => true);
  
  Future<bool> createTable(ar.Schema schema) =>
      boolStatementExec(buildCreateTableStatement(schema));
  
  Future<bool> dropTable(String tableName) =>
      boolStatementExec(buildDropTableStatement(tableName));
  
  Future<bool> addColumnToTable(String tableName, ar.Variable variable) =>
      boolStatementExec(buildAddColumnStatement(tableName, variable));
  
  Future<bool> removeColumnFromTable(String tableName, String variableName) =>
      boolStatementExec(buildRemoveColumnStatement(tableName, variableName));
  
  Future<bool> destroyModel(ar.Model m) =>
      boolStatementExec(buildDestroyModelStatement(m));
  
  Future<ar.Model> saveModel(ar.Schema schema, ar.Model m) {
    return statementQuery(buildSaveModelStatement(m)).then((rows) {
      rows.forEach((row) => updateModelWithRow(row, m));
      return m;
    });
  }
  
  Future<ar.Model> updateModel(ar.Schema schema, ar.Model m) {
    return statementQuery(buildUpdateModelStatement(m)).then((rows) {
      return m;
    });
  }
  
  Future<List<ar.Model>> findModelsByVariables(ar.Collection c,
        Map<ar.Variable, dynamic> variables, {int limit, int offset}) {
    return statementQuery(
        buildFindModelsByVariablesStatement(c.schema, variables, limit, offset))
            .then((rows) {
      var models = [];
      rows.forEach((row) => models.add(updateModelWithRow(row, c.nu)));
      return models;
    });
  }
  
  Future<List<ar.Model>> modelsWhere(ar.Collection c, String sql,
      List params, {int limit, int offset}) {
    return statementQuery(buildSelectModelStatement(c.schema,
      sql, params, limit, offset))
        .then((rows) {
      var models = [];
      rows.forEach((row) => models.add(updateModelWithRow(row, c.nu)));
      return models;
    });
  }
  
  ar.Model updateModelWithRow(r, ar.Model empty) {
    r.forEach((String name, val) => empty[name] = val);
    return empty;
  }
  
  String getPostgresType(ar.VariableType v) {
    switch(v) {
      case ar.VariableType.BOOL:
        return "boolean";
      case ar.VariableType.INT:
        return "int8";
      case ar.VariableType.DOUBLE:
        return "float8";
      case ar.VariableType.STRING:
        return "varchar(255)";
      case ar.VariableType.DATETIME:
        return "timestamp";
      default:
        return "varchar(255)";
    }
  }
  
  String getPgConstraint(ar.Constraint c) {
    switch (c.name) {
      case "AUTO INCREMENT": return "SERIAL";
      default: return c.name;
    }
  }
  
  String getVariableForCreate(ar.Variable v) {
    if (v == ar.Variable.ID_FIELD) return "id serial PRIMARY KEY";
    var stmnt = "${v.name} ${getPostgresType(v.type)}";
    v.constraints.forEach((c) => stmnt += " ${getPgConstraint(c)}");
    return stmnt;
  }
  
  Statement buildCreateTableStatement(ar.Schema schema) {
    var lst = [];
    schema.variables.forEach((v) => lst.add(getVariableForCreate(v)));
    var st = "CREATE TABLE IF NOT EXISTS ${schema.tableName} (${lst.join(',')});";
    return new Statement()..sql = st;
  }
  
  Statement buildUpdateModelStatement(ar.Model m) {
    var schema = m.parent.schema;
    var upd = [];
    var s = new Statement();
    for (ar.Variable v in schema.variables) {
      if (v != ar.Variable.ID_FIELD && m[v.name] != null) {
        upd.add("${v.name}=@${v.name}");
        s.addValue(v.name, m[v.name]);
      }
    }
    s.addValue("id", m["id"]);
    s.sql = "UPDATE ${schema.tableName} SET ${upd.join(',')} WHERE id=@id;";
    return s;
  }
  
  Statement buildFindModelsByVariablesStatement(ar.Schema schema, 
    Map<ar.Variable, dynamic> variables, int limit, int offset) {
    var s = new Statement();
    var stub = "SELECT * FROM ${schema.tableName}";
    if (variables.length > 0) {
      var varStatements = [];
      var keys = variables.keys.toList(growable: false);
      for (int i = 0; i < keys.length; i++) {
        varStatements.add(keys[i].name + "=" + "@value${i+1}");
        s.addValue("value${i+1}", variables[keys[i]]);
      }
      stub += " WHERE " + varStatements.join(" AND ");
    }
    if (limit != null) stub += " LIMIT $limit";
    if (offset!= null) stub += " OFFSET $offset";
    return s..sql = stub;
  }
  
  Statement buildSelectModelStatement(ar.Schema schema, String sql, List args, int limit, int offset) {
    var s = new Statement();
    var stmnt = "SELECT * FROM ${schema.tableName} ";
    if (sql!= null && sql.length > 0) {
      stmnt += "WHERE ";
      var clauses = [];
      for (int i = 0; i < args.length; i++) {
        s.addValue("param${i+1}", args[i]);
      }
    }
    stmnt += replacePlaceholders(sql) + " ";
    if (limit != null) stmnt += "LIMIT $limit ";
    if (offset != null) stmnt += "OFFSET $offset";
    s.sql = stmnt + ";";
    return s;
  }
  
  String replacePlaceholders(String sql) {
    var num = 1;
    return sql.replaceAllMapped(new RegExp(r'\?'), (Match m) {
      var res = "@param$num";
      num++;
      return res;
    });
  }
  
  Statement buildDestroyModelStatement(ar.Model m) {
    var s = new Statement();
    s.sql = "DELETE FROM ${m.parent.schema.tableName} WHERE id = @id";
    s.addValue("id", m["id"]);
    return s;
  }
  
  Statement buildRemoveColumnStatement(String tableName, String variableName) {
    var s = new Statement();
    s..sql = "ALTER TABLE @tableName DROP COLUMN @variableName"
     ..addValue("tableName", tableName)
     ..addValue("variableName", variableName);
    return s;
  }
  
  Statement buildAddColumnStatement(String tableName, ar.Variable variable) {
    var s = new Statement();
    s.sql = "ALTER TABLE @tableName ADD COLUMN ${getVariableForCreate(variable)}";
    s.addValue("tableName", tableName);
    return s;
  }
  
  Statement buildDropTableStatement(String tableName) {
    return new Statement()
      ..sql = "DROP TABLE IF EXISTS @tableName"
      ..addValue("tableName", tableName);
  }
  
  Statement buildSaveModelStatement(ar.Model m) {
    var schema = m.parent.schema;
    var insertNames = [];
    var values = [];
    var s = new Statement();
    schema.variables.forEach((v) {
      if(m[v.name] != null) {
        insertNames.add(v.name);
        values.add("@${v.name}");
        s.addValue(v.name, m[v.name]);
      }
    });
    s.sql = "INSERT INTO ${schema.tableName} (${insertNames.join(',')}) "
      + "values (${values.join(',')}) RETURNING id;";
    return s;
  }
}

class Statement {
  Map<String, dynamic> _values = {};
  String _sql = "";
  
  addValue(String key, value) => _values[key] = value;
  forEachValue(f(String k, v)) => _values.forEach(f);
  set sql(String sql) => this._sql = sql;
  String get sql => this._sql;
  Map<String, dynamic> get values => this._values;
}