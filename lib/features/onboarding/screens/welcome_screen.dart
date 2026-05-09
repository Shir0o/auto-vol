import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/onboarding/providers/onboarding_controller.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationPermissionProvider);
    final dndAsync = ref.watch(notificationPolicyAccessProvider);
    final batteryAsync = ref.watch(ignoreBatteryOptimizationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VocusColors.background,
              VocusColors.surfaceVariant.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Welcome to Vocus',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: VocusColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'To provide the best experience, we need a few permissions and calendar access to automate your volume levels seamlessly.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: VocusColors.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _OnboardingItem(
                          title: 'Google Calendar',
                          description:
                              'Connect your Google account to automatically sync your meetings and events.',
                          icon: Icons.calendar_month_rounded,
                          isCompleted: currentUser != null,
                          actionLabel: 'Authorize',
                          completedLabel: 'Linked',
                          onPressed: () async {
                            await ref.read(authServiceProvider).signIn();
                            ref.invalidate(authStateProvider);
                          },
                        ),
                        const SizedBox(height: 16),
                        _OnboardingItem(
                          title: 'Notification Access',
                          description:
                              'Vocus uses notifications to keep you informed when it\'s automatically adjusting your volume.',
                          icon: Icons.notifications_none_rounded,
                          isCompleted: notificationAsync.value ?? false,
                          actionLabel: 'Allow',
                          onPressed: () async {
                            await ref
                                .read(permissionServiceProvider)
                                .requestNotificationPermission();
                            ref.invalidate(notificationPermissionProvider);
                          },
                        ),
                        const SizedBox(height: 16),
                        _OnboardingItem(
                          title: 'Do Not Disturb Access',
                          description:
                              'Required to change system sound settings and toggle Do Not Disturb mode during your scheduled meetings.',
                          icon: Icons.do_not_disturb_on_outlined,
                          isCompleted: dndAsync.value ?? false,
                          actionLabel: 'Allow',
                          onPressed: () async {
                            await ref
                                .read(permissionServiceProvider)
                                .requestNotificationPolicyAccess();
                            ref.invalidate(notificationPolicyAccessProvider);
                          },
                        ),
                        const SizedBox(height: 16),
                        _OnboardingItem(
                          title: 'Background Activity',
                          description:
                              'Allows Vocus to reliably sync your calendar and update volume levels even when the app isn\'t open.',
                          icon: Icons.battery_saver_rounded,
                          isCompleted: batteryAsync.value ?? false,
                          actionLabel: 'Allow',
                          onPressed: () async {
                            await ref
                                .read(permissionServiceProvider)
                                .requestIgnoreBatteryOptimizations();
                            ref.invalidate(ignoreBatteryOptimizationsProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(onboardingControllerProvider.notifier)
                            .completeOnboarding();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VocusColors.primary,
                        foregroundColor: VocusColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final String actionLabel;
  final String completedLabel;
  final VoidCallback onPressed;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isCompleted,
    required this.actionLabel,
    this.completedLabel = 'Granted',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: VocusColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: VocusColors.onSurface,
                  ),
                ),
              ),
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: VocusColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completedLabel,
                      style: const TextStyle(
                        color: VocusColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VocusColors.primary.withOpacity(0.2),
                    foregroundColor: VocusColors.primary,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: VocusColors.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
