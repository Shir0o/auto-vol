import 'dart:async';
import 'dart:convert';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';

part 'automation_provider.g.dart';

@riverpod
class AutomationEnabled extends _$AutomationEnabled {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('automation_enabled') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('automation_enabled', value);
    final service = ref.read(foregroundServiceProvider);
    if (value) {
      service.start();
    } else {
      service.stop();
    }
  }
}

@riverpod
class DefaultVolume extends _$DefaultVolume {
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

@riverpod
class AutomateRinger extends _$AutomateRinger {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('automate_ringer') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('automate_ringer', value);
  }
}

@riverpod
class AutomateNotification extends _$AutomateNotification {
  @override
  bool build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getBool('automate_notification') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('automate_notification', value);
  }
}

@riverpod
class AutomateDnd extends _$AutomateDnd {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool('automate_dnd') ??
        false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('automate_dnd', value);
  }
}

@riverpod
class VolumeSnapshot extends _$VolumeSnapshot {
  @override
  Map<VolumeStream, double> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final snapshots = <VolumeStream, double>{};

    for (final stream in VolumeStream.values) {
      final val = prefs.getDouble('volume_snapshot_${stream.name}');
      if (val != null) snapshots[stream] = val;
    }
    return snapshots;
  }

  void set(VolumeStream stream, double? value) {
    final newState = Map<VolumeStream, double>.from(state);
    if (value == null) {
      newState.remove(stream);
      ref
          .read(sharedPreferencesProvider)
          .remove('volume_snapshot_${stream.name}');
    } else {
      newState[stream] = value;
      ref
          .read(sharedPreferencesProvider)
          .setDouble('volume_snapshot_${stream.name}', value);
    }
    state = newState;
  }

  void clearAll() {
    state = <VolumeStream, double>{};
    for (final stream in VolumeStream.values) {
      ref
          .read(sharedPreferencesProvider)
          .remove('volume_snapshot_${stream.name}');
    }
  }
}

@riverpod
class DndSnapshot extends _$DndSnapshot {
  @override
  bool? build() {
    return ref.watch(sharedPreferencesProvider).getBool('dnd_snapshot');
  }

  void set(bool? value) {
    state = value;
    if (value == null) {
      ref.read(sharedPreferencesProvider).remove('dnd_snapshot');
    } else {
      ref.read(sharedPreferencesProvider).setBool('dnd_snapshot', value);
    }
  }
}

@riverpod
class Automation extends _$Automation {
  @override
  AutomationStatus build() {
    ref.watch(tickProvider);
    final enabled = ref.watch(automationEnabledProvider);
    final automateRinger = ref.watch(automateRingerProvider);
    final automateNotification = ref.watch(automateNotificationProvider);
    final automateDnd = ref.watch(automateDndProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final events = eventsAsync.value ?? [];
    final rules = ref.watch(volumeRulesProvider).value ?? [];
    final defaultVol = ref.watch(defaultVolumeProvider);
    final snapshots = ref.watch(volumeSnapshotProvider);
    final dndSnap = ref.watch(dndSnapshotProvider);

    final prefs = ref.read(sharedPreferencesProvider);

    if (eventsAsync.hasValue) {
      prefs.setString(
        'cached_events',
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );
    }
    prefs.setDouble('default_volume', defaultVol);

    final now = DateTime.now();
    final activeEvents = events
        .where((e) => e.startTime.isBefore(now) && e.endTime.isAfter(now))
        .toList();

    if (!enabled) {
      return AutomationStatus(
        isEnabled: false,
        currentVolume: defaultVol,
        activeEvents: [],
        lastUpdated: DateFormat('HH:mm:ss').format(now),
      );
    }

    final automationService = ref.read(automationServiceProvider);
    final volumeService = ref.read(volumeServiceProvider);

    final result = automationService.calculateTargetVolume(
      activeEvents: activeEvents,
      rules: rules,
      defaultVolume: defaultVol,
    );

    Future.microtask(() async {
      final streams = [
        VolumeStream.media,
        if (automateRinger) VolumeStream.ringer,
        if (automateNotification) VolumeStream.notification,
      ];

      if (activeEvents.isNotEmpty) {
        if (automateDnd && dndSnap == null) {
          final isDnd = await volumeService.isDndEnabled();
          ref.read(dndSnapshotProvider.notifier).set(isDnd);
          await volumeService.setDndMode(true);
        }

        for (final stream in streams) {
          if (!snapshots.containsKey(stream)) {
            final current = await volumeService.getVolume(stream: stream);
            if (current != null) {
              ref.read(volumeSnapshotProvider.notifier).set(stream, current);
            }
          }
          await volumeService.setVolume(result.volume, stream: stream);
        }
      } else {
        if (dndSnap != null) {
          await volumeService.setDndMode(dndSnap);
          ref.read(dndSnapshotProvider.notifier).set(null);
        }

        if (snapshots.isNotEmpty) {
          for (final entry in snapshots.entries) {
            await volumeService.setVolume(entry.value, stream: entry.key);
          }
          ref.read(volumeSnapshotProvider.notifier).clearAll();
        } else {
          for (final stream in streams) {
            await volumeService.setVolume(defaultVol, stream: stream);
          }
        }
      }
    });

    return AutomationStatus(
      isEnabled: true,
      currentVolume: activeEvents.isEmpty && snapshots.isNotEmpty
          ? snapshots[VolumeStream.media] ?? result.volume
          : result.volume,
      activeEvents: activeEvents,
      winningEvent: result.winningEvent,
      winningRule: result.winningRule,
      lastUpdated: DateFormat('HH:mm:ss').format(now),
    );
  }
}
