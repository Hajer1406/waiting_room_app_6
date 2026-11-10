import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/models/app_connectivity.dart';
import 'package:waiting_room_app/providers/connectivity_provider.dart';
import 'package:waiting_room_app/providers/queue_provider.dart';
import 'package:waiting_room_app/repositories/queue_repository.dart';
import 'package:waiting_room_app/services/connectivity_service.dart';
import 'package:waiting_room_app/services/geolocation_service.dart';
import 'package:waiting_room_app/storage/local_queue_storage.dart';

class _FakeGeoService extends GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

class _AlwaysOnlineConnectivityProvider extends ConnectivityProvider {
  _AlwaysOnlineConnectivityProvider()
      : super(ConnectivityService(null, useStub: true));

  @override
  AppConnectivity get status => AppConnectivity.online;

  @override
  bool get isOnline => true;

  @override
  Future<void> initialize() async {}
}

Widget _buildTestApp(QueueProvider queueProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => _AlwaysOnlineConnectivityProvider(),
      ),
      ChangeNotifierProvider<QueueProvider>.value(value: queueProvider),
    ],
    child: const WaitingRoomApp(),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

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

  Future<void> pumpUntil(WidgetTester tester, bool Function() condition,
      {int timeoutMs = 3000}) async {
    final sw = Stopwatch()..start();
    while (!condition() && sw.elapsedMilliseconds < timeoutMs) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('should add a new client to the list on button tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.isNotEmpty);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('Clients: 1'), findsOneWidget);
  });

  testWidgets(
      'should remove the first client from the list when "Next Client" is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(provider));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'Client A');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.length == 1);

    await tester.enterText(find.byType(TextField), 'Client B');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await pumpUntil(tester, () => provider.clients.length == 2);

    // "Client A" was added first → it's first in the FIFO queue
    expect(provider.clients.first.name, 'Client A');

    await tester.tap(find.byKey(const Key('nextClientButton')));
    await pumpUntil(tester, () => provider.clients.length == 1);

    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.textContaining('Clients: 1'), findsOneWidget);
  });
}
