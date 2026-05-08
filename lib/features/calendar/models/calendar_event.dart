import 'package:googleapis/calendar/v3.dart' as google;

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String calendarId;
  final String? calendarTitle;
  final String? calendarColor;
  final double? volumeOverride;
  final bool isAllDay;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.calendarId,
    this.calendarTitle,
    this.calendarColor,
    this.volumeOverride,
    this.isAllDay = false,
  });

  factory CalendarEvent.fromGoogleEvent(google.Event event, String calendarId,
      {String? calendarTitle, String? calendarColor}) {
    final isAllDay = event.start?.dateTime == null && event.start?.date != null;

    return CalendarEvent(
      id: event.id ?? '',
      title: event.summary ?? 'No Title',
      description: event.description,
      startTime: (event.start?.dateTime ?? event.start?.date ?? DateTime.now()).toLocal(),
      endTime: (event.end?.dateTime ?? event.end?.date ?? DateTime.now()).toLocal(),
      calendarId: calendarId,
      calendarTitle: calendarTitle,
      calendarColor: calendarColor,
      isAllDay: isAllDay,
    );
  }
}
