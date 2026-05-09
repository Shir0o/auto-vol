import 'package:vocus/core/providers/common_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('onboarding_completed') ?? false;
  }

  void completeOnboarding() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('onboarding_completed', true);
    state = true;
  }
}
