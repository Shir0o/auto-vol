import 'package:volo/core/providers/common_providers.dart';
import 'package:volo/core/theme/volo_theme.dart';
import 'package:volo/features/main_screen.dart';
import 'package:volo/features/volume/providers/automation_provider.dart';
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
      child: const VoloApp(),
    ),
  );
}

class VoloApp extends ConsumerWidget {
  const VoloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize automation loop
    ref.listen(automationProvider, (_, __) {});

    return MaterialApp(
      title: 'Volo',
      theme: VoloTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
