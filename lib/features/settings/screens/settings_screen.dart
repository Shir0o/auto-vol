import 'package:volo/core/theme/volo_theme.dart';
import 'package:volo/core/widgets/glass_card.dart';
import 'package:volo/features/volume/providers/automation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationEnabled = ref.watch(automationEnabledProvider);
    final defaultVolume = ref.watch(defaultVolumeProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: VoloColors.deepSpaceGradient)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: VoloColors.onBackground,
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
                _buildConnectionItem('Google Calendar', 'Sync schedules seamlessly', Icons.calendar_month),
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
          color: VoloColors.primary,
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
                  style: TextStyle(fontSize: 14, color: VoloColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => ref.read(automationEnabledProvider.notifier).set(value),
            activeColor: VoloColors.primary,
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
              Icon(Icons.volume_up, color: VoloColors.outline),
            ],
          ),
          Slider(
            value: volume,
            onChanged: (value) => ref.read(defaultVolumeProvider.notifier).set(value),
            activeColor: VoloColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionItem(String title, String subtitle, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VoloColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: VoloColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: VoloColors.outline)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: VoloColors.outline),
        ],
      ),
    );
  }
}
