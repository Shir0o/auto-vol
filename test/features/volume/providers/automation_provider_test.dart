import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAutomationService extends Mock implements AutomationService {}
class MockVolumeService extends Mock implements VolumeService {}

void main() {
  late MockAutomationService mockAutomationService;
  late MockVolumeService mockVolumeService;

  setUp(() {
    mockAutomationService = MockAutomationService();
    mockVolumeService = MockVolumeService();
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
        volumeRulesProvider.overrideWith(() => _MockVolumeRulesNotifier(rules)),
        calendarEventsProvider.overrideWith((ref) => events),
        automationEnabledProvider.overrideWith(() => _MockEnabledNotifier(enabled)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AutomationNotifier', () {
    test('should set volume when automation is enabled and events change', () async {
      final startTime = DateTime.now().subtract(const Duration(minutes: 10));
      final endTime = DateTime.now().add(const Duration(minutes: 10));
      final activeEvent = CalendarEvent(
        id: '1',
        title: 'Focus',
        startTime: startTime,
        endTime: endTime,
        calendarId: 'primary',
      );

      when(() => mockAutomationService.calculateTargetVolume(
            activeEvents: any(named: 'activeEvents'),
            rules: any(named: 'rules'),
            defaultVolume: any(named: 'defaultVolume'),
          )).thenReturn(0.1);
      
      when(() => mockVolumeService.setVolume(any())).thenAnswer((_) async {});

      final container = createContainer(events: [activeEvent], enabled: true);
      
      // Trigger the notifier
      container.read(automationProvider);

      verify(() => mockVolumeService.setVolume(0.1)).called(1);
    });

    test('should NOT set volume when automation is disabled', () async {
      final container = createContainer(enabled: false);
      
      container.read(automationProvider);

      verifyNever(() => mockVolumeService.setVolume(any()));
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
