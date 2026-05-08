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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'calendarId': calendarId,
      'calendarTitle': calendarTitle,
      'calendarColor': calendarColor,
      'volumeOverride': volumeOverride,
      'isAllDay': isAllDay,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      calendarId: json['calendarId'] as String,
      calendarTitle: json['calendarTitle'] as String?,
      calendarColor: json['calendarColor'] as String?,
      volumeOverride: json['volumeOverride'] as double?,
      isAllDay: json['isAllDay'] as bool? ?? false,
    );
  }

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
