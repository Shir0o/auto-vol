import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:vocus/features/volume/repositories/volume_rules_repository.dart';

class MockAutomationService extends Mock implements AutomationService {}

class MockVolumeService extends Mock implements VolumeService {}

class MockVolumeRulesRepository extends Mock implements VolumeRulesRepository {}

void main() {
  late ForegroundTaskHandler handler;
  late MockAutomationService mockAutomationService;
  late MockVolumeService mockVolumeService;
  late MockVolumeRulesRepository mockRulesRepository;

  setUp(() async {
    mockAutomationService = MockAutomationService();
    mockVolumeService = MockVolumeService();
    mockRulesRepository = MockVolumeRulesRepository();

    handler = ForegroundTaskHandler();
    handler.setDependencies(
      automationService: mockAutomationService,
      volumeService: mockVolumeService,
      rulesRepository: mockRulesRepository,
    );

    SharedPreferences.setMockInitialValues({
      'automation_enabled': true,
      'default_volume': 0.5,
      'cached_events': jsonEncode([]),
    });

    registerFallbackValue(VolumeStream.media);

    when(() => mockRulesRepository.loadRules()).thenAnswer((_) async => []);
    when(
      () => mockAutomationService.calculateTargetVolume(
        activeEvents: any(named: 'activeEvents'),
        rules: any(named: 'rules'),
        defaultVolume: any(named: 'defaultVolume'),
      ),
    ).thenReturn(AutomationResult(volume: 0.5, isDefault: true));

    when(
      () => mockVolumeService.setVolume(any(), stream: any(named: 'stream')),
    ).thenAnswer((_) async {});
  });

  test(
    'should NOT set volume when there are no active events and no snapshots',
    () async {
      // GIVEN: No active events (cached_events is empty list in setUp)
      // AND: No snapshots in SharedPreferences

      // WHEN: onRepeatEvent is called
      await handler.onRepeatEvent(DateTime.now());

      // THEN: setVolume should NOT have been called
      verifyNever(
        () => mockVolumeService.setVolume(any(), stream: any(named: 'stream')),
      );
    },
  );

  test('should restore volume from snapshot when event ends', () async {
    // GIVEN: No active events
    // BUT: There is a snapshot in SharedPreferences
    SharedPreferences.setMockInitialValues({
      'automation_enabled': true,
      'default_volume': 0.5,
      'cached_events': jsonEncode([]),
      'volume_snapshot_media': 0.8,
    });

    // WHEN: onRepeatEvent is called
    await handler.onRepeatEvent(DateTime.now());

    // THEN: setVolume should have been called with the snapshot value
    verify(
      () => mockVolumeService.setVolume(0.8, stream: VolumeStream.media),
    ).called(1);

    // AND: snapshot should have been removed
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('volume_snapshot_media'), null);
  });
}
