// test/local_queue_service_test.dart
// Tests for the legacy LocalQueueService (kept for backward-compatibility)
// and the new LocalQueueStorage used by Workshop 6.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/services/local_queue_service.dart';
import 'package:waiting_room_app/models/sync_status.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  // ── Legacy LocalQueueService tests (Workshop 4/5 compatibility) ──────────────

  group('LocalQueueService (legacy)', () {
    late LocalQueueService service;

    setUp(() {
      service = LocalQueueService(inMemory: true);
    });

    tearDown(() async {
      await service.close();
    });

    test('insertClientLocally adds a record to the database', () async {
      await service.insertClientLocally({
        'id': 'test-123',
        'name': 'Alice',
        'lat': 40.71,
        'lng': -74.00,
        'created_at': '2024-01-01T00:00:00Z',
        'is_synced': 0,
      });

      final clients = await service.getUnsyncedClients();
      expect(clients.length, 1);
      expect(clients[0]['name'], 'Alice');
      expect(clients[0]['id'], 'test-123');
    });

    test('getUnsyncedClients returns only unsynced records', () async {
      await service.insertClientLocally({
        'id': 'synced-1',
        'name': 'Bob',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T01:00:00Z',
        'is_synced': 1,
      });
      await service.insertClientLocally({
        'id': 'unsynced-1',
        'name': 'Charlie',
        'lat': 48.85,
        'lng': 2.35,
        'created_at': '2024-01-01T02:00:00Z',
        'is_synced': 0,
      });

      final unsynced = await service.getUnsyncedClients();
      expect(unsynced.length, 1);
      expect(unsynced[0]['name'], 'Charlie');
    });

    test('markClientAsSynced updates is_synced flag to 1', () async {
      await service.insertClientLocally({
        'id': 'mark-test',
        'name': 'Diana',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T03:00:00Z',
        'is_synced': 0,
      });

      await service.markClientAsSynced('mark-test');

      final unsynced = await service.getUnsyncedClients();
      expect(unsynced.isEmpty, true);

      final all = await service.getClients();
      expect(all.length, 1);
      expect(all[0]['is_synced'], 1);
    });

    test('getClients returns all records ordered by created_at', () async {
      await service.insertClientLocally({
        'id': 'c2',
        'name': 'Second',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-02T00:00:00Z',
        'is_synced': 0,
      });
      await service.insertClientLocally({
        'id': 'c1',
        'name': 'First',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T00:00:00Z',
        'is_synced': 0,
      });

      final clients = await service.getClients();
      expect(clients.length, 2);
      expect(clients[0]['name'], 'First');
      expect(clients[1]['name'], 'Second');
    });
  });

  // ── New LocalQueueStorage tests (Workshop 6) ─────────────────────────────────

  group('LocalQueueStorage (Workshop 6)', () {
    late LocalQueueStorage storage;

    setUp(() {
      storage = LocalQueueStorage(inMemory: true);
    });

    tearDown(() async {
      await storage.close();
    });

    test('saveClient stores record with sync_status', () async {
      await storage.saveClient({
        'id': 'w6-1',
        'name': 'Eve',
        'lat': 48.85,
        'lng': 2.35,
        'location_accuracy_m': 10.0,
        'created_at': '2024-01-01T00:00:00Z',
        'sync_status': 'pending',
      });

      final clients = await storage.getPendingClients();
      expect(clients.length, 1);
      expect(clients[0]['name'], 'Eve');
    });

    test('updateSyncStatus changes sync_status to synced', () async {
      await storage.saveClient({
        'id': 'w6-2',
        'name': 'Frank',
        'lat': null,
        'lng': null,
        'location_accuracy_m': null,
        'created_at': '2024-01-01T00:00:00Z',
        'sync_status': 'pending',
      });

      await storage.updateSyncStatus('w6-2', SyncStatus.synced);

      final pending = await storage.getPendingClients();
      expect(pending.isEmpty, isTrue);
    });
  });
}
