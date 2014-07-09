import '../lib/activemigration.dart';
import 'package:args/args.dart';
import 'dart:io';

final parser = new ArgParser(allowTrailingOptions: true);

void main(List<String> arguments) {
  parser.addOption("since", abbr: "s", help: "File, which contains " +
      "timestamp from when migration should start");
  parser.addFlag("help", abbr: "h", help: "Prints this help",
      negatable: false, callback: _help);
  var result = parser.parse(arguments);
  
  if(result.rest.length == 3) {
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
}

void _help(bool value) {
  if(value) print("Dart Migration Tool:\n"
      + "dart migrator.dart [-s (s)] (1) (2) (3)\n"
      + "-s (s): Specify a file which specifies a timestamp\n"
      + "(1): Specify the migration environment\n"
      + "(2): Specify the database.yml file\n"
      + "(3): Specify a folder of or a single migration file\n\n"
      + "Example:\n"
      + "dart migrator.dart -s since.txt development database.yml migrations\n\n"
      + parser.getUsage());
}