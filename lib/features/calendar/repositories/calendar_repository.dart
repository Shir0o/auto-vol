import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:googleapis/calendar/v3.dart' as google;

class CalendarRepository {
  final google.CalendarApi _api;

  CalendarRepository(this._api);

  Future<List<CalendarEntry>> fetchCalendars() async {
    final calendarList = await _api.calendarList.list();
    return calendarList.items?.map((item) {
          return CalendarEntry(
            id: item.id ?? '',
            title: item.summary ?? 'No Title',
            description: item.description,
            isPrimary: item.primary ?? false,
            color: item.backgroundColor,
          );
        }).toList() ??
        [];
  }

  Future<List<CalendarEvent>> fetchEvents(String calendarId, {String? calendarTitle, String? calendarColor}) async {
    final now = DateTime.now();
    final events = await _api.events.list(
      calendarId,
      timeMin: now.toUtc(),
      timeMax: now.add(const Duration(days: 7)).toUtc(),
      singleEvents: true,
    );

    return events.items
            ?.map((e) => CalendarEvent.fromGoogleEvent(
                  e,
                  calendarId,
                  calendarTitle: calendarTitle,
                  calendarColor: calendarColor,
                ))
            .toList() ??
        [];
  }
}
