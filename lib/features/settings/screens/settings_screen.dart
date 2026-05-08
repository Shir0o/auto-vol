import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationEnabled = ref.watch(automationEnabledProvider);
    final defaultVolume = ref.watch(defaultVolumeProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: VocusColors.deepSpaceGradient)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: VocusColors.onBackground,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Automation'),
                _buildAutomationToggle(ref, automationEnabled),
                const SizedBox(height: 24),
                _buildSectionHeader('Focus'),
                _buildDefaultVolumeSlider(ref, defaultVolume),
                const SizedBox(height: 24),
                _buildSectionHeader('Connections'),
                _buildConnectionItem(
                  ref,
                  'Google Calendar',
                  currentUser?.email ?? 'Sync schedules seamlessly',
                  Icons.calendar_month,
                  isConnected: currentUser != null,
                  onTap: () async {
                    final authService = ref.read(authServiceProvider);
                    if (currentUser != null) {
                      await authService.signOut();
                    } else {
                      await authService.signIn();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: VocusColors.primary,
        ),
      ),
    );
  }

  Widget _buildAutomationToggle(WidgetRef ref, bool enabled) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Volume',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Automatically manage alerts based on your daily schedule',
                  style: TextStyle(fontSize: 14, color: VocusColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => ref.read(automationEnabledProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultVolumeSlider(WidgetRef ref, double volume) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alert Volume', style: TextStyle(fontSize: 16)),
              Icon(Icons.volume_up, color: VocusColors.outline),
            ],
          ),
          Slider(
            value: volume,
            onChanged: (value) => ref.read(defaultVolumeProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionItem(
    WidgetRef ref,
    String title,
    String subtitle,
    IconData icon, {
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withOpacity(0.1)
                  : VocusColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isConnected ? Colors.green : VocusColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isConnected ? Colors.green : VocusColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isConnected ? Icons.logout : Icons.chevron_right,
            color: VocusColors.outline,
          ),
        ],
      ),
    );
  }
}
