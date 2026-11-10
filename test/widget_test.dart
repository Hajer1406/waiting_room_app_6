import 'package:flutter_test/flutter_test.dart';
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

/// Stub ConnectivityProvider that never touches the network
class _AlwaysOnlineConnectivityProvider extends ConnectivityProvider {
  _AlwaysOnlineConnectivityProvider()
      : super(ConnectivityService(null, useStub: true));

  @override
  AppConnectivity get status => AppConnectivity.online;

  @override
  bool get isOnline => true;

  @override
  Future<void> initialize() async {} // skip real checks in tests
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Waiting Room app launches successfully',
      (WidgetTester tester) async {
    final storage = LocalQueueStorage(inMemory: true);
    final repo = QueueRepository(supabase: null, storage: storage);
    final queueProvider = QueueProvider(repo, GeolocationService());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConnectivityProvider>(
            create: (_) => _AlwaysOnlineConnectivityProvider(),
          ),
          ChangeNotifierProvider<QueueProvider>.value(value: queueProvider),
        ],
        child: const WaitingRoomApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(WaitingRoomApp), findsOneWidget);

    queueProvider.dispose();
    await storage.close();
  });
}
