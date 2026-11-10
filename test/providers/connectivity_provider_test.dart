import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/models/app_connectivity.dart';
import 'package:waiting_room_app/providers/connectivity_provider.dart';
import 'package:waiting_room_app/services/connectivity_service.dart';

class MockConnectivity extends Mock implements Connectivity {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('ConnectivityProvider Tests', () {
    late MockConnectivityService mockService;
    late StreamController<bool> controller;
    late ConnectivityProvider provider;

    setUp(() {
      mockService = MockConnectivityService();
      controller = StreamController<bool>.broadcast();
      when(() => mockService.networkChanges).thenAnswer((_) => controller.stream);
      when(() => mockService.hasNetwork()).thenAnswer((_) async => true);
      when(() => mockService.isSupabaseAvailable()).thenAnswer((_) async => true);
      provider = ConnectivityProvider(mockService);
    });

    tearDown(() {
      provider.dispose();
      controller.close();
    });

    test('initial state is checking', () {
      expect(provider.status, equals(AppConnectivity.checking));
    });

    test('status changes to offline when no network', () async {
      await provider.initialize();
      controller.add(false);
      // Wait for synchronous microtask
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.status, equals(AppConnectivity.offline));
    });

    test('status changes to online after debounce when backend is available', () async {
      await provider.initialize();
      controller.add(true);
      // Debounce is 700ms in ConnectivityProvider
      await Future.delayed(const Duration(milliseconds: 800));
      expect(provider.status, equals(AppConnectivity.online));
    });
  });
}

