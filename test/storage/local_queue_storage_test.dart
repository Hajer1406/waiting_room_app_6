import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/sync_status.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalQueueStorage Tests', () {
    late LocalQueueStorage storage;

    setUp(() {
      storage = LocalQueueStorage(inMemory: true);
    });

    tearDown(() async {
      await storage.close();
    });

    test('saveClient and getClients', () async {
      final client = Client(
        id: 'c1',
        name: 'Alice',
        lat: 36.8,
        lng: 10.1,
        locationAccuracy: 12.0,
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await storage.saveClient(client.toLocalMap());
      final records = await storage.getClients();

      expect(records.length, 1);
      expect(records.first['name'], 'Alice');
      expect(records.first['sync_status'], 'pending');
    });

    test('getPendingClients returns pending and failed', () async {
      final c1 = Client(
        id: 'c1',
        name: 'Pending Client',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      final c2 = Client(
        id: 'c2',
        name: 'Failed Client',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.failed,
      );
      final c3 = Client(
        id: 'c3',
        name: 'Synced Client',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      await storage.saveClient(c1.toLocalMap());
      await storage.saveClient(c2.toLocalMap());
      await storage.saveClient(c3.toLocalMap());

      final pending = await storage.getPendingClients();
      expect(pending.length, 2);
      expect(pending.map((p) => p['name']), containsAll(['Pending Client', 'Failed Client']));
    });

    test('updateSyncStatus changes status in database', () async {
      final client = Client(
        id: 'c1',
        name: 'Alice',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await storage.saveClient(client.toLocalMap());
      await storage.updateSyncStatus('c1', SyncStatus.synced);

      final records = await storage.getClients();
      expect(records.first['sync_status'], 'synced');
    });
  });
}

