import 'package:vocus/features/calendar/models/calendar_event.dart';

class AutomationStatus {
  final bool isEnabled;
  final double currentVolume;
  final List<CalendarEvent> activeEvents;
  final String? lastUpdated;

  AutomationStatus({
    required this.isEnabled,
    required this.currentVolume,
    required this.activeEvents,
    this.lastUpdated,
  });

  bool get isActive => isEnabled && activeEvents.isNotEmpty;
}
