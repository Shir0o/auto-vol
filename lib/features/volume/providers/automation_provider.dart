import 'dart:async';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AutomationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void set(bool value) => state = value;
}

final automationEnabledProvider = NotifierProvider<AutomationEnabledNotifier, bool>(() {
  return AutomationEnabledNotifier();
});

class DefaultVolumeNotifier extends Notifier<double> {
  @override
  double build() => 0.5;

  void set(double value) => state = value;
}

final defaultVolumeProvider = NotifierProvider<DefaultVolumeNotifier, double>(() {
  return DefaultVolumeNotifier();
});

class AutomationNotifier extends Notifier<AutomationStatus> {
  @override
  AutomationStatus build() {
    final enabled = ref.watch(automationEnabledProvider);
    final events = ref.watch(calendarEventsProvider).value ?? [];
    final rules = ref.watch(volumeRulesProvider).value ?? [];
    final defaultVolume = ref.watch(defaultVolumeProvider);

    final now = DateTime.now();
    final activeEvents = events.where((e) => 
      e.startTime.isBefore(now) && e.endTime.isAfter(now)
    ).toList();

    if (!enabled) {
      return AutomationStatus(
        isEnabled: false,
        currentVolume: defaultVolume,
        activeEvents: [],
        lastUpdated: DateFormat('HH:mm:ss').format(now),
      );
    }

    final automationService = ref.read(automationServiceProvider);
    final volumeService = ref.read(volumeServiceProvider);

    final targetVolume = automationService.calculateTargetVolume(
      activeEvents: activeEvents,
      rules: rules,
      defaultVolume: defaultVolume,
    );

    // Side effect: update system volume
    // Using scheduleMicrotask to avoid updating during build
    Future.microtask(() => volumeService.setVolume(targetVolume));

    return AutomationStatus(
      isEnabled: true,
      currentVolume: targetVolume,
      activeEvents: activeEvents,
      lastUpdated: DateFormat('HH:mm:ss').format(now),
    );
  }
}

final automationProvider = NotifierProvider<AutomationNotifier, AutomationStatus>(() {
  return AutomationNotifier();
});
