import 'package:auto_vol/features/calendar/models/calendar_event.dart';
import 'package:auto_vol/features/volume/models/volume_rule.dart';
import 'package:auto_vol/features/volume/services/automation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late AutomationService automationService;

  setUp(() {
    automationService = AutomationService();
  });

  group('AutomationService.calculateTargetVolume', () {
    test('should return default volume if no events are active', () {
      final volume = automationService.calculateTargetVolume(
        activeEvents: [],
        rules: [],
        defaultVolume: 0.5,
      );

      expect(volume, 0.5);
    });

    test('should return volume from matching rule', () {
      final activeEvent = CalendarEvent(
        id: '1',
        title: 'Focus Time',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: DateTime.now().add(const Duration(minutes: 10)),
        calendarId: 'primary',
      );

      final rule = VolumeRule(
        id: 'r1',
        calendarId: 'primary',
        eventTitlePattern: 'Focus',
        volumeLevel: 0.1,
        priority: 1,
      );

      final volume = automationService.calculateTargetVolume(
        activeEvents: [activeEvent],
        rules: [rule],
        defaultVolume: 0.5,
      );

      expect(volume, 0.1);
    });

    test('should pick rule with highest priority if multiple match', () {
      final activeEvent = CalendarEvent(
        id: '1',
        title: 'Important Focus',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: DateTime.now().add(const Duration(minutes: 10)),
        calendarId: 'primary',
      );

      final rule1 = VolumeRule(
        id: 'r1',
        calendarId: 'primary',
        eventTitlePattern: 'Focus',
        volumeLevel: 0.1,
        priority: 1,
      );

      final rule2 = VolumeRule(
        id: 'r2',
        calendarId: 'primary',
        eventTitlePattern: 'Important',
        volumeLevel: 0.0,
        priority: 10,
      );

      final volume = automationService.calculateTargetVolume(
        activeEvents: [activeEvent],
        rules: [rule1, rule2],
        defaultVolume: 0.5,
      );

      expect(volume, 0.0);
    });

    test('should respect volumeOverride on event (takes highest priority)', () {
      final activeEvent = CalendarEvent(
        id: '1',
        title: 'Focus Time',
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: DateTime.now().add(const Duration(minutes: 10)),
        calendarId: 'primary',
        volumeOverride: 0.2,
      );

      final rule = VolumeRule(
        id: 'r1',
        calendarId: 'primary',
        eventTitlePattern: 'Focus',
        volumeLevel: 0.1,
        priority: 1,
      );

      final volume = automationService.calculateTargetVolume(
        activeEvents: [activeEvent],
        rules: [rule],
        defaultVolume: 0.5,
      );

      expect(volume, 0.2);
    });
  });
}
