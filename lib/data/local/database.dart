import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get credentialId => text()();
  TextColumn get name => text()();
  TextColumn get config => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Calls extends Table {
  TextColumn get id => text()();
  TextColumn get credentialId => text()();
  TextColumn get characterId => text()();
  TextColumn get characterSnapshot => text()();
  TextColumn get liveId => text().nullable()();
  TextColumn get phase => text()();
  BoolColumn get endConfirmed => boolean().withDefault(const Constant(false))();
  TextColumn get endReason => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get controlReadyAt => dateTime().nullable()();
  DateTimeColumn get localReleasedAt => dateTime().nullable()();
  IntColumn get billedSeconds => integer().nullable()();
  TextColumn get creditsCost => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {credentialId, liveId},
  ];
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get callId => text().references(Calls, #id)();
  TextColumn get speaker => text()();
  TextColumn get content => text()();
  TextColumn get delivery => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Settings, Characters, Calls, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'xiaoyu'));
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}
