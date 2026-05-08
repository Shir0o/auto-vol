import 'dart:async';
import 'dart:convert';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAutomationService extends Mock implements AutomationService {}
class MockVolumeService extends Mock implements VolumeService {}
class MockForegroundService extends Mock implements ForegroundServiceWrapper {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

class FakeVolumeRules extends VolumeRules {
  final List<VolumeRule> _rules;
  FakeVolumeRules(this._rules);
  @override
  FutureOr<List<VolumeRule>> build() => _rules;
}

class FakeAutomationEnabled extends AutomationEnabled {
  final bool _initial;
  FakeAutomationEnabled(this._initial);
  @override
  bool build() => _initial;
}

class FakeAutomateRinger extends AutomateRinger {
  final bool _val;
  FakeAutomateRinger(this._val);
  @override
  bool build() => _val;
}

class FakeAutomateNotification extends AutomateNotification {
  final bool _val;
  FakeAutomateNotification(this._val);
  @override
  bool build() => _val;
}

class FakeAutomateDnd extends AutomateDnd {
  final bool _val;
  FakeAutomateDnd(this._val);
  @override
  bool build() => _val;
}

class _TestEventsNotifier extends Notifier<List<CalendarEvent>> {
  @override
  List<CalendarEvent> build() => [];
  void set(List<CalendarEvent> events) => state = events;
}

final testEventsProvider = NotifierProvider<_TestEventsNotifier, List<CalendarEvent>>(_TestEventsNotifier.new);

void main() {
  late MockAutomationService mockAutomationService;
  late MockVolumeService mockVolumeService;
  late MockForegroundService mockForegroundService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    registerFallbackValue(VolumeStream.media);
    mockAutomationService = MockAutomationService();
    mockVolumeService = MockVolumeService();
    mockForegroundService = MockForegroundService();
    mockSharedPreferences = MockSharedPreferences();

    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockSharedPreferences.getStringList(any())).thenReturn(null);
    when(() => mockSharedPreferences.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);

    when(() => mockVolumeService.getVolume(stream: any(named: 'stream')))
        .thenAnswer((_) async => 0.5);
    when(() => mockVolumeService.setVolume(any(), stream: any(named: 'stream')))
        .thenAnswer((_) async {});
    when(() => mockVolumeService.isDndEnabled()).thenAnswer((_) async => false);
    when(() => mockVolumeService.setDndMode(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({
    List<VolumeRule> rules = const [],
    bool enabled = true,
    bool automateRinger = false,
    bool automateNotification = false,
    bool automateDnd = false,
    Stream<DateTime>? tickStream,
  }) {
    final container = ProviderContainer(
      overrides: [
        automationServiceProvider.overrideWithValue(mockAutomationService),
        volumeServiceProvider.overrideWithValue(mockVolumeService),
        foregroundServiceProvider.overrideWithValue(mockForegroundService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        calendarEventsProvider.overrideWith((ref) => ref.watch(testEventsProvider)),
        volumeRulesProvider.overrideWith(() => FakeVolumeRules(rules)),
        automationEnabledProvider.overrideWith(() => FakeAutomationEnabled(enabled)),
        automateRingerProvider.overrideWith(() => FakeAutomateRinger(automateRinger)),
        automateNotificationProvider.overrideWith(() => FakeAutomateNotification(automateNotification)),
        automateDndProvider.overrideWith(() => FakeAutomateDnd(automateDnd)),
        if (tickStream != null) tickProvider.overrideWith((ref) => tickStream),
      ],
    );

    when(() => mockSharedPreferences.getBool('automation_enabled')).thenReturn(enabled);
    when(() => mockSharedPreferences.getBool('automate_ringer')).thenReturn(automateRinger);
    when(() => mockSharedPreferences.getBool('automate_notification')).thenReturn(automateNotification);
    when(() => mockSharedPreferences.getBool('automate_dnd')).thenReturn(automateDnd);

    addTearDown(container.dispose);
    return container;
  }

  group('AutomationNotifier', () {
    test(
      'should snapshot current volume before event starts and restore it after event ends',
      () async {
        final tickController = StreamController<DateTime>(sync: true);

        // Initial state: no events
        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: [],
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.5, isDefault: true));

        when(
          () => mockVolumeService.getVolume(stream: any(named: 'stream')),
        ).thenAnswer((_) async => 0.7);

        final container = createContainer(
          enabled: true,
          tickStream: tickController.stream,
        );

        container.listen(automationProvider, (_, __) {});

        // Initial build - no events, should use default (0.5)
        await Future.delayed(const Duration(milliseconds: 10));
        verify(
          () => mockVolumeService.setVolume(0.5, stream: VolumeStream.media),
        ).called(greaterThanOrEqualTo(1));

        // Event starts
        final activeEvent = CalendarEvent(
          id: '1',
          title: 'Meeting',
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now().add(const Duration(minutes: 10)),
          calendarId: 'primary',
        );

        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: [activeEvent],
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.2, winningEvent: activeEvent));

        // Update events and tick
        container.read(testEventsProvider.notifier).state = [activeEvent];
        tickController.add(DateTime.now());

        await Future.delayed(const Duration(milliseconds: 10));

        // Should have snapshotted 0.7 and set to 0.2
        verify(
          () => mockVolumeService.getVolume(stream: VolumeStream.media),
        ).called(greaterThanOrEqualTo(1));
        verify(
          () => mockVolumeService.setVolume(0.2, stream: VolumeStream.media),
        ).called(greaterThanOrEqualTo(1));

        // Set mock to return snapshotted value when restoring
        when(() => mockSharedPreferences.getDouble('volume_snapshot_media')).thenReturn(0.7);

        // Event ends
        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: [],
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.5, isDefault: true));

        container.read(testEventsProvider.notifier).state = [];
        tickController.add(DateTime.now());

        await Future.delayed(const Duration(milliseconds: 10));

        // Should have restored 0.7 instead of setting to 0.5
        verify(
          () => mockVolumeService.setVolume(0.7, stream: VolumeStream.media),
        ).called(1);

        tickController.close();
      },
    );

    test(
      'should set volume and return status when automation is enabled and events change',
      () async {
        final activeEvent = CalendarEvent(
          id: '1',
          title: 'Focus',
          startTime: DateTime.now().subtract(const Duration(minutes: 10)),
          endTime: DateTime.now().add(const Duration(minutes: 10)),
          calendarId: 'primary',
        );

        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: any(named: 'activeEvents'),
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.1));

        final container = createContainer(enabled: true);
        container.read(testEventsProvider.notifier).state = [activeEvent];

        // Trigger the notifier
        final status = container.read(automationProvider);

        // Wait for microtask
        await Future.delayed(Duration.zero);

        expect(status.isEnabled, true);
        expect(status.currentVolume, 0.1);
        expect(status.activeEvents, [activeEvent]);
        verify(
          () => mockVolumeService.setVolume(0.1, stream: VolumeStream.media),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    test('should return disabled status when automation is disabled', () async {
      final container = createContainer(enabled: false);

      final status = container.read(automationProvider);

      expect(status.isEnabled, false);
      verifyNever(
        () => mockVolumeService.setVolume(any(), stream: any(named: 'stream')),
      );
    });
  });

  group('AutomationEnabledNotifier', () {
    test('should start foreground service when enabled', () {
      when(() => mockForegroundService.start()).thenAnswer((_) async => true);
      
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          foregroundServiceProvider.overrideWithValue(mockForegroundService),
        ],
      );
      
      when(() => mockSharedPreferences.getBool('automation_enabled')).thenReturn(false);

      container.read(automationEnabledProvider.notifier).set(true);

      verify(() => mockForegroundService.start()).called(1);
    });

    test('should stop foreground service when disabled', () {
      when(() => mockForegroundService.stop()).thenAnswer((_) async => true);
      
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
          foregroundServiceProvider.overrideWithValue(mockForegroundService),
        ],
      );

      when(() => mockSharedPreferences.getBool('automation_enabled')).thenReturn(true);

      container.read(automationEnabledProvider.notifier).set(false);

      verify(() => mockForegroundService.stop()).called(1);
    });
  });
}
