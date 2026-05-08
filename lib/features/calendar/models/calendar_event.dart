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
  });

  factory CalendarEvent.fromGoogleEvent(google.Event event, String calendarId,
      {String? calendarTitle, String? calendarColor}) {
    return CalendarEvent(
      id: event.id ?? '',
      title: event.summary ?? 'No Title',
      description: event.description,
      startTime: (event.start?.dateTime ?? event.start?.date ?? DateTime.now()).toLocal(),
      endTime: (event.end?.dateTime ?? event.end?.date ?? DateTime.now()).toLocal(),
      calendarId: calendarId,
      calendarTitle: calendarTitle,
      calendarColor: calendarColor,
    );
  }
}
