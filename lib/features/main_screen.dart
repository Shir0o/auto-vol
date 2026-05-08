import 'package:vocus/features/schedule/screens/schedule_screen.dart';
import 'package:vocus/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}

final selectedIndexProvider = NotifierProvider<SelectedIndexNotifier, int>(() {
  return SelectedIndexNotifier();
});

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final screens = [const ScheduleScreen(), const SettingsScreen()];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(selectedIndexProvider.notifier).set(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
