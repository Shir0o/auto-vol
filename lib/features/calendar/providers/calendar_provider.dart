import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableCalendarsProvider = FutureProvider<List<CalendarEntry>>((ref) async {
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
      data: (calendars) => {calendars.firstWhere((c) => c.isPrimary, orElse: () => calendars.first).id},
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
    await ref.read(sharedPreferencesProvider).setStringList(_storageKey, state.toList());
  }
}

final enabledCalendarIdsProvider = NotifierProvider<EnabledCalendarIdsNotifier, Set<String>>(() {
  return EnabledCalendarIdsNotifier();
});

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final repository = await ref.watch(calendarRepositoryProvider.future);
  final enabledIds = ref.watch(enabledCalendarIdsProvider);

  if (enabledIds.isEmpty) return [];

  final allEvents = await Future.wait(
    enabledIds.map((id) => repository.fetchEvents(id)),
  );

  final flattened = allEvents.expand((e) => e).toList();
  flattened.sort((a, b) => a.startTime.compareTo(b.startTime));
  return flattened;
});
