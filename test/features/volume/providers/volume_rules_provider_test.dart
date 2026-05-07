import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/repositories/volume_rules_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVolumeRulesRepository extends Mock implements VolumeRulesRepository {}

void main() {
  late MockVolumeRulesRepository mockRepository;

  setUp(() {
    mockRepository = MockVolumeRulesRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        volumeRulesRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('VolumeRulesNotifier', () {
    test('should load rules on initialization', () async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'c1',
        eventTitlePattern: 'p1',
        volumeLevel: 0.5,
        priority: 1,
      );
      
      when(() => mockRepository.loadRules()).thenAnswer((_) async => [rule]);

      final container = createContainer();
      
      // Wait for the async initialization
      await container.read(volumeRulesProvider.notifier).future;

      expect(container.read(volumeRulesProvider).value, [rule]);
    });

    test('addRule should save rule to repository', () async {
      final rule = VolumeRule(
        id: '1',
        calendarId: 'c1',
        eventTitlePattern: 'p1',
        volumeLevel: 0.5,
        priority: 1,
      );

      when(() => mockRepository.loadRules()).thenAnswer((_) async => []);
      when(() => mockRepository.saveRules(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(volumeRulesProvider.notifier).future;

      await container.read(volumeRulesProvider.notifier).addRule(rule);

      expect(container.read(volumeRulesProvider).value, [rule]);
      verify(() => mockRepository.saveRules([rule])).called(1);
    });
  });
}
