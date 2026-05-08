import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  GoogleSignInAccount? build() {
    final googleSignIn = ref.watch(googleSignInProvider);

    googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        state = event.user;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        state = null;
      }
    });

    return null;
  }

  void updateState(GoogleSignInAccount? user) {
    state = user;
  }
}

@riverpod
GoogleSignInAccount? currentUser(Ref ref) {
  return ref.watch(authStateProvider);
}

@riverpod
bool isStatusAuthenticated(Ref ref) {
  return ref.watch(currentUserProvider) != null;
}
