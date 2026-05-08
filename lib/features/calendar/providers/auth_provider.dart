import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return googleSignIn.onCurrentUserChanged;
});

final currentUserProvider = Provider<GoogleSignInAccount?>((ref) {
  return ref.watch(authStateProvider).value;
});

final isStatusAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
