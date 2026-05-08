import 'dart:convert';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:vocus/features/calendar/services/background/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/calendar/v3.dart' as google;

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockCalendarApi extends Mock implements google.CalendarApi {}
class MockEventsResource extends Mock implements google.EventsResource {}
class MockEvents extends Mock implements google.Events {}
class MockAuthorizationClient extends Mock implements GoogleSignInAuthorizationClient {}
class MockGoogleSignInClientAuthorization extends Mock implements GoogleSignInClientAuthorization {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockAccount;
  late MockSharedPreferences mockPrefs;
  late MockCalendarApi mockApi;
  late MockEventsResource mockEventsResource;
  late MockEvents mockEvents;
  late MockAuthorizationClient mockAuthClient;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockAccount = MockGoogleSignInAccount();
    mockPrefs = MockSharedPreferences();
    mockApi = MockCalendarApi();
    mockEventsResource = MockEventsResource();
    mockEvents = MockEvents();
    mockAuthClient = MockAuthorizationClient();

    final mockAuth = MockGoogleSignInClientAuthorization();
    when(() => mockAuth.accessToken).thenReturn('fake-token');
    
    when(() => mockGoogleSignIn.attemptLightweightAuthentication())
        .thenAnswer((_) async => mockAccount);
    when(() => mockAccount.authorizationClient).thenReturn(mockAuthClient);
    when(() => mockAuthClient.authorizeScopes(any()))
        .thenAnswer((_) async => mockAuth);
    when(() => mockApi.events).thenReturn(mockEventsResource);
  });

  test('SyncService should return false if authentication fails', () async {
    when(() => mockGoogleSignIn.attemptLightweightAuthentication())
        .thenAnswer((_) async => null);
    
    final service = SyncService(mockGoogleSignIn, mockPrefs);
    final result = await service.syncCalendars();
    
    expect(result, false);
  });

  test('SyncService should return true if no calendars are enabled', () async {
    when(() => mockPrefs.getStringList('enabled_calendar_ids')).thenReturn([]);
    
    final service = SyncService(mockGoogleSignIn, mockPrefs);
    final result = await service.syncCalendars();
    
    expect(result, true);
  });
}
