import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/volume/repositories/volume_rules_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// The callback function for the background task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundTaskHandler extends TaskHandler {
  AutomationService? _automationService;
  VolumeService? _volumeService;
  VolumeRulesRepository? _rulesRepository;

  void setDependencies({
    AutomationService? automationService,
    VolumeService? volumeService,
    VolumeRulesRepository? rulesRepository,
  }) {
    _automationService = automationService;
    _volumeService = volumeService;
    _rulesRepository = rulesRepository;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    _automationService ??= AutomationService();
    _volumeService ??= VolumeService();
    final prefs = await SharedPreferences.getInstance();
    _rulesRepository ??= VolumeRulesRepository(prefs);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final automationService = _automationService ?? AutomationService();
    final volumeService = _volumeService ?? VolumeService();
    final rulesRepository = _rulesRepository ?? VolumeRulesRepository(prefs);

    // Load rules
    final rules = await rulesRepository.loadRules();

    // Load cached events (synced by main isolate)
    final eventsJson = prefs.getString('cached_events');
    if (eventsJson == null) return;

    final List<dynamic> decoded = jsonDecode(eventsJson);
    final events = decoded.map((e) => CalendarEvent.fromJson(e)).toList();

    final defaultVolume = prefs.getDouble('default_volume') ?? 0.5;

    final now = DateTime.now();
    final activeEvents = events
        .where((e) => e.startTime.isBefore(now) && e.endTime.isAfter(now))
        .toList();

    final result = automationService.calculateTargetVolume(
      activeEvents: activeEvents,
      rules: rules,
      defaultVolume: defaultVolume,
    );

    // Snapshot and restore logic for multiple streams
    final automateRinger = prefs.getBool('automate_ringer') ?? false;
    final automateNotification =
        prefs.getBool('automate_notification') ?? false;
    final automateDnd = prefs.getBool('automate_dnd') ?? false;

    final streams = [
      VolumeStream.media,
      if (automateRinger) VolumeStream.ringer,
      if (automateNotification) VolumeStream.notification,
    ];

    if (activeEvents.isNotEmpty) {
      // Handle DND
      final dndSnapshot = prefs.getBool('dnd_snapshot');
      if (automateDnd && dndSnapshot == null) {
        final isDnd = await volumeService.isDndEnabled();
        await prefs.setBool('dnd_snapshot', isDnd);
        await volumeService.setDndMode(true);
      }

      for (final stream in streams) {
        final snapshot = prefs.getDouble('volume_snapshot_${stream.name}');
        if (snapshot == null) {
          final current = await volumeService.getVolume(stream: stream);
          if (current != null) {
            await prefs.setDouble('volume_snapshot_${stream.name}', current);
          }
        }
        await volumeService.setVolume(result.volume, stream: stream);
      }
    } else {
      // Restore DND
      final dndSnapshot = prefs.getBool('dnd_snapshot');
      if (dndSnapshot != null) {
        await volumeService.setDndMode(dndSnapshot);
        await prefs.remove('dnd_snapshot');
      }

      // Check if we have any snapshots to restore
      for (final stream in VolumeStream.values) {
        final snapshot = prefs.getDouble('volume_snapshot_${stream.name}');
        if (snapshot != null) {
          await volumeService.setVolume(snapshot, stream: stream);
          await prefs.remove('volume_snapshot_${stream.name}');
        }
      }
    }

    // Update notification
    String statusText = 'Monitoring schedule...';
    if (activeEvents.isNotEmpty) {
      statusText =
          'Active: ${result.winningEvent?.title ?? activeEvents.first.title} (${(result.volume * 100).toInt()}%)';
    }

    FlutterForegroundTask.updateService(
      notificationTitle: 'Vocus Automation Active',
      notificationText: statusText,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Clean up if needed
  }
}

class VocusForegroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vocus_automation',
        channelName: 'Vocus Automation',
        channelDescription: 'Maintains volume automation in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          60000,
        ), // Check every minute
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Vocus Automation',
      notificationText: 'Starting background monitoring...',
      callback: startCallback,
    );

    return result is ServiceRequestSuccess;
  }

  static Future<bool> stop() async {
    final result = await FlutterForegroundTask.stopService();
    return result is ServiceRequestSuccess;
  }
}

class ForegroundServiceWrapper {
  Future<void> init() => VocusForegroundService.init();
  Future<bool> start() => VocusForegroundService.start();
  Future<bool> stop() => VocusForegroundService.stop();
}
