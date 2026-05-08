// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_rules_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VolumeRules)
final volumeRulesProvider = VolumeRulesProvider._();

final class VolumeRulesProvider
    extends $AsyncNotifierProvider<VolumeRules, List<VolumeRule>> {
  VolumeRulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'volumeRulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$volumeRulesHash();

  @$internal
  @override
  VolumeRules create() => VolumeRules();
}

String _$volumeRulesHash() => r'8fd23b58bf096895fcdf4841eadb66ab9190af5a';

abstract class _$VolumeRules extends $AsyncNotifier<List<VolumeRule>> {
  FutureOr<List<VolumeRule>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<VolumeRule>>, List<VolumeRule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<VolumeRule>>, List<VolumeRule>>,
              AsyncValue<List<VolumeRule>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
