import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/models/sync_status.dart';

void main() {
  group('Client Model Tests', () {
    test('client without location reports hasLocation as false', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        createdAt: DateTime.now(),
      );
      expect(client.hasLocation, isFalse);
      expect(client.locationText, equals('Location not captured'));
    });

    test('toLocalMap preserves accuracy and syncStatus', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        lat: 36.8065,
        lng: 10.1815,
        locationAccuracy: 5.5,
        createdAt: DateTime(2026, 1, 1),
        syncStatus: SyncStatus.pending,
      );
      final map = client.toLocalMap();
      expect(map['location_accuracy_m'], equals(5.5));
      expect(map['sync_status'], equals('pending'));
    });

    test('toSupabaseMap excludes local sync_status', () {
      final client = Client(
        id: '1',
        name: 'Test Client',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      final map = client.toSupabaseMap();
      expect(map.containsKey('sync_status'), isFalse);
    });
  });
}

