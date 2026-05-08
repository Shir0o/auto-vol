import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import 'package:googleapis/calendar/v3.dart' as google;

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(googleSignInProvider));
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final volumeRulesRepositoryProvider = Provider<VolumeRulesRepository>((ref) {
  return VolumeRulesRepository(ref.watch(sharedPreferencesProvider));
});

final volumeServiceProvider = Provider<VolumeService>((ref) {
  return VolumeService();
});

final automationServiceProvider = Provider<AutomationService>((ref) {
  return AutomationService();
});

final foregroundServiceProvider = Provider<ForegroundServiceWrapper>((ref) {
  return ForegroundServiceWrapper();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final notificationPolicyAccessProvider = FutureProvider<bool>((ref) {
  return ref.watch(permissionServiceProvider).hasNotificationPolicyAccess();
});

final ignoreBatteryOptimizationsProvider = FutureProvider<bool>((ref) {
  return ref.watch(permissionServiceProvider).isIgnoringBatteryOptimizations();
});

final calendarRepositoryProvider = FutureProvider<CalendarRepository>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('Not authenticated');

  final authService = ref.read(authServiceProvider);
  final api = await authService.getCalendarApi(user);
  if (api == null) throw Exception('Failed to get API');
  return CalendarRepository(api);
});
