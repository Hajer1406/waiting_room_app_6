import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';
import 'package:waiting_room_app/services/local_queue_service.dart';

class _FakeGeoService extends GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocalQueueService localDb;
  late QueueProvider provider;

  setUp(() {
    localDb = LocalQueueService(inMemory: true);
    provider = QueueProvider.withDependencies(
      supabaseClient: null,
      geoService: _FakeGeoService(),
      localDb: localDb,
    );
  });

  tearDown(() async {
    provider.dispose();
    await localDb.close();
  });

  Future<void> pumpUntil(WidgetTester tester, bool Function() condition,
      {int timeoutMs = 3000}) async {
    final stopWatch = Stopwatch()..start();
    while (!condition() && stopWatch.elapsedMilliseconds < timeoutMs) {
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('should add a new client to the list on button tap',
      (WidgetTester tester) async {
    // ARRANGE
    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const WaitingRoomApp(),
      ),
    );
    await pumpUntil(tester, () => true, timeoutMs: 100);

    // ACT
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.isNotEmpty);

    // ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets(
      'should remove a client from the list when the delete button is tapped',
      (WidgetTester tester) async {
    // ARRANGE
    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const WaitingRoomApp(),
      ),
    );
    await pumpUntil(tester, () => true, timeoutMs: 100);

    await tester.enterText(find.byType(TextField), 'Bob');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.isNotEmpty);

    expect(find.text('Bob'), findsOneWidget);

    // ACT
    await tester.tap(find.byIcon(Icons.delete));
    await pumpUntil(tester, () => provider.clients.isEmpty);

    // ASSERT
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Clients in Queue: 0'), findsOneWidget);
  });

  testWidgets(
      'should remove the first client from the list when "Next Client" is tapped',
      (WidgetTester tester) async {
    // ARRANGE
    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const WaitingRoomApp(),
      ),
    );
    await pumpUntil(tester, () => true, timeoutMs: 100);

    // Add two clients to the list first
    await tester.enterText(find.byType(TextField), 'Client A');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.length == 1);

    await tester.enterText(find.byType(TextField), 'Client B');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.length == 2);

    // ACT
    await tester.tap(find.byKey(const Key('nextClientButton')));
    await pumpUntil(tester, () => provider.clients.length == 1);

    // ASSERT
    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });
}
