import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_provider.g.dart';

@riverpod
Future<List<CalendarEntry>> availableCalendars(Ref ref) async {
  final repository = await ref.watch(calendarRepositoryProvider.future);
  return repository.fetchCalendars();
}

@riverpod
class EnabledCalendarIds extends _$EnabledCalendarIds {
  static const _storageKey = 'enabled_calendar_ids';

  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      return stored.toSet();
    }

    final availableAsync = ref.watch(availableCalendarsProvider);
    return availableAsync.when(
      data: (calendars) => calendars.isEmpty
          ? {}
          : {
              calendars
                  .firstWhere((c) => c.isPrimary, orElse: () => calendars.first)
                  .id,
            },
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );
  }

  Future<void> toggle(String id) async {
    final newState = Set<String>.from(state);
    if (newState.contains(id)) {
      newState.remove(id);
    } else {
      newState.add(id);
    }
    state = newState;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(_storageKey, state.toList());
  }
}

@riverpod
class IncludeAllDayEvents extends _$IncludeAllDayEvents {
  static const _storageKey = 'include_all_day_events';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_storageKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_storageKey, state);
  }
}

@riverpod
Future<List<CalendarEvent>> calendarEvents(Ref ref) async {
  ref.watch(calendarRefreshTickProvider);
  final repository = await ref.watch(calendarRepositoryProvider.future);
  final enabledIds = ref.watch(enabledCalendarIdsProvider);
  final includeAllDay = ref.watch(includeAllDayEventsProvider);
  final availableCalendarsList = await ref.watch(
    availableCalendarsProvider.future,
  );
  final overridesAsync = ref.watch(eventOverridesProvider);

  if (enabledIds.isEmpty) return <CalendarEvent>[];

  final calendarMap = {for (var c in availableCalendarsList) c.id: c};

  final List<Future<List<CalendarEvent>>> fetchFutures = enabledIds.map((
    String id,
  ) {
    final cal = calendarMap[id];
    return repository.fetchEvents(
      id,
      calendarTitle: cal?.title,
      calendarColor: cal?.color,
    );
  }).toList();

  final List<List<CalendarEvent>> allEventsResults =
      await Future.wait<List<CalendarEvent>>(fetchFutures);

  final List<CalendarEvent> flattened = allEventsResults
      .expand((e) => e)
      .toList();

  final Map<String, double> overrides = overridesAsync.value ?? {};
  final List<CalendarEvent> withOverrides = flattened.map<CalendarEvent>((
    event,
  ) {
    if (overrides.containsKey(event.id)) {
      return event.copyWith(volumeOverride: overrides[event.id]);
    }
    return event;
  }).toList();

  final List<CalendarEvent> filtered = includeAllDay
      ? withOverrides
      : withOverrides.where((e) => !e.isAllDay).toList();

  filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
  return filtered;
}
