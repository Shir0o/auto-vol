import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/onboarding/providers/onboarding_controller.dart';
import 'package:vocus/features/onboarding/screens/welcome_screen.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vocus/features/calendar/services/background/sync_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:io';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Workmanager: Executing task $task');
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncService = SyncService(GoogleSignIn.instance, prefs);
      return await syncService.syncCalendars();
    } catch (e) {
      print('Workmanager: Failed to execute task: $e');
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print(
      'Note: .env file not found or failed to load: $e. Falling back to build-time definitions.',
    );
  }

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // TODO: set to false in production
  );

  // Register periodic task
  await Workmanager().registerPeriodicTask(
    'vocus_sync_task',
    'syncCalendars',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Initialize foreground task
  await VocusForegroundService.init();

  // Initialize Google Sign-In. Client IDs are loaded from .env file or provided
  // at build time via --dart-define.
  // On Android, the "Web Client ID" from the Google Cloud Console must be used
  // as the clientId/serverClientId to satisfy the Credential Manager.
  final iosClientId =
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  final webClientId =
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  if (iosClientId.isEmpty || webClientId.isEmpty) {
    // ignore: avoid_print
    print(
      'WARNING: GOOGLE_IOS_CLIENT_ID or GOOGLE_WEB_CLIENT_ID not found in .env or build-time definitions.',
    );
  }

  await GoogleSignIn.instance.initialize(
    clientId: Platform.isIOS ? iosClientId : webClientId,
    serverClientId: webClientId,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const VocusApp(),
    ),
  );
}

final scaffoldMessengerKeyProvider = Provider(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

class VocusApp extends ConsumerWidget {
  const VocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize automation loop and show feedback
    ref.listen(automationProvider, (previous, next) {
      if (next.isEnabled && next.activeEvents.isNotEmpty) {
        final prevActive = previous?.activeEvents.firstOrNull;
        final nextActive = next.activeEvents.first;

        if (prevActive?.id != nextActive.id) {
          final messenger = ref.read(scaffoldMessengerKeyProvider).currentState;
          messenger?.clearSnackBars();
          messenger?.showSnackBar(
            SnackBar(
              content: Text('Auto-Volume: Adjusted for "${nextActive.title}"'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: VocusColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });

    final onboardingCompleted = ref.watch(onboardingControllerProvider);

    return MaterialApp(
      title: 'Vocus',
      theme: VocusTheme.darkTheme,
      home: onboardingCompleted ? const MainScreen() : const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
    );
  }
}
