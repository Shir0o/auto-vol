import 'package:vocus/features/calendar/services/background/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockAuthorizationClient extends Mock
    implements GoogleSignInAuthorizationClient {}

class MockGoogleSignInClientAuthorization extends Mock
    implements GoogleSignInClientAuthorization {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockAccount;
  late MockSharedPreferences mockPrefs;
  late MockAuthorizationClient mockAuthClient;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockAccount = MockGoogleSignInAccount();
    mockPrefs = MockSharedPreferences();
    mockAuthClient = MockAuthorizationClient();

    final mockAuth = MockGoogleSignInClientAuthorization();
    when(() => mockAuth.accessToken).thenReturn('fake-token');

    when(
      () => mockGoogleSignIn.attemptLightweightAuthentication(),
    ).thenAnswer((_) async => mockAccount);
    when(() => mockAccount.authorizationClient).thenReturn(mockAuthClient);
    when(
      () => mockAuthClient.authorizeScopes(any()),
    ).thenAnswer((_) async => mockAuth);
  });

  test('SyncService should return false if authentication fails', () async {
    when(
      () => mockGoogleSignIn.attemptLightweightAuthentication(),
    ).thenAnswer((_) async => null);

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
