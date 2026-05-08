import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/schedule/screens/schedule_screen.dart';
import 'package:shimmer/shimmer.dart';

class MockAutomationNotifier extends AutomationNotifier {
  final AutomationStatus _status;
  MockAutomationNotifier(this._status);

  @override
  AutomationStatus build() => _status;
}

class MockVolumeRulesNotifier extends VolumeRulesNotifier {
  final List<VolumeRule> _rules;
  MockVolumeRulesNotifier(this._rules);

  @override
  Future<List<VolumeRule>> build() async => _rules;
}

void main() {
  final dummyStatus = AutomationStatus(
    isEnabled: false,
    currentVolume: 0.5,
    activeEvents: [],
  );

  testWidgets('ScheduleScreen shows skeleton loader when loading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final completer = Completer<List<CalendarEvent>>();
    final loadingProvider = FutureProvider<List<CalendarEvent>>(
      (ref) => completer.future,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith(
            (ref) => ref.watch(loadingProvider.future),
          ),
          automationProvider.overrideWith(
            () => MockAutomationNotifier(dummyStatus),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: const ScheduleScreen()),
      ),
    );

    await tester.pump();

    // Should find Shimmer instead of CircularProgressIndicator
    expect(find.byType(Shimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Complete to clean up
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('ScheduleScreen has RefreshIndicator and triggers refresh', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    int callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) async {
            callCount++;
            return [
              CalendarEvent(
                id: '1',
                title: 'Test Event $callCount',
                startTime: DateTime.now().add(const Duration(hours: 1)),
                endTime: DateTime.now().add(const Duration(hours: 2)),
                calendarId: 'primary',
                calendarTitle: 'Work',
                calendarColor: '#FF0000',
              ),
            ];
          }),
          automationProvider.overrideWith(
            () => MockAutomationNotifier(dummyStatus),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: const ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Event 1'), findsOneWidget);
    expect(find.textContaining('Work'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(callCount, 1);

    // Find RefreshIndicator
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Trigger Refresh
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump(); // start refresh
    await tester.pump(const Duration(seconds: 1)); // wait for refresh
    await tester.pumpAndSettle();

    // Verify it refreshed
    expect(find.text('Test Event 2'), findsOneWidget);
    expect(callCount, 2);
  });

  testWidgets('ScheduleScreen allows setting volume override for an event', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final event = CalendarEvent(
      id: 'event-1',
      title: 'Tune Me',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      calendarId: 'primary',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) async => [event]),
          automationProvider.overrideWith(
            () => MockAutomationNotifier(dummyStatus),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: const ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Find the tune button (we'll use Icons.volume_up_outlined as a finder)
    final tuneButton = find.byIcon(Icons.volume_up_outlined);
    expect(tuneButton, findsOneWidget);

    // Tap it to open dialog/sheet
    await tester.tap(tuneButton);
    await tester.pumpAndSettle();

    // Should find a slider and a confirm button
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('APPLY'), findsOneWidget);

    // Set slider to 0.8 (80%)
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();

    // Tap apply
    await tester.tap(find.text('APPLY'));
    await tester.pumpAndSettle();

    // Verify it closed (no slider anymore)
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('ScheduleScreen allows resetting volume override for an event', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final event = CalendarEvent(
      id: 'event-1',
      title: 'Reset Me',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      calendarId: 'primary',
      volumeOverride: 0.8,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) async => [event]),
          automationProvider.overrideWith(
            () => MockAutomationNotifier(dummyStatus),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: const ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Find the tune button (should be Icons.edit because override exists)
    final tuneButton = find.byIcon(Icons.edit);
    expect(tuneButton, findsOneWidget);

    // Tap it
    await tester.tap(tuneButton);
    await tester.pumpAndSettle();

    // Should find RESET button
    final resetButton = find.text('RESET');
    expect(resetButton, findsOneWidget);

    // Tap RESET
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    // Verify dialog closed
    expect(find.text('RESET'), findsNothing);
  });

  testWidgets('ScheduleScreen highlights winning event and shows conflicts',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
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
          calendarEventsProvider.overrideWith((ref) async => [event1, event2]),
          volumeRulesProvider
              .overrideWith(() => MockVolumeRulesNotifier([rule1, rule2])),
          automationProvider.overrideWith(() => MockAutomationNotifier(status)),
          currentUserProvider.overrideWithValue(null),
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

  testWidgets('ScheduleScreen shows correct tooltip on conflict icon',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarEventsProvider.overrideWith((ref) async => [event1, event2]),
          volumeRulesProvider
              .overrideWith(() => MockVolumeRulesNotifier([rule1, rule2])),
          automationProvider.overrideWith(
              () => MockAutomationNotifier(AutomationStatus(
                    isEnabled: true,
                    currentVolume: 0.2,
                    activeEvents: [event1, event2],
                    winningEvent: event1,
                    winningRule: rule1,
                  ))),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final warningFinder = find.byIcon(Icons.warning_amber_rounded);
    expect(warningFinder, findsWidgets);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Volume conflict with another event',
      ),
      findsWidgets,
    );
  });
}
