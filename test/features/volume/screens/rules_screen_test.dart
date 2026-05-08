import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/screens/rules_screen.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/volume/repositories/volume_rules_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVolumeRulesRepository extends Mock implements VolumeRulesRepository {}

void main() {
  late MockVolumeRulesRepository mockRepository;
  late SharedPreferences prefs;

  setUp(() async {
    mockRepository = MockVolumeRulesRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    registerFallbackValue(
      VolumeRule(
        id: '1',
        calendarId: 'primary',
        eventTitlePattern: 'Test',
        volumeLevel: 0.5,
        priority: 0,
      ),
    );
  });

  Widget createRulesScreen() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        availableCalendarsProvider.overrideWith((ref) async => [
          CalendarEntry(id: 'primary', title: 'Primary', isPrimary: true),
        ]),
        volumeRulesRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(home: RulesScreen()),
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

      when(() => mockRepository.loadRules()).thenAnswer((_) async => [rule]);

      await tester.pumpWidget(createRulesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Muted'), findsOneWidget);
    });

    testWidgets('should show empty state when no rules', (tester) async {
      when(() => mockRepository.loadRules()).thenAnswer((_) async => []);

      await tester.pumpWidget(createRulesScreen());
      await tester.pumpAndSettle();

      expect(find.text('No rules defined'), findsOneWidget);
    });

    testWidgets('should call updateRule when a rule is edited', (tester) async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'primary',
        eventTitlePattern: 'Meeting',
        volumeLevel: 0.0,
        priority: 1,
      );

      when(() => mockRepository.loadRules()).thenAnswer((_) async => [rule]);
      when(() => mockRepository.saveRules(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createRulesScreen());
      await tester.pumpAndSettle();

      // Tap on the rule to edit
      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Rule'), findsOneWidget);

      // Change priority
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.add),
      ));
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.saveRules(any(
            that: contains(isA<VolumeRule>().having((r) => r.priority, 'priority', 2)),
          ))).called(1);
    });

    testWidgets('should call addRule when a new rule is added', (tester) async {
      when(() => mockRepository.loadRules()).thenAnswer((_) async => []);
      when(() => mockRepository.saveRules(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createRulesScreen());
      await tester.pumpAndSettle();

      // Tap FAB to add
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Rule'), findsOneWidget);

      // Enter keyword
      await tester.enterText(find.byType(TextField), 'Workout');
      await tester.pumpAndSettle();

      // Tap Add
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.saveRules(any(
            that: contains(isA<VolumeRule>().having((r) => r.eventTitlePattern, 'pattern', 'Workout')),
          ))).called(1);
    });
  });
}
