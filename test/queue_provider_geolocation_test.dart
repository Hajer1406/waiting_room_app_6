import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

// Hand-written mock (equivalent to @GenerateMocks([GeolocationService]))
class MockGeolocationService extends Mock implements GeolocationService {
  @override
  Future<Position?> getCurrentPosition() =>
      super.noSuchMethod(
        Invocation.method(#getCurrentPosition, []),
        returnValue: Future<Position?>.value(null),
        returnValueForMissingStub: Future<Position?>.value(null),
      ) as Future<Position?>;
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  late MockGeolocationService mockGeo;
  late LocalQueueStorage storage;
  late QueueProvider provider;

  setUp(() {
    mockGeo = MockGeolocationService();
    storage = LocalQueueStorage(inMemory: true);
    final repo = QueueRepository(supabase: null, storage: storage);
    provider = QueueProvider(repo, mockGeo);
  });

  tearDown(() async {
    provider.dispose();
    await storage.close();
  });

  test('addClient saves client with geolocation when permission granted',
      () async {
    final mockPosition = Position(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => mockPosition);

    await provider.addClient('Test User');

    expect(provider.clients.length, 1);
    expect(provider.clients.last.name, 'Test User');
    expect(provider.clients.last.lat, 37.7749);
    expect(provider.clients.last.lng, -122.4194);
  });

  test('addClient saves client with null location when permission denied',
      () async {
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => null);

    await provider.addClient('No Location User');

    expect(provider.clients.length, 1);
    expect(provider.clients.last.name, 'No Location User');
    expect(provider.clients.last.lat, isNull);
    expect(provider.clients.last.lng, isNull);
  });

  test('addClient rejects empty name', () async {
    final error = await provider.addClient('   ');

    expect(error, isNotNull);
    expect(error, 'Client name cannot be empty');
    expect(provider.clients.isEmpty, true);
  });

  test('addClient stores record locally as pending', () async {
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => null);

    await provider.addClient('Offline User');

    final pending = await storage.getPendingClients();
    expect(pending.length, 1);
    expect(pending[0]['name'], 'Offline User');
    expect(pending[0]['sync_status'], 'pending');
  });

  test('removeClient removes from local list', () async {
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => null);
    await provider.addClient('To Remove');

    expect(provider.clients.length, 1);
    final clientId = provider.clients.first.id;

    await provider.removeClient(clientId);

    expect(provider.clients.isEmpty, true);
  });

  test('nextClient removes first client in queue', () async {
    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => null);
    await provider.addClient('First');
    await provider.addClient('Second');

    expect(provider.clients.length, 2);
    expect(provider.clients.first.name, 'First');

    await provider.nextClient();

    expect(provider.clients.length, 1);
    expect(provider.clients.first.name, 'Second');
  });
}
