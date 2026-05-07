import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_vol/features/calendar/services/auth_service.dart';
import 'package:auto_vol/features/calendar/repositories/calendar_repository.dart';
import 'package:auto_vol/features/volume/repositories/volume_rules_repository.dart';
import 'package:auto_vol/features/volume/services/automation_service.dart';
import 'package:auto_vol/features/volume/services/volume_service.dart';

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

final calendarRepositoryProvider = FutureProvider<CalendarRepository>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final api = await authService.getCalendarApi();
  if (api == null) throw Exception('Not authenticated');
  return CalendarRepository(api);
});
