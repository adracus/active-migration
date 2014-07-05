ActiveMigration
===============

## Finally, Migrations!
Migrations are a concept of getting your persistence layer into a consistent state.
Over the time you are developing your application, your persistence architecture
might change, additonal tables or columns might be added. Here, ActiveMigration comes
into play: ActiveMigration provides you an easy way to migrate your database, also
respecting different environments (development, production or any environment you
can think of).

### Migrating
For migration, this package comes with a built in tool: The migrator.dart-script.
This script enables you to simply migrate a single migration or a folder with
subfolders full of migrations. To get help about how to use the tool, simply type

```
dart migrator.dart -h
```
and the help for the tool will be displayed.
Usually, the tool takes three arguments:
+ The environment, in which the migration should happen
+ The location of the database.yml file
+ A single migration or a folder full of migrations

#### The environment
The environment specifies, which adapter and settings should be loaded from the
database.yml file.

#### The database.yml file
Here, you may specify your adapters and also connection parameters which are
needed in order to connect to your adapter. Here an example file:

```yaml
development:
  adapter: postgres
  username: dartman
  password: password
  host: localhost
  port: 5432
  database: dartbase
```

#### The migration file(s)
The last and most important point are the migration files. Migration
files have a standardized structure: First, there is a comment containing
the timestamp of when the migration was created in milliseconds.
Second, there has to be a class, which is also contained in the name
of the migration file. Then there are the migration up- and down methods,
up for if the migration should be done and down if it should be undone.
In order to be able to create migration files easily, ActiveMigration
comes with another tool: The ActiveMigration `generator.dart`.

### Generating
Migrations can be easily generated with the `generator.dart` script.
This script needs one or two arguments:
+ Name of the Migration
+ Location of the Migration, optional

This generates the Migration with the specified name at the
specified location. If no location was specified, the Migration will
be created at the place from where you ran the generator script.