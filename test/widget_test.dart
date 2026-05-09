import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kiezlink_app/main.dart';
import 'package:kiezlink_app/data/news_provider.dart';

void main() {
  group('Kiezlink App Tests', () {
    testWidgets('App initializes and shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const KiezlinkApp());
      await tester.pump();

      // Verify app title
      expect(find.text('Kiezlink'), findsWidgets);

      // Verify search icon exists
      expect(find.byIcon(Icons.search), findsWidgets);

      // Verify menu icon exists
      expect(find.byIcon(Icons.menu), findsWidgets);
    });

    testWidgets('Search bar can be toggled', (WidgetTester tester) async {
      await tester.pumpWidget(const KiezlinkApp());
      await tester.pumpAndSettle();

      // Search should not be visible initially
      expect(find.byType(TextField), findsNothing);

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search bar should now be visible
      expect(find.byType(TextField), findsOneWidget);

      // Verify search hint text
      expect(find.text('Search news...'), findsOneWidget);
    });

    testWidgets('Side menu opens when menu button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(const KiezlinkApp());
      await tester.pumpAndSettle();

      // Menu should not be visible initially
      expect(find.text('Berliner Leser'), findsNothing);

      // Tap menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Menu should now be visible
      expect(find.text('Berliner Leser'), findsOneWidget);
      expect(find.text('My Feed'), findsOneWidget);
      expect(find.text('Trending Now'), findsOneWidget);
    });

    testWidgets('Error message displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const KiezlinkApp());
      
      // Wait for loading to complete (will show error due to no API)
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Should show error UI
      expect(find.byIcon(Icons.wifi_off_rounded), findsWidgets);
      expect(find.text('Could not load news'), findsWidgets);
    });
  });
}
