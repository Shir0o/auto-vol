class VolumeRule {
  final String id;
  final String calendarId;
  final String eventTitlePattern;
  final double volumeLevel;
  final int priority;

  VolumeRule({
    required this.id,
    required this.calendarId,
    required this.eventTitlePattern,
    required this.volumeLevel,
    required this.priority,
  });

  bool matches(String eventTitle) {
    return eventTitle.contains(eventTitlePattern);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'calendarId': calendarId,
      'eventTitlePattern': eventTitlePattern,
      'volumeLevel': volumeLevel,
      'priority': priority,
    };
  }

  factory VolumeRule.fromJson(Map<String, dynamic> json) {
    return VolumeRule(
      id: json['id'] as String,
      calendarId: json['calendarId'] as String,
      eventTitlePattern: json['eventTitlePattern'] as String,
      volumeLevel: (json['volumeLevel'] as num).toDouble(),
      priority: json['priority'] as int,
    );
  }
}
