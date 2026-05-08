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
  late AutomationService _automationService;
  late VolumeService _volumeService;
  late VolumeRulesRepository _rulesRepository;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    _automationService = AutomationService();
    _volumeService = VolumeService();
    final prefs = await SharedPreferences.getInstance();
    _rulesRepository = VolumeRulesRepository(prefs);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();

    // Load rules
    final rules = await _rulesRepository.loadRules();

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

    final targetVolume = _automationService.calculateTargetVolume(
      activeEvents: activeEvents,
      rules: rules,
      defaultVolume: defaultVolume,
    );

    await _volumeService.setVolume(targetVolume);

    // Update notification
    String statusText = 'Monitoring schedule...';
    if (activeEvents.isNotEmpty) {
      statusText =
          'Active: ${activeEvents.first.title} (${(targetVolume * 100).toInt()}%)';
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
