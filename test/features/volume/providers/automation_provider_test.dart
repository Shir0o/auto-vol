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

void main() {
  late MockAutomationService mockAutomationService;
  late MockVolumeService mockVolumeService;
  late MockForegroundService mockForegroundService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockAutomationService = MockAutomationService();
    mockVolumeService = MockVolumeService();
    mockForegroundService = MockForegroundService();
    mockSharedPreferences = MockSharedPreferences();

    when(
      () => mockSharedPreferences.setString(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSharedPreferences.setDouble(any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockSharedPreferences.setBool(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => mockSharedPreferences.getBool(any())).thenReturn(null);
    when(() => mockSharedPreferences.getDouble(any())).thenReturn(null);
  });

  ProviderContainer createContainer({
    List<VolumeRule> rules = const [],
    List<CalendarEvent> events = const [],
    bool enabled = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        automationServiceProvider.overrideWithValue(mockAutomationService),
        volumeServiceProvider.overrideWithValue(mockVolumeService),
        foregroundServiceProvider.overrideWithValue(mockForegroundService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        volumeRulesProvider.overrideWith(() => _MockVolumeRulesNotifier(rules)),
        calendarEventsProvider.overrideWith((ref) => events),
        automationEnabledProvider.overrideWith(
          () => _MockEnabledNotifier(enabled),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AutomationNotifier', () {
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
