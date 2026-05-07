import 'package:volo/core/providers/common_providers.dart';
import 'package:volo/features/calendar/models/calendar_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final repository = await ref.watch(calendarRepositoryProvider.future);
  // Fetching from primary calendar for now
  return repository.fetchEvents('primary');
});
