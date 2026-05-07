import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

    // Request permissions on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionServiceProvider).requestInitialPermissions();
    });

    return MaterialApp(
      title: 'Vocus',
      theme: VocusTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
