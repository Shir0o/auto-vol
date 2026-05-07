import 'package:volo/features/calendar/models/calendar_event.dart';
import 'package:volo/features/volume/models/volume_rule.dart';

class AutomationService {
  double calculateTargetVolume({
    required List<CalendarEvent> activeEvents,
    required List<VolumeRule> rules,
    required double defaultVolume,
  }) {
    if (activeEvents.isEmpty) {
      return defaultVolume;
    }

    double? highestPriorityVolume;
    int highestPriority = -1;

    for (final event in activeEvents) {
      // Direct event override takes precedence (infinite priority)
      if (event.volumeOverride != null) {
        return event.volumeOverride!;
      }

      // Check rules
      for (final rule in rules) {
        if (rule.calendarId == event.calendarId && rule.matches(event.title)) {
          if (rule.priority > highestPriority) {
            highestPriority = rule.priority;
            highestPriorityVolume = rule.volumeLevel;
          }
        }
      }
    }

    return highestPriorityVolume ?? defaultVolume;
  }
}
