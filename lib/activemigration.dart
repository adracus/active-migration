library activemigration;

import 'dart:async';
import 'dart:io';

import 'package:postgres_adapter/postgres_adapter.dart';
import 'package:activerecord/activerecord.dart';
import 'package:yaml/yaml.dart';

const lookup = const {
  "postgres": PostgresAdapter
};

abstract class Migration {
  final DatabaseAdapter adapter;
  Migration(this.adapter);
  Future up();
  Future down();
}

List<Configuration> parseDatabaseFile(File file) {
  var doc = loadYaml(file.readAsStringSync());
  return doc.keys.
      map((key) => new Configuration(key, doc[key])).toList();
}

class Configuration {
  final String environment;
  var _doc;
  
  Configuration(this.environment, this._doc);
  operator[](String key) => _doc[key];
  String get adapterName => _doc["adapter"];
  toString() => "$environment: configs: $_doc";
}