import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

class _FakeGeoService extends GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Client Model Tests', () {
    test('Client.fromMap should correctly deserialize map data', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-uuid-1234',
        'name': 'Alice',
        'created_at': now.toIso8601String(),
      };

      final client = Client.fromMap(map);

      expect(client.id, 'test-uuid-1234');
      expect(client.name, 'Alice');
      expect(client.createdAt.toIso8601String(), now.toIso8601String());
    });

    test('Client.toMap should correctly serialize client data', () {
      final now = DateTime.now();
      final client = Client(
        id: 'uuid-5678',
        name: 'Bob',
        createdAt: now,
      );

      final map = client.toMap();

      expect(map['id'], 'uuid-5678');
      expect(map['name'], 'Bob');
      expect(map['created_at'], now.toIso8601String());
    });

    test('Client equality should work by id', () {
      final now = DateTime.now();
      final client1 = Client(id: 'id-1', name: 'Alice', createdAt: now);
      final client2 = Client(id: 'id-1', name: 'Alice', createdAt: now);
      final client3 = Client(id: 'id-2', name: 'Alice', createdAt: now);

      expect(client1, equals(client2));
      expect(client1, isNot(equals(client3)));
    });
  });

  group('QueueProvider Local & Unit Tests', () {
    late LocalQueueStorage storage;
    late QueueProvider provider;

    setUp(() {
      storage = LocalQueueStorage(inMemory: true);
      final repo = QueueRepository(supabase: null, storage: storage);
      provider = QueueProvider(repo, _FakeGeoService());
    });

    tearDown(() async {
      provider.dispose();
      await storage.close();
    });

    test('should add a client to the queue', () async {
      await provider.addClient('Alice');

      expect(provider.clients.length, 1);
      expect(provider.clients.first.name, 'Alice');
    });

    test('should not add client with empty or whitespace name', () async {
      await provider.addClient('   ');
      await provider.addClient('');

      expect(provider.clients.isEmpty, isTrue);
    });

    test('should remove a client by id', () async {
      await provider.addClient('Alice');
      await provider.addClient('Bob');
      final firstId = provider.clients.first.id;

      await provider.removeClient(firstId);

      expect(provider.clients.length, 1);
      expect(provider.clients.first.name, 'Bob');
    });

    test('should remove the first client when nextClient() is called', () async {
      await provider.addClient('Client A');
      await provider.addClient('Client B');

      await provider.nextClient();

      expect(provider.clients.length, 1);
      expect(provider.clients.first.name, 'Client B');
    });

    test('should handle nextClient() gracefully on empty queue', () async {
      expect(provider.clients.isEmpty, isTrue);
      await provider.nextClient();
      expect(provider.clients.isEmpty, isTrue);
    });
  });
}
