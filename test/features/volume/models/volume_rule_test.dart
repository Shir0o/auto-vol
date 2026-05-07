import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VolumeRule', () {
    test('should correctly instantiate', () {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'primary',
        eventTitlePattern: 'Focus',
        volumeLevel: 0.1,
        priority: 1,
      );

      expect(rule.id, '1');
      expect(rule.calendarId, 'primary');
      expect(rule.eventTitlePattern, 'Focus');
      expect(rule.volumeLevel, 0.1);
      expect(rule.priority, 1);
    });

    test('should match event title correctly', () {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'primary',
        eventTitlePattern: 'Focus',
        volumeLevel: 0.1,
        priority: 1,
      );

      expect(rule.matches('Deep Work: Focus'), true);
      expect(rule.matches('Meeting'), false);
    });
  });
}
