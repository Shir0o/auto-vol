import 'dart:async';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_rules_provider.g.dart';

@riverpod
class VolumeRules extends _$VolumeRules {
  @override
  FutureOr<List<VolumeRule>> build() async {
    final repository = ref.watch(volumeRulesRepositoryProvider);
    return repository.loadRules();
  }

  Future<void> addRule(VolumeRule rule) async {
    final currentRules = state.value ?? [];
    final updatedRules = [...currentRules, rule];
    state = AsyncData(updatedRules);

    final repository = ref.read(volumeRulesRepositoryProvider);
    await repository.saveRules(updatedRules);
  }

  Future<void> updateRule(VolumeRule rule) async {
    final currentRules = state.value ?? [];
    final updatedRules =
        currentRules.map((r) => r.id == rule.id ? rule : r).toList();
    state = AsyncData(updatedRules);

    final repository = ref.read(volumeRulesRepositoryProvider);
    await repository.saveRules(updatedRules);
  }

  Future<void> deleteRule(String id) async {
    final currentRules = state.value ?? [];
    final updatedRules = currentRules.where((r) => r.id != id).toList();
    state = AsyncData(updatedRules);

    final repository = ref.read(volumeRulesRepositoryProvider);
    await repository.saveRules(updatedRules);
  }
}
