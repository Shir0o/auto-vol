import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/screens/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVolumeRulesNotifier extends AsyncNotifier<List<VolumeRule>> with Mock implements VolumeRulesNotifier {}

void main() {
  late MockVolumeRulesNotifier mockNotifier;

  setUp(() {
    mockNotifier = MockVolumeRulesNotifier();
    registerFallbackValue(VolumeRule(
      id: '1',
      calendarId: 'primary',
      eventTitlePattern: 'Test',
      volumeLevel: 0.5,
      priority: 0,
    ));
  });

  Widget createRulesScreen(AsyncValue<List<VolumeRule>> state) {
    return ProviderScope(
      overrides: [
        volumeRulesProvider.overrideWith(() => mockNotifier),
      ],
      child: MaterialApp(
        home: const RulesScreen(),
      ),
    );
  }

  group('RulesScreen', () {
    testWidgets('should display rules when loaded', (tester) async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'primary',
        eventTitlePattern: 'Meeting',
        volumeLevel: 0.0,
        priority: 1,
      );

      when(() => mockNotifier.build()).thenAnswer((_) async => [rule]);

      await tester.pumpWidget(createRulesScreen(AsyncData([rule])));
      await tester.pumpAndSettle();

      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Muted'), findsOneWidget);
    });

    testWidgets('should show empty state when no rules', (tester) async {
      when(() => mockNotifier.build()).thenAnswer((_) async => []);

      await tester.pumpWidget(createRulesScreen(const AsyncData([])));
      await tester.pumpAndSettle();

      expect(find.text('No rules defined'), findsOneWidget);
    });
  });
}
