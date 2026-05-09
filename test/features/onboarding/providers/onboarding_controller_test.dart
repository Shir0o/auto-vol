import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/onboarding/providers/onboarding_controller.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
  });

  group('OnboardingController', () {
    test('should return false initially if not set in prefs', () {
      when(() => mockPrefs.getBool('onboarding_completed')).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
      addTearDown(container.dispose);

      final isCompleted = container.read(onboardingControllerProvider);
      expect(isCompleted, false);
    });

    test('should return true if set in prefs', () {
      when(() => mockPrefs.getBool('onboarding_completed')).thenReturn(true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
      addTearDown(container.dispose);

      final isCompleted = container.read(onboardingControllerProvider);
      expect(isCompleted, true);
    });

    test('completeOnboarding should update prefs and state', () async {
      when(() => mockPrefs.getBool('onboarding_completed')).thenReturn(false);
      when(() => mockPrefs.setBool('onboarding_completed', true))
          .thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingControllerProvider), false);

      container.read(onboardingControllerProvider.notifier).completeOnboarding();

      expect(container.read(onboardingControllerProvider), true);
      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });
  });
}
