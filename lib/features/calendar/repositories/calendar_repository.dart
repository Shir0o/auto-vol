import 'package:volo/features/calendar/models/calendar_event.dart';
import 'package:googleapis/calendar/v3.dart' as google;

class CalendarRepository {
  final google.CalendarApi _api;

  CalendarRepository(this._api);

  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    final now = DateTime.now();
    final events = await _api.events.list(
      calendarId,
      timeMin: now.toUtc(),
      timeMax: now.add(const Duration(days: 7)).toUtc(),
      singleEvents: true,
    );

    return events.items
            ?.map((e) => CalendarEvent.fromGoogleEvent(e, calendarId))
            .toList() ??
        [];
  }
}
