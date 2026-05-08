import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Sign-In
  await GoogleSignIn.instance.initialize(
    clientId: '1088393636693-p5k62kk0u2tqvnv4uojhv5eh9v6cjmhb.apps.googleusercontent.com',
    serverClientId: '1088393636693-p5k62kk0u2tqvnv4uojhv5eh9v6cjmhb.apps.googleusercontent.com',
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VocusApp(),
    ),
  );
}

class VocusApp extends ConsumerWidget {
  const VocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize automation loop
    ref.listen(automationProvider, (_, __) {});

    // Request permissions and silent sign-in on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(permissionServiceProvider).requestInitialPermissions();
      final user = await ref.read(authServiceProvider).signInSilently();
      if (user != null) {
        ref.read(authStateNotifierProvider.notifier).updateState(user);
      }
    });

    return MaterialApp(
      title: 'Vocus',
      theme: VocusTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
