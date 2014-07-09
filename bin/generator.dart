import "dart:io";
import "dart:async" show Future;
import "package:args/args.dart";

final parser = new ArgParser(allowTrailingOptions: true);

main(List<String> args) {
  parser.addFlag("help", abbr: "h", help: "Prints this help", callback: _help);
  var res = parser.parse(args);
  if(res.rest.length > 0) {
    if(res.rest.length == 1) return _generateMigration(res.rest[0]);
    return _generateMigration(res.rest[0], res.rest[1]);
  }
}

Future<File> _generateMigration(String name, [String loc]) {
  var now = new DateTime.now().millisecondsSinceEpoch.toString();
  var path = loc == null ? "$now\_$name.dart" : "$loc/$now\_$name.dart";
  var f = new File(path);
  var sink = f.openWrite();
  sink.writeln("//$name");
  sink.writeln('import "dart:async";');
  sink.writeln('import "package:activerecord/activerecord.dart";');
  sink.writeln('import "package:activemigration/activemigration.dart";');
  sink.writeln("class $name extends Migration {");
  sink.writeln("  $name(DatabaseAdapter adapter): super(adapter);");
  sink.writeln("  Future up() => null;");
  sink.writeln("  Future down() => null;");
  sink.writeln("}");
  return sink.flush().then((_) => f);
}

_help(bool arg) {
  if(arg) print("Dart Migration generator:\n"
      + "dart generator.dart (1) [(2)]\n"
      + "(1): Name of the migration\n"
      + "(2): Location of the migration, optional\n\n"
      + parser.getUsage());
}