import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableCalendarsProvider = FutureProvider<List<CalendarEntry>>((
  ref,
) async {
  final repository = await ref.watch(calendarRepositoryProvider.future);
  return repository.fetchCalendars();
});

class EnabledCalendarIdsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'enabled_calendar_ids';

  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getStringList(_storageKey);
    if (stored != null) {
      return stored.toSet();
    }

    // Default: only primary calendar if nothing stored
    final availableAsync = ref.watch(availableCalendarsProvider);
    return availableAsync.when(
      data: (calendars) => calendars.isEmpty
          ? {}
          : {
              calendars
                  .firstWhere((c) => c.isPrimary, orElse: () => calendars.first)
                  .id,
            },
      loading: () => {},
      error: (_, __) => {},
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

class IncludeAllDayEventsNotifier extends Notifier<bool> {
  static const _storageKey = 'include_all_day_events';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_storageKey) ?? true; // Default to true
  }

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_storageKey, state);
  }
}

final includeAllDayEventsProvider =
    NotifierProvider<IncludeAllDayEventsNotifier, bool>(() {
      return IncludeAllDayEventsNotifier();
    });

final enabledCalendarIdsProvider =
    NotifierProvider<EnabledCalendarIdsNotifier, Set<String>>(() {
      return EnabledCalendarIdsNotifier();
    });

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  ref.watch(calendarRefreshTickProvider); // Watch periodic refresh tick
  final repository = await ref.watch(calendarRepositoryProvider.future);
  final enabledIds = ref.watch(enabledCalendarIdsProvider);
  final includeAllDay = ref.watch(includeAllDayEventsProvider);
  final availableAsync = await ref.watch(availableCalendarsProvider.future);
  final overridesAsync = ref.watch(eventOverridesProvider);

  if (enabledIds.isEmpty) return [];

  final calendarMap = {for (var c in availableAsync) c.id: c};

  final allEvents = await Future.wait(
    enabledIds.map((id) {
      final cal = calendarMap[id];
      return repository.fetchEvents(
        id,
        calendarTitle: cal?.title,
        calendarColor: cal?.color,
      );
    }),
  );

  final flattened = allEvents.expand((e) => e).toList();

  // Apply overrides
  final overrides = overridesAsync.value ?? {};
  final withOverrides = flattened.map((event) {
    if (overrides.containsKey(event.id)) {
      return event.copyWith(volumeOverride: overrides[event.id]);
    }
    return event;
  }).toList();

  // Filter all-day events if not included
  final filtered = includeAllDay
      ? withOverrides
      : withOverrides.where((e) => !e.isAllDay).toList();

  filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
  return filtered;
});
