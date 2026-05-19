import 'dart:convert';
import 'dart:developer';

import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:vocus/features/calendar/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _prefs;

  SyncService(this._googleSignIn, this._prefs);

  Future<bool> syncCalendars() async {
    final authService = AuthService(_googleSignIn);
    final user = await authService.signInSilently();

    if (user == null) {
      log('Not authenticated', name: 'SyncService');
      return false;
    }

    final api = await authService.getCalendarApi(user);
    if (api == null) {
      log('Failed to get Calendar API', name: 'SyncService');
      return false;
    }

    final repository = CalendarRepository(api);

    // Get enabled calendar IDs
    final enabledIds = _prefs.getStringList('enabled_calendar_ids') ?? [];
    if (enabledIds.isEmpty) {
      log('No calendars enabled', name: 'SyncService');
      return true;
    }

    try {
      final allEvents = await Future.wait(
        enabledIds.map((id) => repository.fetchEvents(id)),
      );

      final flattened = allEvents.expand((e) => e).toList();

      // Update cache
      await _prefs.setString(
        'cached_events',
        jsonEncode(flattened.map((e) => e.toJson()).toList()),
      );

      log(
        'Successfully synced ${flattened.length} events',
        name: 'SyncService',
      );
      return true;
    } catch (e) {
      log('Error during sync', name: 'SyncService', error: e);
      return false;
    }
  }
}
