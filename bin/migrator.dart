import '../lib/activemigration.dart';
import 'dart:io';

void main(List<String> arguments) {
  print(arguments);
  
  var configs = (parseDatabaseFile(new File(arguments[0])));
  print(configs[0].adapter);
}