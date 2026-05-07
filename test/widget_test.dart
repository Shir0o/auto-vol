import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('VocusApp renders MainScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const VocusApp(),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    expect(find.text('Vocus'), findsWidgets); // Found multiple times (header and body)
    expect(find.text('Sync Status'), findsOneWidget);
  });
}
