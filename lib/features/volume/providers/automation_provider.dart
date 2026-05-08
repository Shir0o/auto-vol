import 'dart:async';
import 'dart:convert';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AutomationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('automation_enabled') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('automation_enabled', value);
    final foregroundService = ref.read(foregroundServiceProvider);
    if (value) {
      foregroundService.start();
    } else {
      foregroundService.stop();
    }
  }
}

final automationEnabledProvider =
    NotifierProvider<AutomationEnabledNotifier, bool>(() {
      return AutomationEnabledNotifier();
    });

class DefaultVolumeNotifier extends Notifier<double> {
  @override
  double build() {
    return ref.watch(sharedPreferencesProvider).getDouble('default_volume') ??
        0.5;
  }

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble('default_volume', value);
  }
}

final defaultVolumeProvider = NotifierProvider<DefaultVolumeNotifier, double>(
  () {
    return DefaultVolumeNotifier();
  },
);

class VolumeSnapshotNotifier extends Notifier<double?> {
  @override
  double? build() {
    return ref.watch(sharedPreferencesProvider).getDouble('volume_snapshot');
  }

  void set(double? value) {
    state = value;
    if (value == null) {
      ref.read(sharedPreferencesProvider).remove('volume_snapshot');
    } else {
      ref.read(sharedPreferencesProvider).setDouble('volume_snapshot', value);
    }
  }
}

final volumeSnapshotProvider =
    NotifierProvider<VolumeSnapshotNotifier, double?>(() {
      return VolumeSnapshotNotifier();
    });

class AutomationNotifier extends Notifier<AutomationStatus> {
  @override
  AutomationStatus build() {
    ref.watch(tickProvider); // Watch the periodic tick
    final enabled = ref.watch(automationEnabledProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final events = eventsAsync.value ?? [];
    final rules = ref.watch(volumeRulesProvider).value ?? [];
    final defaultVolume = ref.watch(defaultVolumeProvider);
    final snapshot = ref.watch(volumeSnapshotProvider);

    // Sync to SharedPreferences for background service
    final prefs = ref.read(sharedPreferencesProvider);

    // Only sync if data is actually available to avoid clearing cache during loading
    if (eventsAsync.hasValue) {
      prefs.setString(
        'cached_events',
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );
    }
    prefs.setDouble('default_volume', defaultVolume);

    final now = DateTime.now();
    final activeEvents =
        events
            .where((e) => e.startTime.isBefore(now) && e.endTime.isAfter(now))
            .toList();

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

    final result = automationService.calculateTargetVolume(
      activeEvents: activeEvents,
      rules: rules,
      defaultVolume: defaultVolume,
    );

    // Side effect: update system volume with snapshot/restore logic
    Future.microtask(() async {
      if (activeEvents.isNotEmpty) {
        if (snapshot == null) {
          // First time entering automation - snapshot current volume
          final current = await volumeService.getVolume();
          ref.read(volumeSnapshotProvider.notifier).set(current);
        }
        await volumeService.setVolume(result.volume);
      } else {
        if (snapshot != null) {
          // Leaving automation - restore snapshotted volume
          await volumeService.setVolume(snapshot);
          ref.read(volumeSnapshotProvider.notifier).set(null);
        } else {
          // No active events and no snapshot - use default
          await volumeService.setVolume(defaultVolume);
        }
      }
    });

    return AutomationStatus(
      isEnabled: true,
      currentVolume:
          activeEvents.isEmpty && snapshot != null ? snapshot : result.volume,
      activeEvents: activeEvents,
      winningEvent: result.winningEvent,
      winningRule: result.winningRule,
      lastUpdated: DateFormat('HH:mm:ss').format(now),
    );
  }
}

final automationProvider =
    NotifierProvider<AutomationNotifier, AutomationStatus>(() {
      return AutomationNotifier();
    });
