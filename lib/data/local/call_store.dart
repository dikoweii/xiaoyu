import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../domain/call_ports.dart';
import 'database.dart' hide Character;
import 'repositories.dart';

class DriftCallStore implements CallPersistence {
  DriftCallStore(this.local);
  final LocalRepository local;
  AppDatabase get db => local.db;
  @override
  Future<void> begin(String callId, Character c, Credential credential) async =>
      db
          .into(db.calls)
          .insert(
            CallsCompanion.insert(
              id: callId,
              credentialId: credential.id,
              characterId: c.id,
              characterSnapshot: jsonEncode(c.toJson()),
              phase: 'creating',
              createdAt: DateTime.now().toUtc(),
            ),
          );
  @override
  Future<void> update(String callId, Json fields) async {
    await (db.update(db.calls)..where((t) => t.id.equals(callId))).write(
      CallsCompanion(
        liveId: fields.containsKey('liveId')
            ? Value(fields['liveId'] as String?)
            : const Value.absent(),
        phase: fields.containsKey('phase')
            ? Value(fields['phase'] as String)
            : const Value.absent(),
        endConfirmed: fields.containsKey('endConfirmed')
            ? Value(fields['endConfirmed'] as bool)
            : const Value.absent(),
        endReason: fields.containsKey('endReason')
            ? Value(fields['endReason'] as String?)
            : const Value.absent(),
        errorCode: fields.containsKey('error')
            ? Value(fields['error'] as String?)
            : const Value.absent(),
        controlReadyAt: fields.containsKey('readyAt')
            ? Value(fields['readyAt'] as DateTime?)
            : const Value.absent(),
        localReleasedAt: fields.containsKey('releasedAt')
            ? Value(fields['releasedAt'] as DateTime?)
            : const Value.absent(),
        billedSeconds: fields.containsKey('billedSeconds')
            ? Value(fields['billedSeconds'] as int?)
            : const Value.absent(),
        creditsCost: fields.containsKey('creditsCost')
            ? Value(fields['creditsCost'] as String?)
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> message(
    String callId,
    String id,
    String speaker,
    String text,
    String delivery,
  ) => local.addMessage(callId, id, speaker, text, delivery: delivery);
  @override
  Future<bool> hasUnresolved() async =>
      (await (db.select(db.calls)..where(
                (t) =>
                    t.endConfirmed.equals(false) &
                    t.phase.equals('failed').not(),
              ))
              .get())
          .isNotEmpty;
}
