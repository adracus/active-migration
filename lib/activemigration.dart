library activemigration;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:activerecord/activerecord.dart';
import 'adapters/postgres_adapter.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart';
import 'package:codewriter/codewriter.dart';

export 'adapters/postgres_adapter.dart';

part 'database_adapter.dart';

const lookup = const {
  "postgres": PostgresAdapter
};

Future<File> createMigrator(String env, File fromFile,
    File configFile, List<MigrationFile> migrationFiles) {
  var from = readTimestampFile(fromFile);
  var file = new StandardFile("migrator_tmp.dart");
  file.addImport(new Import("io"));
  file.addImport(new Import("async", show: ["Future"]));
  file.addImport(new Import("activemigration/activemigration.dart", namespace: "package"));
  migrationFiles.forEach((mFile) => file.addImport(mFile.import));
  var main = new NamedFunc("main");
  main.addExpression(
        new UserExpression('var config = '
            + 'parseDatabaseFile(new File("${configFile.absolute.path}"))["$env"];'));
  main.addExpression(new UserExpression("var fs = [];"));
  for(int i = 0; i < migrationFiles.length; i++) {
    if (from != null && migrationFiles[i].timestamp.isBefore(from)) break;
    main.addExpression(
        new UserExpression("var mig$i = new " +
            "${migrationFiles[i].className}();"));
    main.addExpression(new UserExpression("fs.add(mig$i.up(config.adapter));"));
  }
  writeMigrationTimestamp(fromFile, new DateTime.now());
  main.addExpression(
      new UserExpression("Future.wait(fs).then((_) => print('done'));"));
  file.addContent(main);
  return file.writeToFile().then((f) => f);
}

DateTime getYounger(DateTime dt1, DateTime dt2) {
  if(dt1.compareTo(dt2) <= 0) return dt1;
  return dt2;
}

DateTime readTimestampFile(File f) {
  if(f == null) return null;
  if(FileSystemEntity.isDirectorySync(f.path)) throw "File needed, not directory";
  var lines = f.readAsLinesSync();
  if(lines.length == 0) return null;
  try {
    int milliSecs = int.parse(lines[0]);
    return new DateTime.fromMillisecondsSinceEpoch(milliSecs);
  } on FormatException catch (e) {
    return null;
  }
}

abstract class Migration {
  Future up(DatabaseAdapter adapter);
  Future down(DatabaseAdapter adapter);
}

String parseMigrationClass(File migrationFile) {
  return migrationFile.readAsLinesSync().first.replaceAll("//", "").trim();
}

DateTime parseMigrationTimestamp(File migrationFile) {
  int msecs = int.parse(basename(migrationFile.path).split("_").first.trim());
  return new DateTime.fromMillisecondsSinceEpoch(msecs);
}

void writeMigrationTimestamp(File timestampFile, DateTime time) {
  if(timestampFile == null) return;
  if(time == null) time = new DateTime.now();
  var sink = timestampFile.openWrite();
  sink
    ..writeln(time.millisecondsSinceEpoch)
    ..flush().whenComplete(() => sink.close());
}

Map<String, AdapterConfiguration> parseDatabaseFile(File file) {
  var doc = loadYaml(file.readAsStringSync());
  var result = {};
  doc.keys.forEach((key) =>
      result[key] = new AdapterConfiguration(key, doc[key]));
  return result;
}

List<MigrationFile> findMigrationFiles(FileSystemEntity root) {
  if(FileSystemEntity.isFileSync(root.path)) {
    if (isMigrationFile(root)) return [new MigrationFile(root)];
    else return [];
  }
  return new Directory(root.path).listSync(recursive: true).where((entity) =>
      isMigrationFile(entity)).map((ent) => new MigrationFile(ent as File))
          .toList();
}

bool isMigrationFile(FileSystemEntity entity) {
  return FileSystemEntity.isFileSync(entity.path) && entity.path.endsWith(".dart")
      && entity.path.contains("_") && new RegExp(r"[0-9]+").hasMatch(entity.path)
        && (new RegExp(r"[0-9]+").firstMatch(entity.path.split("_")[0]).end
            == entity.path.split("_")[0].length);
}

class AdapterConfiguration {
  final String environment;
  var _doc;
  
  AdapterConfiguration(this.environment, this._doc);
  operator[](String key) => _doc[key];
  String get adapterName => _doc["adapter"];
  toString() => "$environment: configs: $_doc";
  DatabaseAdapter get adapter {
    final clazz = reflectClass(lookup[adapterName.toLowerCase()]);
    return clazz.newInstance(new Symbol(""), [this]).reflectee;
  }
}

class MigrationFile {
  final String className;
  final DateTime timestamp;
  final File file;
  
  MigrationFile(File f) :
    file = f,
    timestamp = new DateTime.fromMillisecondsSinceEpoch(
        int.parse(basename(f.path).split("_").first.trim())),
    className = f.readAsLinesSync().first.replaceAll("//", "").trim();
  
  Import get import => new Import.raw(file.absolute.path);
}