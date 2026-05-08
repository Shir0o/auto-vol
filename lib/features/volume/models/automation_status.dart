import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';

class AutomationStatus {
  final bool isEnabled;
  final double currentVolume;
  final List<CalendarEvent> activeEvents;
  final CalendarEvent? winningEvent;
  final VolumeRule? winningRule;
  final String? lastUpdated;

  AutomationStatus({
    required this.isEnabled,
    required this.currentVolume,
    required this.activeEvents,
    this.winningEvent,
    this.winningRule,
    this.lastUpdated,
  });

  bool get isActive => isEnabled && activeEvents.isNotEmpty;
}
