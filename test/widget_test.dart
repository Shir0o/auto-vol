import 'package:auto_vol/core/providers/common_providers.dart';
import 'package:auto_vol/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AuraApp renders MainScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AuraApp(),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    expect(find.text('Aura'), findsWidgets); // Found multiple times (header and body)
    expect(find.text('Sync Status'), findsOneWidget);
  });
}
