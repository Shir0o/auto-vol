import 'dart:async';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/volume/repositories/event_overrides_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_overrides_provider.g.dart';

@riverpod
EventOverridesRepository eventOverridesRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EventOverridesRepository(prefs);
}

@riverpod
class EventOverrides extends _$EventOverrides {
  @override
  FutureOr<Map<String, double>> build() async {
    final repository = ref.watch(eventOverridesRepositoryProvider);
    return repository.loadOverrides();
  }

  Future<void> setOverride(String eventId, double volume) async {
    final currentOverrides = state.value ?? {};
    final updatedOverrides = Map<String, double>.from(currentOverrides);
    updatedOverrides[eventId] = volume;
    state = AsyncData(updatedOverrides);

    final repository = ref.read(eventOverridesRepositoryProvider);
    await repository.saveOverrides(updatedOverrides);
  }

  Future<void> removeOverride(String eventId) async {
    final currentOverrides = state.value ?? {};
    final updatedOverrides = Map<String, double>.from(currentOverrides);
    updatedOverrides.remove(eventId);
    state = AsyncData(updatedOverrides);

    final repository = ref.read(eventOverridesRepositoryProvider);
    await repository.saveOverrides(updatedOverrides);
  }
}
