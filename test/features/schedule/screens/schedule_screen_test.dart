import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/schedule/screens/schedule_screen.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MockAutomation extends Notifier<AutomationStatus>
    with Mock
    implements Automation {
  final AutomationStatus _status;
  MockAutomation(this._status);

  @override
  AutomationStatus build() => _status;
}

class MockVolumeRules extends AsyncNotifier<List<VolumeRule>>
    with Mock
    implements VolumeRules {
  final List<VolumeRule> _rules;
  MockVolumeRules(this._rules);

  @override
  FutureOr<List<VolumeRule>> build() async => _rules;
}

class MockEventOverrides extends AsyncNotifier<Map<String, double>>
    with Mock
    implements EventOverrides {
  final Map<String, double> _overrides;
  MockEventOverrides(this._overrides);

  @override
  FutureOr<Map<String, double>> build() async => _overrides;
}

class MockAuthState extends AsyncNotifier<GoogleSignInAccount?>
    with Mock
    implements AuthState {
  final GoogleSignInAccount? _user;
  MockAuthState(this._user);

  @override
  FutureOr<GoogleSignInAccount?> build() => _user;
}

void main() {
  late MockEventOverrides mockOverrides;
  late MockVolumeRules mockRules;
  final dummyStatus = AutomationStatus(
    isEnabled: false,
    currentVolume: 0.5,
    activeEvents: [],
  );

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<List<CalendarEvent>>());
  });

  setUp(() {
    mockOverrides = MockEventOverrides({}.cast<String, double>());
    mockRules = MockVolumeRules([]);

    when(() => mockOverrides.removeOverride(any())).thenAnswer((_) async {});
    when(
      () => mockOverrides.setOverride(any(), any()),
    ).thenAnswer((_) async {});
  });

  testWidgets('ScheduleScreen displays empty state when no events', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = MockGoogleSignInAccount();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => <CalendarEvent>[]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
  });

  testWidgets('ScheduleScreen displays list of events', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final mockUser = MockGoogleSignInAccount();
    final event1 = CalendarEvent(
      id: '1',
      title: 'Meeting',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      calendarId: 'primary',
      calendarTitle: 'Work',
      calendarColor: '#FF0000',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => [event1]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Meeting'), findsOneWidget);
    expect(find.textContaining('Work'), findsOneWidget);
  });

  testWidgets('ScheduleScreen allows tuning volume override for an event', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final mockUser = MockGoogleSignInAccount();
    final event = CalendarEvent(
      id: '1',
      title: 'Event',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      calendarId: 'primary',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => [event]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Find the tune button
    final tuneButton = find.byIcon(Icons.volume_up_outlined);
    expect(tuneButton, findsOneWidget);

    // Tap it
    await tester.tap(tuneButton);
    await tester.pumpAndSettle();

    // Verify dialog shown
    expect(find.textContaining('Tune Volume for'), findsOneWidget);
  });

  testWidgets('ScheduleScreen allows resetting volume override for an event', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final mockUser = MockGoogleSignInAccount();
    final event = CalendarEvent(
      id: '1',
      title: 'Event',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      calendarId: 'primary',
      volumeOverride: 0.8,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => [event]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Find the tune button (should be Icons.edit because override exists)
    final tuneButton = find.byIcon(Icons.edit);
    expect(tuneButton, findsOneWidget);

    // Tap it
    await tester.tap(tuneButton);
    await tester.pumpAndSettle();

    // Verify RESET button shown
    final resetButton = find.text('RESET');
    expect(resetButton, findsOneWidget);

    // Tap RESET
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    // Verify dialog closed
    expect(find.text('RESET'), findsNothing);
  });

  testWidgets('ScheduleScreen highlights winning event and shows conflicts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final mockUser = MockGoogleSignInAccount();
    final event1 = CalendarEvent(
      id: 'e1',
      title: 'Meeting 1',
      startTime: now.subtract(const Duration(minutes: 10)),
      endTime: now.add(const Duration(minutes: 10)),
      calendarId: 'primary',
    );
    final event2 = CalendarEvent(
      id: 'e2',
      title: 'Meeting 2',
      startTime: now.subtract(const Duration(minutes: 5)),
      endTime: now.add(const Duration(minutes: 15)),
      calendarId: 'primary',
    );

    final rule1 = VolumeRule(
      id: 'r1',
      calendarId: 'primary',
      eventTitlePattern: 'Meeting 1',
      volumeLevel: 0.2,
      priority: 2,
    );
    final rule2 = VolumeRule(
      id: 'r2',
      calendarId: 'primary',
      eventTitlePattern: 'Meeting 2',
      volumeLevel: 0.5,
      priority: 1,
    );

    final status = AutomationStatus(
      isEnabled: true,
      currentVolume: 0.2,
      activeEvents: [event1, event2],
      winningEvent: event1,
      winningRule: rule1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => [event1, event2]),
          volumeRulesProvider.overrideWith(
            () => MockVolumeRules([rule1, rule2]),
          ),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(status)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Target labels
    expect(find.text('Target: 20%'), findsOneWidget);
    expect(find.text('Target: 50%'), findsOneWidget);

    // Verify winning icon
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);

    // Verify conflict icon (warning)
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });

  testWidgets('ScheduleScreen shows banner when permissions are missing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = MockGoogleSignInAccount();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => <CalendarEvent>[]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
          notificationPermissionProvider.overrideWith((ref) => false),
          notificationPolicyAccessProvider.overrideWith((ref) => false),
          ignoreBatteryOptimizationsProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missing Permissions'), findsOneWidget);
    expect(find.text('Fix in Settings'), findsOneWidget);
  });

  testWidgets('ScheduleScreen hides banner when all permissions are granted', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockUser = MockGoogleSignInAccount();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => <CalendarEvent>[]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
          notificationPermissionProvider.overrideWith((ref) => true),
          notificationPolicyAccessProvider.overrideWith((ref) => true),
          ignoreBatteryOptimizationsProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missing Permissions'), findsNothing);
  });

  testWidgets(
    'ScheduleScreen navigates to Settings when Fix in Settings is tapped',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockUser = MockGoogleSignInAccount();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) => <CalendarEvent>[]),
          volumeRulesProvider.overrideWith(() => mockRules),
          eventOverridesProvider.overrideWith(() => mockOverrides),
          automationProvider.overrideWith(() => MockAutomation(dummyStatus)),
          authStateProvider.overrideWith(() => MockAuthState(mockUser)),
          currentUserProvider.overrideWith((ref) => mockUser),
          notificationPermissionProvider.overrideWith((ref) => false),
          notificationPolicyAccessProvider.overrideWith((ref) => false),
          ignoreBatteryOptimizationsProvider.overrideWith((ref) => false),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final fixButton = find.text('Fix in Settings');
      expect(fixButton, findsOneWidget);

      await tester.tap(fixButton);
      await tester.pump();

      expect(container.read(selectedIndexProvider), 1);
    },
  );
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
