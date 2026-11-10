import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/connectivity_provider.dart';
import 'providers/queue_provider.dart';
import 'repositories/queue_repository.dart';
import 'screens/queue_screen.dart';
import 'services/connectivity_service.dart';
import 'services/geolocation_service.dart';
import 'services/sync_service.dart';
import 'storage/local_queue_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  SupabaseClient? supabaseClient;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      supabaseClient = Supabase.instance.client;

      // Attempt anonymous sign-in in the background
      supabaseClient.auth.signInAnonymously().catchError((_) => null);
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  final localStorage = LocalQueueStorage();
  final queueRepository = QueueRepository(
    supabase: supabaseClient,
    storage: localStorage,
  );
  final geoService = GeolocationService();
  final syncService = SyncService(localStorage, queueRepository);

  final clientForConnectivity = supabaseClient;
  final connectivityService = ConnectivityService(clientForConnectivity);

  runApp(
    MultiProvider(
      providers: [
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(connectivityService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueProvider(queueRepository, geoService),
        ),
      ],
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QueueScreen(),
    );
  }
}
