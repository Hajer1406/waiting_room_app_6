import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/sync_status.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/sync_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

class MockQueueRepository extends Mock implements QueueRepository {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(
      Client(
        id: 'fallback',
        name: 'Fallback',
        createdAt: DateTime.now(),
      ),
    );
  });

  group('SyncService Tests', () {
    late LocalQueueStorage storage;
    late MockQueueRepository mockRepository;
    late SyncService syncService;

    setUp(() {
      storage = LocalQueueStorage(inMemory: true);
      mockRepository = MockQueueRepository();
      syncService = SyncService(storage, mockRepository);
    });

    tearDown(() async {
      await storage.close();
    });

    test('synchronize successfully updates pending client to synced', () async {
      final client = Client(
        id: 'client-1',
        name: 'Sync Test',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await storage.saveClient(client.toLocalMap());
      when(() => mockRepository.registerOnServer(any())).thenAnswer((_) async {});

      await syncService.synchronize();

      verify(() => mockRepository.registerOnServer(any())).called(1);
      final clients = await storage.getClients();
      expect(clients.first['sync_status'], equals('synced'));
    });

    test('synchronize marks client as failed when repository throws', () async {
      final client = Client(
        id: 'client-fail',
        name: 'Fail Test',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await storage.saveClient(client.toLocalMap());
      when(() => mockRepository.registerOnServer(any())).thenThrow(Exception('Network error'));

      await syncService.synchronize();

      final clients = await storage.getClients();
      expect(clients.first['sync_status'], equals('failed'));
    });
  });
}

