import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/schedule/screens/schedule_screen.dart';
import 'package:vocus/features/settings/screens/settings_screen.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/screens/rules_screen.dart';

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

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

/// Collects every `RenderFlex overflowed ...` error raised while it is
/// installed. Overflow errors are swallowed (rather than forwarded to the test
/// binding) so one bad frame cannot short-circuit the rest of the audit; the
/// test asserts the collected list is empty at the end.
class _OverflowCollector {
  final List<String> messages = <String>[];
  FlutterExceptionHandler? _previous;

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final description = details.exceptionAsString();
      final isOverflow =
          description.contains('overflowed') &&
          (description.contains('RenderFlex') ||
              details.library == 'rendering library');
      if (isOverflow) {
        messages.add(details.toString());
        return;
      }
      _previous?.call(details);
    };
  }

  void restore() {
    final previous = _previous;
    if (previous != null) {
      FlutterError.onError = previous;
      _previous = null;
    }
  }
}

void main() {
  late SharedPreferences prefs;
  late MockGoogleSignInAccount mockUser;
  late CalendarEvent activeEvent;
  late CalendarEvent upcomingEvent;
  late VolumeRule rule1;
  late AutomationStatus status;

  const phone = Size(390, 844);
  const smallPhone = Size(320, 568);

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<List<CalendarEvent>>());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    mockUser = MockGoogleSignInAccount();
    when(() => mockUser.email).thenReturn('user@example.com');
    when(() => mockUser.displayName).thenReturn('Alex');

    final now = DateTime.now();
    activeEvent = CalendarEvent(
      id: 'event-active-1',
      title: 'Sprint Planning & Roadmap Review',
      startTime: now.subtract(const Duration(minutes: 20)),
      endTime: now.add(const Duration(minutes: 40)),
      calendarId: 'primary',
      calendarTitle: 'Work',
      calendarColor: '#00F0FF',
      description: 'Review Q4 deliverables and team commitments',
    );

    upcomingEvent = CalendarEvent(
      id: 'event-upcoming-2',
      title: 'Architecture Review',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      calendarId: 'primary',
      calendarTitle: 'Engineering',
      calendarColor: '#7000FF',
      description: 'Discuss audio automation architecture',
    );

    rule1 = VolumeRule(
      id: 'rule-sprint',
      calendarId: 'primary',
      eventTitlePattern: 'Sprint Planning',
      volumeLevel: 0.15,
      priority: 2,
    );

    status = AutomationStatus(
      isEnabled: true,
      currentVolume: 0.15,
      activeEvents: [activeEvent],
      winningEvent: activeEvent,
      winningRule: rule1,
    );
  });

  Widget buildHarvestedApp({required ThemeMode themeMode}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarEventsProvider.overrideWith(
          (ref) => [activeEvent, upcomingEvent],
        ),
        availableCalendarsProvider.overrideWith(
          (ref) async => [
            CalendarEntry(
              id: 'primary',
              title: 'Work',
              isPrimary: true,
              color: '#00F0FF',
            ),
            CalendarEntry(id: 'team', title: 'Team', color: '#7000FF'),
          ],
        ),
        volumeRulesProvider.overrideWith(() => MockVolumeRules([rule1])),
        eventOverridesProvider.overrideWith(() => MockEventOverrides({})),
        automationProvider.overrideWith(() => MockAutomation(status)),
        authStateProvider.overrideWith(() => MockAuthState(mockUser)),
        currentUserProvider.overrideWith((ref) => mockUser),
        notificationPermissionProvider.overrideWith((ref) => true),
        notificationPolicyAccessProvider.overrideWith((ref) => true),
        ignoreBatteryOptimizationsProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        title: 'Vocus',
        theme: VocusTheme.lightTheme,
        darkTheme: VocusTheme.darkTheme,
        themeMode: themeMode,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Future<void> pumpVariant(
    WidgetTester tester, {
    required ThemeMode themeMode,
    required Size size,
    required double textScale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(buildHarvestedApp(themeMode: themeMode));
    await tester.pumpAndSettle();
  }

  /// Goldens are only written when `flutter test --update-goldens` is run.
  /// In a normal run this is a no-op, so a missing golden never fails CI.
  Future<void> maybeGolden(WidgetTester tester, String name) async {
    if (!autoUpdateGoldenFiles) return;
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  Future<void> audit(WidgetTester tester, String step) async {
    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
      reason: 'androidTapTargetGuideline failed at: $step',
    );
    await expectLater(
      tester,
      meetsGuideline(textContrastGuideline),
      reason: 'textContrastGuideline failed at: $step',
    );
  }

  Finder navItem(String label) => find.descendant(
    of: find.byType(BottomNavigationBar),
    matching: find.text(label),
  );

  void expectNoOverflows(_OverflowCollector overflows, String step) {
    overflows.restore();
    expect(
      overflows.messages,
      isEmpty,
      reason:
          'RenderFlex overflow(s) detected at: $step\n'
          '${overflows.messages.join('\n---\n')}',
    );
  }

  group('UI/UX Usability & Golden Matrix Audit', () {
    testWidgets('variant: phone_light (390x844 @ 1.0x)', (tester) async {
      final overflows = _OverflowCollector()..start();
      addTearDown(overflows.restore);

      await pumpVariant(
        tester,
        themeMode: ThemeMode.light,
        size: phone,
        textScale: 1.0,
      );

      expect(find.byType(ScheduleScreen), findsOneWidget);
      await maybeGolden(tester, 'phone_light');
      await audit(tester, 'phone_light');

      expectNoOverflows(overflows, 'phone_light');
      expect(tester.takeException(), isNull);
    });

    testWidgets('variant: phone_dark (390x844 @ 1.0x)', (tester) async {
      final overflows = _OverflowCollector()..start();
      addTearDown(overflows.restore);

      await pumpVariant(
        tester,
        themeMode: ThemeMode.dark,
        size: phone,
        textScale: 1.0,
      );

      expect(find.byType(ScheduleScreen), findsOneWidget);
      await maybeGolden(tester, 'phone_dark');
      await audit(tester, 'phone_dark');

      expectNoOverflows(overflows, 'phone_dark');
      expect(tester.takeException(), isNull);
    });

    testWidgets('variant: small_large_font (320x568 @ 1.6x)', (tester) async {
      final overflows = _OverflowCollector()..start();
      addTearDown(overflows.restore);

      await pumpVariant(
        tester,
        themeMode: ThemeMode.light,
        size: smallPhone,
        textScale: 1.6,
      );

      expect(find.byType(ScheduleScreen), findsOneWidget);
      await maybeGolden(tester, 'small_320x568_text_1_6');
      await audit(tester, 'small_large_font');

      expectNoOverflows(overflows, 'small_large_font');
      expect(tester.takeException(), isNull);
    });

    testWidgets('interactive: tabs, rules screen and dialogs (390x844)', (
      tester,
    ) async {
      final overflows = _OverflowCollector()..start();
      addTearDown(overflows.restore);

      await pumpVariant(
        tester,
        themeMode: ThemeMode.light,
        size: phone,
        textScale: 1.0,
      );

      // Default tab.
      expect(find.byType(ScheduleScreen), findsOneWidget);

      // Schedule -> Settings.
      await tester.tap(navItem('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await maybeGolden(tester, 'step_settings');
      await audit(tester, 'settings tab');

      // Scroll through Settings so lower sections are laid out and audited.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await audit(tester, 'settings tab (scrolled)');
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();

      // Settings -> Automation Rules (pushed route).
      await tester.scrollUntilVisible(
        find.text('Automation Rules'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Automation Rules'));
      await tester.pumpAndSettle();
      expect(find.byType(RulesScreen), findsOneWidget);
      await audit(tester, 'rules screen');

      // FAB -> add-options bottom sheet.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Add Manual Override'), findsOneWidget);
      await audit(tester, 'add options sheet');
      await maybeGolden(tester, 'step_add_sheet');

      // Sheet -> "Select Event" dialog.
      await tester.tap(find.text('Add Manual Override'));
      await tester.pumpAndSettle();
      expect(find.text('Select Event'), findsOneWidget);
      await audit(tester, 'event picker dialog');

      // Pick an event -> per-event override dialog.
      await tester.tap(find.text(activeEvent.title));
      await tester.pumpAndSettle();
      expect(find.text('Override "${activeEvent.title}"'), findsOneWidget);
      await audit(tester, 'override dialog');
      await maybeGolden(tester, 'step_override_dialog');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // FAB -> Add General Rule -> "Add Rule" dialog.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add General Rule'));
      await tester.pumpAndSettle();
      expect(find.text('Add Rule'), findsOneWidget);
      await audit(tester, 'add rule dialog');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Back to Settings, then back to the Schedule tab.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(navItem('Schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleScreen), findsOneWidget);
      await audit(tester, 'schedule tab after navigation');

      expectNoOverflows(overflows, 'interactive 390x844');
      expect(tester.takeException(), isNull);
    });

    testWidgets('interactive: tab click-through on small +1.6x font', (
      tester,
    ) async {
      final overflows = _OverflowCollector()..start();
      addTearDown(overflows.restore);

      await pumpVariant(
        tester,
        themeMode: ThemeMode.dark,
        size: smallPhone,
        textScale: 1.6,
      );

      await tester.tap(navItem('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await audit(tester, 'small settings tab');

      await tester.scrollUntilVisible(
        find.text('Automation Rules'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await audit(tester, 'small settings tab (scrolled)');

      await tester.tap(navItem('Schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleScreen), findsOneWidget);
      await audit(tester, 'small schedule tab');

      expectNoOverflows(overflows, 'interactive 320x568 @ 1.6x');
      expect(tester.takeException(), isNull);
    });
  });
}
