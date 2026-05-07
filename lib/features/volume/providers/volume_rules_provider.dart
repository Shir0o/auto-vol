import 'dart:async';
import 'package:volo/core/providers/common_providers.dart';
import 'package:volo/features/volume/models/volume_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VolumeRulesNotifier extends AsyncNotifier<List<VolumeRule>> {
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

  Future<void> deleteRule(String id) async {
    final currentRules = state.value ?? [];
    final updatedRules = currentRules.where((r) => r.id != id).toList();
    state = AsyncData(updatedRules);

    final repository = ref.read(volumeRulesRepositoryProvider);
    await repository.saveRules(updatedRules);
  }
}

final volumeRulesProvider = AsyncNotifierProvider<VolumeRulesNotifier, List<VolumeRule>>(() {
  return VolumeRulesNotifier();
});
