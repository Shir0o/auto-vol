// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(availableCalendars)
final availableCalendarsProvider = AvailableCalendarsProvider._();

final class AvailableCalendarsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalendarEntry>>,
          List<CalendarEntry>,
          FutureOr<List<CalendarEntry>>
        >
    with
        $FutureModifier<List<CalendarEntry>>,
        $FutureProvider<List<CalendarEntry>> {
  AvailableCalendarsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableCalendarsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableCalendarsHash();

  @$internal
  @override
  $FutureProviderElement<List<CalendarEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CalendarEntry>> create(Ref ref) {
    return availableCalendars(ref);
  }
}

String _$availableCalendarsHash() =>
    r'2f1b1e00abd7f991b3827324f400eb99c09308e8';

@ProviderFor(EnabledCalendarIds)
final enabledCalendarIdsProvider = EnabledCalendarIdsProvider._();

final class EnabledCalendarIdsProvider
    extends $NotifierProvider<EnabledCalendarIds, Set<String>> {
  EnabledCalendarIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledCalendarIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledCalendarIdsHash();

  @$internal
  @override
  EnabledCalendarIds create() => EnabledCalendarIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$enabledCalendarIdsHash() =>
    r'5ef487be9ea6f0278cbc8c6895c282b54e222712';

abstract class _$EnabledCalendarIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(IncludeAllDayEvents)
final includeAllDayEventsProvider = IncludeAllDayEventsProvider._();

final class IncludeAllDayEventsProvider
    extends $NotifierProvider<IncludeAllDayEvents, bool> {
  IncludeAllDayEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'includeAllDayEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$includeAllDayEventsHash();

  @$internal
  @override
  IncludeAllDayEvents create() => IncludeAllDayEvents();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$includeAllDayEventsHash() =>
    r'11fbe9b22c48cbac65109a7e11d202d61db193b4';

abstract class _$IncludeAllDayEvents extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(calendarEvents)
final calendarEventsProvider = CalendarEventsProvider._();

final class CalendarEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalendarEvent>>,
          List<CalendarEvent>,
          FutureOr<List<CalendarEvent>>
        >
    with
        $FutureModifier<List<CalendarEvent>>,
        $FutureProvider<List<CalendarEvent>> {
  CalendarEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<CalendarEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CalendarEvent>> create(Ref ref) {
    return calendarEvents(ref);
  }
}

String _$calendarEventsHash() => r'859003482bc083ca32ac620bd87093cd808413fb';
