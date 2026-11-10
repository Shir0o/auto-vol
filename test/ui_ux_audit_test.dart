import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';

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

void main() {
  late SharedPreferences prefs;
  late MockGoogleSignInAccount mockUser;
  late CalendarEvent activeEvent;
  late CalendarEvent upcomingEvent;
  late VolumeRule rule1;
  late AutomationStatus status;

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

  Widget buildHarvestedApp({
    required ThemeMode themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarEventsProvider.overrideWith(
          (ref) => [activeEvent, upcomingEvent],
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
        theme: lightTheme ?? ThemeData.light(useMaterial3: true),
        darkTheme: darkTheme ?? VocusTheme.darkTheme,
        themeMode: themeMode,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  group('UI/UX Usability & Golden Matrix Audit', () {
    testWidgets('variant: phone_light (390x844 @ 1.0x)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildHarvestedApp(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/phone_light.png'),
        );
      }

      expect(tester.takeException(), isNull);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('variant: phone_dark (390x844 @ 1.0x)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildHarvestedApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/phone_dark.png'),
        );
      }

      expect(tester.takeException(), isNull);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('variant: small_large_font (320x568 @ 1.6x)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildHarvestedApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      if (autoUpdateGoldenFiles) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/small_large_font.png'),
        );
      }

      expect(tester.takeException(), isNull);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
