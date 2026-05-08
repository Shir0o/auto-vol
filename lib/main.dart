import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Sign-In
  // Note: On Android, the "Web Client ID" from the Google Cloud Console 
  // must be used as the clientId/serverClientId to satisfy the Credential Manager.
  await GoogleSignIn.instance.initialize(
    clientId: Platform.isIOS 
        ? '1088393636693-5acqni1bji55g47tgs183lnli6cv1a0i.apps.googleusercontent.com' 
        : '1088393636693-lm37rmn0q08204ppv2cbm56d3bcta9tj.apps.googleusercontent.com',
    serverClientId: '1088393636693-lm37rmn0q08204ppv2cbm56d3bcta9tj.apps.googleusercontent.com',
    scopes: [
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );
...
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
