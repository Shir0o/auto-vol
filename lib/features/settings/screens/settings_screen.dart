import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/screens/rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automationEnabled = ref.watch(automationEnabledProvider);
    final defaultVolume = ref.watch(defaultVolumeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final calendarsAsync = ref.watch(availableCalendarsProvider);
    final enabledCalendarIds = ref.watch(enabledCalendarIdsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: VocusColors.deepSpaceGradient,
            ),
          ),
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
                const SizedBox(height: 12),
                _buildRingerToggle(ref),
                const SizedBox(height: 12),
                _buildNotificationToggle(ref),
                const SizedBox(height: 12),
                _buildDndToggle(ref),
                const SizedBox(height: 12),
                _buildRulesEntry(context),
                const SizedBox(height: 24),
                _buildSectionHeader('Focus'),
                _buildDefaultVolumeSlider(ref, defaultVolume),
                const SizedBox(height: 24),
                _buildSectionHeader('System Permissions'),
                _buildPermissionItems(context, ref),
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
                if (currentUser != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Preferences'),
                  _buildAllDayToggle(ref),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Managed Calendars'),
                  calendarsAsync.when(
                    data: (calendars) => Column(
                      children: calendars.map((cal) {
                        final isEnabled = enabledCalendarIds.contains(cal.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildCalendarToggle(ref, cal, isEnabled),
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Failed to load calendars: $err'),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
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
            onChanged: (value) =>
                ref.read(automationEnabledProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRingerToggle(WidgetRef ref) {
    final enabled = ref.watch(automateRingerProvider);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Automate Ringer', style: TextStyle(fontSize: 16)),
                SizedBox(height: 2),
                Text(
                  'Sync phone call volume with your schedule',
                  style: TextStyle(fontSize: 12, color: VocusColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) =>
                ref.read(automateRingerProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(WidgetRef ref) {
    final enabled = ref.watch(automateNotificationProvider);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Automate Notifications', style: TextStyle(fontSize: 16)),
                SizedBox(height: 2),
                Text(
                  'Sync message and app alerts with your schedule',
                  style: TextStyle(fontSize: 12, color: VocusColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) =>
                ref.read(automateNotificationProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDndToggle(WidgetRef ref) {
    final enabled = ref.watch(automateDndProvider);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Automate Do Not Disturb', style: TextStyle(fontSize: 16)),
                SizedBox(height: 2),
                Text(
                  'Silence all alerts automatically during events',
                  style: TextStyle(fontSize: 12, color: VocusColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) =>
                ref.read(automateDndProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesEntry(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RulesScreen()),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.rule, color: VocusColors.primary),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automation Rules',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Define volume levels for specific event titles',
                        style: TextStyle(
                          fontSize: 12,
                          color: VocusColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: VocusColors.outline),
        ],
      ),
    );
  }

  Widget _buildAllDayToggle(WidgetRef ref) {
    final includeAllDay = ref.watch(includeAllDayEventsProvider);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      onTap: () => ref.read(includeAllDayEventsProvider.notifier).toggle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Include All-Day Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Show events that span the entire day in your schedule',
                  style: TextStyle(fontSize: 14, color: VocusColors.outline),
                ),
              ],
            ),
          ),
          Switch(
            value: includeAllDay,
            onChanged: (value) =>
                ref.read(includeAllDayEventsProvider.notifier).toggle(),
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
              const Icon(Icons.volume_up, color: VocusColors.outline),
            ],
          ),
          Slider(
            value: volume,
            onChanged: (value) =>
                ref.read(defaultVolumeProvider.notifier).set(value),
            activeColor: VocusColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    AsyncValue<bool> status,
    VoidCallback onRequest,
  ) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VocusColors.outline,
                  ),
                ),
              ],
            ),
          ),
          status.when(
            data: (granted) => !isAndroid || granted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VocusColors.primary.withOpacity(0.2),
                      foregroundColor: VocusColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('GRANT', style: TextStyle(fontSize: 12)),
                  ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItems(BuildContext context, WidgetRef ref) {
    final dndAccess = ref.watch(notificationPolicyAccessProvider);
    final batteryOpt = ref.watch(ignoreBatteryOptimizationsProvider);

    return Column(
      children: [
        _buildPermissionRow(
          context,
          ref,
          'Do Not Disturb Access',
          'Required to change volume during DND',
          dndAccess,
          () => ref
              .read(permissionServiceProvider)
              .requestNotificationPolicyAccess()
              .then((_) => ref.invalidate(notificationPolicyAccessProvider)),
        ),
        const SizedBox(height: 12),
        _buildPermissionRow(
          context,
          ref,
          'Battery Optimization',
          'Exempt app to ensure reliable background monitoring',
          batteryOpt,
          () => ref
              .read(permissionServiceProvider)
              .requestIgnoreBatteryOptimizations()
              .then((_) => ref.invalidate(ignoreBatteryOptimizationsProvider)),
        ),
      ],
    );
  }

  Widget _buildCalendarToggle(
    WidgetRef ref,
    CalendarEntry cal,
    bool isEnabled,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => ref.read(enabledCalendarIdsProvider.notifier).toggle(cal.id),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: cal.color != null
                  ? Color(int.parse(cal.color!.replaceAll('#', '0xFF')))
                  : VocusColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cal.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cal.description != null)
                  Text(
                    cal.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: VocusColors.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) =>
                ref.read(enabledCalendarIdsProvider.notifier).toggle(cal.id),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
