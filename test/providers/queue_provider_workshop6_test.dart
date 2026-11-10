import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/queue_state.dart';
import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';

class MockQueueRepository extends Mock implements QueueRepository {}
class MockGeolocationService extends Mock implements GeolocationService {}

void main() {
  late MockQueueRepository mockRepository;
  late MockGeolocationService mockGeo;
  late QueueProvider provider;

  setUp(() {
    mockRepository = MockQueueRepository();
    mockGeo = MockGeolocationService();
    provider = QueueProvider(mockRepository, mockGeo);
  });

  group('QueueProvider Pagination & Realtime Tests', () {
    test('fetchInitialQueue loads items and sets state to loaded', () async {
      final mockClients = [
        Client(id: '1', name: 'Alice', createdAt: DateTime.now()),
        Client(id: '2', name: 'Bob', createdAt: DateTime.now()),
      ];
      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => mockClients);

      await provider.fetchInitialQueue();

      expect(provider.state, equals(QueueState.loaded));
      expect(provider.clients.length, equals(2));
      expect(provider.hasMore, isFalse);
    });

    test('fetchInitialQueue sets state to empty when 0 clients returned', () async {
      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => []);

      await provider.fetchInitialQueue();

      expect(provider.state, equals(QueueState.empty));
      expect(provider.clients.isEmpty, isTrue);
    });

    test('handleRealtimeInsert adds client without duplicates', () {
      final client = Client(id: '1', name: 'Alice', createdAt: DateTime.now());

      provider.handleRealtimeInsert(client);
      expect(provider.clients.length, equals(1));

      // Attempt duplicate insert
      provider.handleRealtimeInsert(client);
      expect(provider.clients.length, equals(1));
    });

    test('loadMore appends unique items to client list', () async {
      final page2 = [
        Client(id: 'unique-21', name: 'Client 21', createdAt: DateTime.now()),
      ];

      when(() => mockRepository.fetchPage(offset: 0, limit: 20))
          .thenAnswer((_) async => List.generate(20, (i) => Client(id: '$i', name: 'C$i', createdAt: DateTime.now())));
      when(() => mockRepository.fetchPage(offset: 20, limit: 20))
          .thenAnswer((_) async => page2);

      await provider.fetchInitialQueue();
      expect(provider.clients.length, equals(20));

      await provider.loadMore();
      expect(provider.clients.length, equals(21));
    });
  });
}

