import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:vocus/features/settings/screens/settings_screen.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockForegroundService extends Mock implements ForegroundServiceWrapper {}

void main() {
  late MockForegroundService mockForegroundService;

  setUp(() {
    mockForegroundService = MockForegroundService();
    when(() => mockForegroundService.start()).thenAnswer((_) async => true);
    when(() => mockForegroundService.stop()).thenAnswer((_) async => true);
  });

  testWidgets(
    'SettingsScreen displays available calendars and allows toggling',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockUser = MockGoogleSignInAccount();
      when(() => mockUser.email).thenReturn('test@example.com');

      final mockRepository = MockCalendarRepository();
      final calendars = [
        CalendarEntry(id: 'cal-1', title: 'Work', isPrimary: true),
        CalendarEntry(id: 'cal-2', title: 'Holidays'),
      ];
      when(
        () => mockRepository.fetchCalendars(),
      ).thenAnswer((_) async => calendars);

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserProvider.overrideWith((ref) => mockUser),
            calendarRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            foregroundServiceProvider.overrideWithValue(mockForegroundService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pump(); // Start calendarRepositoryProvider loading
      await tester.pump(); // Start availableCalendarsProvider loading
      await tester.pumpAndSettle();

      expect(find.text('Managed Calendars'), findsOneWidget);
      expect(find.textContaining('Work'), findsOneWidget);
      expect(find.textContaining('Holidays'), findsOneWidget);

      // Initial state: Work should be enabled (default primary)
      // Switches order: 0: Auto-Volume, 1: All-Day, 2: Work, 3: Holidays
      final switches = find.byType(Switch);

      final allDaySwitch = switches.at(1);
      final workSwitch = switches.at(2);
      final holidaysSwitch = switches.at(3);

      expect(tester.widget<Switch>(allDaySwitch).value, isTrue);
      expect(tester.widget<Switch>(workSwitch).value, isTrue);
      expect(tester.widget<Switch>(holidaysSwitch).value, isFalse);

      // Toggle Holidays
      await tester.tap(find.textContaining('Holidays'));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(holidaysSwitch).value, isTrue);
      expect(
        prefs.getStringList('enabled_calendar_ids'),
        containsAll(['cal-1', 'cal-2']),
      );
    },
  );

  testWidgets('SettingsScreen allows toggling all-day events preference', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = MockGoogleSignInAccount();
    when(() => mockUser.email).thenReturn('test@example.com');

    final mockRepository = MockCalendarRepository();
    when(() => mockRepository.fetchCalendars()).thenAnswer((_) async => []);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith((ref) => mockUser),
          calendarRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
          foregroundServiceProvider.overrideWithValue(mockForegroundService),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify toggle exists and is true by default
    final allDayToggleFinder = find.text('Include All-Day Events');
    expect(allDayToggleFinder, findsOneWidget);

    final switches = find.byType(Switch);
    expect(tester.widget<Switch>(switches.at(1)).value, isTrue);

    // Toggle it
    await tester.tap(allDayToggleFinder);
    await tester.pumpAndSettle();

    // Verify state changed
    expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
    expect(prefs.getBool('include_all_day_events'), isFalse);
  });
}
