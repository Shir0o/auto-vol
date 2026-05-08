import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';

class AutomationResult {
  final double volume;
  final CalendarEvent? winningEvent;
  final VolumeRule? winningRule;
  final bool isDefault;

  AutomationResult({
    required this.volume,
    this.winningEvent,
    this.winningRule,
    this.isDefault = false,
  });
}

class AutomationService {
  AutomationResult calculateTargetVolume({
    required List<CalendarEvent> activeEvents,
    required List<VolumeRule> rules,
    required double defaultVolume,
  }) {
    if (activeEvents.isEmpty) {
      return AutomationResult(volume: defaultVolume, isDefault: true);
    }

    CalendarEvent? winningEvent;
    VolumeRule? winningRule;
    double? highestPriorityVolume;
    int highestPriority = -1;

    for (final event in activeEvents) {
      // Direct event override takes precedence (infinite priority)
      if (event.volumeOverride != null) {
        return AutomationResult(
          volume: event.volumeOverride!,
          winningEvent: event,
        );
      }

      // Check rules
      for (final rule in rules) {
        if (rule.calendarId == event.calendarId && rule.matches(event.title)) {
          if (rule.priority > highestPriority) {
            highestPriority = rule.priority;
            highestPriorityVolume = rule.volumeLevel;
            winningEvent = event;
            winningRule = rule;
          }
        }
      }
    }

    if (highestPriorityVolume != null) {
      return AutomationResult(
        volume: highestPriorityVolume,
        winningEvent: winningEvent,
        winningRule: winningRule,
      );
    }

    return AutomationResult(volume: defaultVolume, isDefault: true);
  }
}
