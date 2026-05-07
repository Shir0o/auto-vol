import 'dart:convert';
import 'package:auto_vol/features/volume/models/volume_rule.dart';
import 'package:auto_vol/features/volume/repositories/volume_rules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late VolumeRulesRepository repository;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = VolumeRulesRepository(mockPrefs);
  });

  group('VolumeRulesRepository', () {
    test('should load rules from shared preferences', () async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'c1',
        eventTitlePattern: 'p1',
        volumeLevel: 0.5,
        priority: 1,
      );
      
      final ruleJson = jsonEncode({
        'id': '1',
        'calendarId': 'c1',
        'eventTitlePattern': 'p1',
        'volumeLevel': 0.5,
        'priority': 1,
      });

      when(() => mockPrefs.getStringList(any())).thenReturn([ruleJson]);

      final rules = await repository.loadRules();

      expect(rules.length, 1);
      expect(rules.first.id, '1');
      expect(rules.first.volumeLevel, 0.5);
    });

    test('should save rules to shared preferences', () async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'c1',
        eventTitlePattern: 'p1',
        volumeLevel: 0.5,
        priority: 1,
      );

      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);

      await repository.saveRules([rule]);

      verify(() => mockPrefs.setStringList(any(), any())).called(1);
    });
  });
}
