// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_overrides_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventOverridesRepository)
final eventOverridesRepositoryProvider = EventOverridesRepositoryProvider._();

final class EventOverridesRepositoryProvider
    extends
        $FunctionalProvider<
          EventOverridesRepository,
          EventOverridesRepository,
          EventOverridesRepository
        >
    with $Provider<EventOverridesRepository> {
  EventOverridesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventOverridesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventOverridesRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventOverridesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EventOverridesRepository create(Ref ref) {
    return eventOverridesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventOverridesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventOverridesRepository>(value),
    );
  }
}

String _$eventOverridesRepositoryHash() =>
    r'd6303c21a5200a79a3990940aacd39fb1823dcff';

@ProviderFor(EventOverrides)
final eventOverridesProvider = EventOverridesProvider._();

final class EventOverridesProvider
    extends $AsyncNotifierProvider<EventOverrides, Map<String, double>> {
  EventOverridesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventOverridesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventOverridesHash();

  @$internal
  @override
  EventOverrides create() => EventOverrides();
}

String _$eventOverridesHash() => r'666a93df8f3b3800311b22363dc301e762b901da';

abstract class _$EventOverrides extends $AsyncNotifier<Map<String, double>> {
  FutureOr<Map<String, double>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, double>>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, double>>, Map<String, double>>,
              AsyncValue<Map<String, double>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
