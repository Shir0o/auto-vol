import 'package:auto_vol/core/providers/common_providers.dart';
import 'package:auto_vol/core/theme/aura_theme.dart';
import 'package:auto_vol/features/main_screen.dart';
import 'package:auto_vol/features/volume/providers/automation_provider.dart';
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
      child: const AuraApp(),
    ),
  );
}

class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize automation loop
    ref.listen(automationProvider, (_, __) {});

    return MaterialApp(
      title: 'Aura',
      theme: AuraTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
