import 'dart:async';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAutomationService extends Mock implements AutomationService {}

class MockVolumeService extends Mock implements VolumeService {}

class MockForegroundService extends Mock implements ForegroundServiceWrapper {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class _ManualListNotifier<T> extends Notifier<List<T>> {
  @override
  List<T> build() => [];
  set state(List<T> value) => super.state = value;
}

void main() {
  late MockAutomationService mockAutomationService;
  late MockVolumeService mockVolumeService;
  late MockForegroundService mockForegroundService;
  late MockSharedPreferences mockSharedPreferences;
  late NotifierProvider<_ManualListNotifier<CalendarEvent>, List<CalendarEvent>> eventsStateProvider;

  setUp(() {
    mockAutomationService = MockAutomationService();
    mockVolumeService = MockVolumeService();
    mockForegroundService = MockForegroundService();
    mockSharedPreferences = MockSharedPreferences();
    eventsStateProvider = NotifierProvider<_ManualListNotifier<CalendarEvent>, List<CalendarEvent>>(() => _ManualListNotifier<CalendarEvent>());

    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSharedPreferences.setDouble(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSharedPreferences.setBool(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.remove(any())).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
    when(() => mockVolumeService.getVolume()).thenAnswer((_) async => 0.5);
  });

  ProviderContainer createContainer({
    List<VolumeRule> rules = const [],
    List<CalendarEvent> events = const [],
    bool enabled = true,
    Stream<DateTime>? tickStream,
  }) {
    final container = ProviderContainer(
      overrides: [
        automationServiceProvider.overrideWithValue(mockAutomationService),
        volumeServiceProvider.overrideWithValue(mockVolumeService),
        foregroundServiceProvider.overrideWithValue(mockForegroundService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        calendarEventsProvider.overrideWith((ref) => ref.watch(eventsStateProvider)),
        volumeRulesProvider.overrideWith(() => _MockVolumeRulesNotifier(rules)),
        automationEnabledProvider.overrideWith(
          () => _MockEnabledNotifier(enabled),
        ),
        if (tickStream != null) tickProvider.overrideWith((ref) => tickStream),
      ],
    );
    // Initialize state
    container.read(eventsStateProvider.notifier).state = events;
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

        when(() => mockVolumeService.getVolume()).thenAnswer((_) async => 0.7);
        when(() => mockVolumeService.setVolume(any())).thenAnswer((_) async {});

        final container = createContainer(
          events: [], 
          enabled: true, 
          tickStream: tickController.stream,
        );

        container.listen(automationProvider, (_, __) {});

        // Initial build - no events, should use default (0.5)
        await Future.delayed(const Duration(milliseconds: 10));
        verify(() => mockVolumeService.setVolume(0.5)).called(greaterThanOrEqualTo(1));

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

        // Update events
        container.read(eventsStateProvider.notifier).state = [activeEvent];
        tickController.add(DateTime.now());
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Should have snapshotted 0.7 (mocked getVolume) and set to 0.2
        verify(() => mockVolumeService.getVolume()).called(greaterThanOrEqualTo(1));
        verify(() => mockVolumeService.setVolume(0.2)).called(greaterThanOrEqualTo(1));

        // Event ends
        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: [],
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.5, isDefault: true));

        container.read(eventsStateProvider.notifier).state = [];
        tickController.add(DateTime.now());

        await Future.delayed(const Duration(milliseconds: 10));

        // Should have restored 0.7 instead of setting to 0.5
        verify(() => mockVolumeService.setVolume(0.7)).called(1);
        
        tickController.close();
      },
    );
    test(
      'should set volume and return status when automation is enabled and events change',
      () async {
        final startTime = DateTime.now().subtract(const Duration(minutes: 10));
        final endTime = DateTime.now().add(const Duration(minutes: 10));
        final activeEvent = CalendarEvent(
          id: '1',
          title: 'Focus',
          startTime: startTime,
          endTime: endTime,
          calendarId: 'primary',
        );

        when(
          () => mockAutomationService.calculateTargetVolume(
            activeEvents: any(named: 'activeEvents'),
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          ),
        ).thenReturn(AutomationResult(volume: 0.1));

        when(() => mockVolumeService.setVolume(any())).thenAnswer((_) async {});

        final container = createContainer(events: [activeEvent], enabled: true);

        // Trigger the notifier
        final status = container.read(automationProvider);

        // Wait for microtask
        await Future.delayed(Duration.zero);

        expect(status.isEnabled, true);
        expect(status.currentVolume, 0.1);
        expect(status.activeEvents, [activeEvent]);
        verify(() => mockVolumeService.setVolume(0.1)).called(1);
      },
    );

    test('should return disabled status when automation is disabled', () async {
      final container = createContainer(enabled: false);

      final status = container.read(automationProvider);

      expect(status.isEnabled, false);
      verifyNever(() => mockVolumeService.setVolume(any()));
    });
  });

  group('AutomationEnabledNotifier', () {
    test('should start foreground service when enabled', () {
      when(() => mockForegroundService.start()).thenAnswer((_) async => true);
      final container = createContainer(enabled: false);

      container.read(automationEnabledProvider.notifier).set(true);

      verify(() => mockForegroundService.start()).called(1);
    });

    test('should stop foreground service when disabled', () {
      when(() => mockForegroundService.stop()).thenAnswer((_) async => true);
      final container = createContainer(enabled: true);

      container.read(automationEnabledProvider.notifier).set(false);

      verify(() => mockForegroundService.stop()).called(1);
    });
  });
}

class _MockVolumeRulesNotifier extends VolumeRulesNotifier {
  final List<VolumeRule> _rules;
  _MockVolumeRulesNotifier(this._rules);

  @override
  Future<List<VolumeRule>> build() async => _rules;
}

class _MockEnabledNotifier extends AutomationEnabledNotifier {
  final bool _enabled;
  _MockEnabledNotifier(this._enabled);

  @override
  bool build() => _enabled;
}
