import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/app_connectivity.dart';
import 'package:waiting_room_app/widgets/offline_banner.dart';

void main() {
  testWidgets('Offline banner is displayed when offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflineBanner(status: AppConnectivity.offline),
        ),
      ),
    );
    expect(find.text('No network connection'), findsOneWidget);
  });

  testWidgets('Offline banner is hidden when online', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflineBanner(status: AppConnectivity.online),
        ),
      ),
    );
    expect(find.byType(OfflineBanner), findsOneWidget);
    expect(find.text('No network connection'), findsNothing);
  });

  testWidgets('Offline banner displays backend unavailable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflineBanner(status: AppConnectivity.backendUnavailable),
        ),
      ),
    );
    expect(find.text('Waiting-room server unavailable'), findsOneWidget);
  });
}

