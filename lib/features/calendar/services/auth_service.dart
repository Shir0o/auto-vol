import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:http/http.dart' as http;

class AuthService {
  final GoogleSignIn _googleSignIn;

  AuthService(this._googleSignIn);

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.authenticate();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<google.CalendarApi?> getCalendarApi() async {
    final account = await _googleSignIn.attemptLightweightAuthentication();
    if (account == null) return null;

    final scopes = [google.CalendarApi.calendarReadonlyScope];
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
