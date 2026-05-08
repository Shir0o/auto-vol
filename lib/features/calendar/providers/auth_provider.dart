import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthStateNotifier extends Notifier<GoogleSignInAccount?> {
  @override
  GoogleSignInAccount? build() {
    // Initial state is null, will be updated by main.dart or events
    final googleSignIn = ref.watch(googleSignInProvider);
    
    // Listen for events to keep state in sync (e.g. if user signs out elsewhere)
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

final authStateNotifierProvider = NotifierProvider<AuthStateNotifier, GoogleSignInAccount?>(AuthStateNotifier.new);

final currentUserProvider = Provider<GoogleSignInAccount?>((ref) {
  return ref.watch(authStateNotifierProvider);
});

final isStatusAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
