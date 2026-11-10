import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

  late LocalQueueStorage storage;
  late QueueProvider manager;

  setUp(() {
    storage = LocalQueueStorage(inMemory: true);
    final repo = QueueRepository(supabase: null, storage: storage);
    manager = QueueProvider(repo, _FakeGeoService());
  });

  tearDown(() async {
    manager.dispose();
    await storage.close();
  });

  test('should add a client to the waiting list', () async {
    await manager.addClient('John Doe');

    expect(manager.clients.length, 1);
    expect(manager.clients.first.name, 'John Doe');
  });

  test('should remove a client from the waiting list', () async {
    await manager.addClient('John Doe');
    await manager.addClient('Jane Doe');
    final johnId = manager.clients.first.id;

    await manager.removeClient(johnId);

    expect(manager.clients.length, 1);
    expect(manager.clients.first.name, 'Jane Doe');
  });

  test('should remove the first client when nextClient() is called', () async {
    await manager.addClient('Client A');
    await manager.addClient('Client B');

    await manager.nextClient();

    expect(manager.clients.length, 1);
    expect(manager.clients.first.name, 'Client B');
  });
}
