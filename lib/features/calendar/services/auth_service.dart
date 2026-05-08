import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:http/http.dart' as http;

class AuthService {
  final GoogleSignIn _googleSignIn;

  AuthService(this._googleSignIn);

  Future<GoogleSignInAccount?> signIn() async {
    // Pass scopeHint to request permissions upfront and avoid multiple dialogues later
    return await _googleSignIn.authenticate(
      scopeHint: [google.CalendarApi.calendarReadonlyScope],
    );
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    // If we already have a user, just return it
    if (_googleSignIn.currentUser != null) {
      return _googleSignIn.currentUser;
    }
    return await _googleSignIn.attemptLightweightAuthentication();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<google.CalendarApi?> getCalendarApi(GoogleSignInAccount account) async {
    final scopes = [google.CalendarApi.calendarReadonlyScope];
    
    // This should be silent if the user already granted the scopes during sign-in
    final auth = await account.authorizationClient.authorizeScopes(scopes);
    
    final headers = {'Authorization': 'Bearer ${auth.accessToken}'};
    final client = _GoogleAuthClient(headers);
    return google.CalendarApi(client);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
