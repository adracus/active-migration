//MyAwsumMigration
import "dart:async";
import "package:activerecord/activerecord.dart";
import "package:activemigration/activemigration.dart";
class MyAwsumMigration extends Migration {
  MyAwsumMigration(DatabaseAdapter adapter): super(adapter);
  Future up() => new Future.sync(() => print("diddlydoo"));
  Future down() => null;
}
