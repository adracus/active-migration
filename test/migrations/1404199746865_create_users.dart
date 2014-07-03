//MyMigration
import 'package:activemigration/activemigration.dart';
import 'dart:async';

class MyMigration extends Migration {
  up(DatabaseAdapter adapter) => new Future.microtask(() => print("Yehaaa, I was migrated :D"));
  down(DatabaseAdapter adapter) => null;
}