import '../lib/activemigration.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) {
  var parser = new ArgParser();
  parser.addOption("since", abbr: "s");
  var result = parser.parse(arguments);
  print(result.rest);
  var since = result["since"] == null? null : new File(result["since"]);
  createMigrator(result.rest[0], since, new File(result.rest[1]), 
      findMigrationFiles(new File(result.rest[2]))).then((file) {
    Process.run("dart", [file.absolute.path]).then((result) {
      print(result.stdout);
      print(result.stderr);
      file.delete().then((_) => result.stderr == "" ?
          print("Migration successfull") : print("Migration failed"));
    });
  });
}