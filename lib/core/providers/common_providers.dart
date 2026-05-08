import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/services/permission_service.dart';
import 'package:vocus/features/calendar/services/auth_service.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:vocus/features/volume/repositories/volume_rules_repository.dart';
import 'package:vocus/features/volume/services/automation_service.dart';
import 'package:vocus/features/volume/services/volume_service.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'common_providers.g.dart';

@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) {
  return GoogleSignIn.instance;
}

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService(ref.watch(googleSignInProvider));
}

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError();
}

@Riverpod(keepAlive: true)
VolumeRulesRepository volumeRulesRepository(Ref ref) {
  return VolumeRulesRepository(ref.watch(sharedPreferencesProvider));
}

@Riverpod(keepAlive: true)
VolumeService volumeService(Ref ref) {
  return VolumeService();
}

@Riverpod(keepAlive: true)
AutomationService automationService(Ref ref) {
  return AutomationService();
}

@Riverpod(keepAlive: true)
ForegroundServiceWrapper foregroundService(Ref ref) {
  return ForegroundServiceWrapper();
}

@Riverpod(keepAlive: true)
PermissionService permissionService(Ref ref) {
  return PermissionService();
}

@riverpod
Stream<DateTime> tick(Ref ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
}

@riverpod
Stream<DateTime> calendarRefreshTick(Ref ref) {
  return Stream.periodic(const Duration(minutes: 15), (_) => DateTime.now());
}

@riverpod
Future<bool> notificationPolicyAccess(Ref ref) {
  return ref.watch(permissionServiceProvider).hasNotificationPolicyAccess();
}

@riverpod
Future<bool> ignoreBatteryOptimizations(Ref ref) {
  return ref.watch(permissionServiceProvider).isIgnoringBatteryOptimizations();
}

@riverpod
Future<CalendarRepository> calendarRepository(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  final service = ref.read(authServiceProvider);
  final api = await service.getCalendarApi(user);
  if (api == null) throw Exception('Failed to get API');
  return CalendarRepository(api);
}
