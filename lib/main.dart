import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/services/foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vocus/features/calendar/services/background/sync_service.dart';

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
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Initialize foreground task
  await VocusForegroundService.init();

  // Initialize Google Sign-In. Client IDs can be overridden at build time via
  // --dart-define so contributors can use their own OAuth credentials without
  // editing this file. On Android, the "Web Client ID" from the Google Cloud
  // Console must be used as the clientId/serverClientId to satisfy the
  // Credential Manager.
  const iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '1088393636693-5acqni1bji55g47tgs183lnli6cv1a0i.apps.googleusercontent.com',
  );
  const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1088393636693-lm37rmn0q08204ppv2cbm56d3bcta9tj.apps.googleusercontent.com',
  );
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
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
    );
  }
}
