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

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? calendarId,
    String? calendarTitle,
    String? calendarColor,
    double? volumeOverride,
    bool? isAllDay,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      calendarId: calendarId ?? this.calendarId,
      calendarTitle: calendarTitle ?? this.calendarTitle,
      calendarColor: calendarColor ?? this.calendarColor,
      volumeOverride: volumeOverride ?? this.volumeOverride,
      isAllDay: isAllDay ?? this.isAllDay,
    );
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

  factory CalendarEvent.fromGoogleEvent(
    google.Event event,
    String calendarId, {
    String? calendarTitle,
    String? calendarColor,
  }) {
    final isAllDay = event.start?.dateTime == null && event.start?.date != null;
    final summary = event.summary ?? 'No Title';
    final description = event.description;

    // Parse volume override from summary first, then description
    double? volumeOverride = parseVolumeOverride(summary);
    if (volumeOverride == null && description != null) {
      volumeOverride = parseVolumeOverride(description);
    }

    return CalendarEvent(
      id: event.id ?? '',
      title: summary,
      description: description,
      startTime: (event.start?.dateTime ?? event.start?.date ?? DateTime.now())
          .toLocal(),
      endTime: (event.end?.dateTime ?? event.end?.date ?? DateTime.now())
          .toLocal(),
      calendarId: calendarId,
      calendarTitle: calendarTitle,
      calendarColor: calendarColor,
      volumeOverride: volumeOverride,
      isAllDay: isAllDay,
    );
  }

  static double? parseVolumeOverride(String text) {
    // Check for [vol:0.5] or [vol:20%]
    final volRegExp = RegExp(r'\[vol:(\d+(\.\d+)?)%?\]');
    final match = volRegExp.firstMatch(text);
    if (match != null) {
      final valueStr = match.group(1)!;
      final isPercentage = match.group(0)!.contains('%');
      double value = double.parse(valueStr);
      return (isPercentage ? value / 100.0 : value).clamp(0.0, 1.0);
    }

    final lowerText = text.toLowerCase();
    if (lowerText.contains('!silent')) return 0.0;
    if (lowerText.contains('!mute')) return 0.0;
    if (lowerText.contains('!loud')) return 1.0;

    return null;
  }
}
