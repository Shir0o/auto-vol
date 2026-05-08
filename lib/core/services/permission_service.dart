import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestInitialPermissions() async {
    await [Permission.notification].request();
  }

  Future<bool> hasNotificationPolicyAccess() async {
    return await Permission.accessNotificationPolicy.isGranted;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> requestNotificationPolicyAccess() async {
    await Permission.accessNotificationPolicy.request();
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await Permission.ignoreBatteryOptimizations.request();
  }
  
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}
