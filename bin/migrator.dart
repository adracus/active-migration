import '../lib/activemigration.dart';
import 'dart:io';

void main(List<String> arguments) {
  print(arguments);
  
  print(parseDatabaseFile(new File(arguments[0])));
}