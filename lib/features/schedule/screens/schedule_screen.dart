import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/providers/auth_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/models/automation_status.dart';
import 'package:vocus/features/volume/providers/automation_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:vocus/features/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final automationStatus = ref.watch(automationProvider);

    final notificationPermission = ref.watch(notificationPermissionProvider);
    final dndAccess = ref.watch(notificationPolicyAccessProvider);
    final batteryOpt = ref.watch(ignoreBatteryOptimizationsProvider);

    final hasMissingPermissions =
        (notificationPermission.value == false) ||
        (dndAccess.value == false) ||
        (batteryOpt.value == false);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: VocusColors.deepSpaceGradient,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(ref, automationStatus),
                if (hasMissingPermissions) _buildMissingPermissionsBanner(ref),
                Expanded(
                  child: authState.when(
                    loading: () => _buildSkeletonLoader(),
                    error: (err, _) => Center(child: Text('Auth Error: $err')),
                    data: (user) {
                      if (user == null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10,
                          ),
                          child: _buildOnboardingCard(ref),
                        );
                      }

                      final eventsAsync = ref.watch(calendarEventsProvider);
                      return eventsAsync.when(
                        data: (events) {
                          final rules =
                              ref.watch(volumeRulesProvider).value ?? [];
                          return RefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(calendarEventsProvider),
                            color: VocusColors.primary,
                            backgroundColor: VocusColors.surface,
                            child: _buildTimeline(
                              context,
                              ref,
                              events,
                              rules,
                              automationStatus,
                            ),
                          );
                        },
                        loading: () => _buildSkeletonLoader(),
                        error: (err, stack) =>
                            Center(child: Text('Schedule Error: $err')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, AutomationStatus status) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: VocusColors.onBackground,
                ),
              ),
              _buildStatusBadge(ref, status),
            ],
          ),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(fontSize: 18, color: VocusColors.outline),
          ),
          if (status.isEnabled && status.activeEvents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _buildActiveAutomationCard(status),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(WidgetRef ref, AutomationStatus status) {
    final color = status.isEnabled ? VocusColors.primary : VocusColors.outline;
    return GestureDetector(
      onTap: () =>
          ref.read(automationEnabledProvider.notifier).set(!status.isEnabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              status.isEnabled ? 'MONITORING' : 'PAUSED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAutomationCard(AutomationStatus status) {
    final winningEvent = status.winningEvent;
    final otherEvents = status.activeEvents
        .where((e) => e.id != winningEvent?.id)
        .toList();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      opacity: 0.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: VocusColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      winningEvent != null
                          ? 'Active: "${winningEvent.title}"'
                          : 'Monitoring schedule...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Target Volume: ${(status.currentVolume * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: VocusColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.winningRule != null)
                Tooltip(
                  message:
                      'Rule: ${status.winningRule!.eventTitlePattern} (${status.winningRule!.priority})',
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: VocusColors.outline,
                  ),
                ),
            ],
          ),
          if (otherEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(
                height: 1,
                color: VocusColors.outline,
                thickness: 0.1,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Overlapping with ${otherEvents.length} other event${otherEvents.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMissingPermissionsBanner(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        opacity: 0.15,
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missing Permissions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: VocusColors.onSurface,
                    ),
                  ),
                  Text(
                    'Some features may not work as expected.',
                    style: TextStyle(fontSize: 12, color: VocusColors.outline),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(selectedIndexProvider.notifier).set(1);
              },
              child: const Text(
                'Fix in Settings',
                style: TextStyle(
                  color: VocusColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: VocusColors.primary,
            size: 32,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect your schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sync with Google Calendar to automatically manage your device volume during meetings and focus time.',
            style: TextStyle(
              fontSize: 14,
              color: VocusColors.outline,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => ref.read(authServiceProvider).signIn(),
            style: ElevatedButton.styleFrom(
              backgroundColor: VocusColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: VocusColors.surface.withOpacity(0.3),
      highlightColor: VocusColors.surface.withOpacity(0.1),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: GlassCard(
            padding: EdgeInsets.zero,
            opacity: 0.1,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 100,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 80,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Space for the action button
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    List<CalendarEvent> events,
    List<VolumeRule> rules,
    AutomationStatus automationStatus,
  ) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: VocusColors.outline.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming events',
              style: TextStyle(color: VocusColors.outline, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final groupedEvents = <DateTime, List<CalendarEvent>>{};
    for (var event in events) {
      final date = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      groupedEvents.putIfAbsent(date, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()..sort();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEvents = groupedEvents[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            ...dayEvents.map(
              (e) => _buildEventItem(
                context,
                ref,
                e,
                events,
                rules,
                automationStatus,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dayLabel;
    if (date == today) {
      dayLabel = 'Today';
    } else if (date == tomorrow) {
      dayLabel = 'Tomorrow';
    } else {
      dayLabel = DateFormat('EEEE').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            dayLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: VocusColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• ${DateFormat('MMMM d').format(date)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: VocusColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
    List<CalendarEvent> allEvents,
    List<VolumeRule> rules,
    AutomationStatus automationStatus,
  ) {
    final timeFormat = DateFormat('h:mm a');
    final startTimeStr = timeFormat.format(event.startTime);
    final endTimeStr = timeFormat.format(event.endTime);
    final now = DateTime.now();
    final isActive =
        event.startTime.isBefore(now) && event.endTime.isAfter(now);
    final isWinner = automationStatus.winningEvent?.id == event.id;

    final automationService = ref.read(automationServiceProvider);
    final targetVolume = automationService.getTargetVolumeForEvent(
      event: event,
      rules: rules,
    );

    // Conflict detection
    bool hasConflict = false;
    if (targetVolume != null) {
      final overlaps = allEvents.where(
        (e) =>
            e.id != event.id &&
            e.startTime.isBefore(event.endTime) &&
            event.startTime.isBefore(e.endTime),
      );

      for (final other in overlaps) {
        final otherTarget = automationService.getTargetVolumeForEvent(
          event: other,
          rules: rules,
        );
        if (otherTarget != null && otherTarget != targetVolume) {
          hasConflict = true;
          break;
        }
      }
    }

    final calColor = event.calendarColor != null
        ? Color(int.parse(event.calendarColor!.replaceAll('#', '0xFF')))
        : VocusColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GlassCard(
        padding: EdgeInsets.zero,
        opacity: isActive ? 0.2 : 0.1,
        border: isWinner
            ? Border.all(color: VocusColors.primary.withOpacity(0.5), width: 2)
            : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: calColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: VocusColors.onSurface,
                              ),
                            ),
                          ),
                          if (isWinner)
                            const Icon(
                              Icons.auto_awesome,
                              color: VocusColors.primary,
                              size: 16,
                            ),
                          if (hasConflict)
                            const Tooltip(
                              message: 'Volume conflict with another event',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orangeAccent,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            event.isAllDay
                                ? 'All day'
                                : '$startTimeStr - $endTimeStr',
                            style: const TextStyle(
                              fontSize: 13,
                              color: VocusColors.outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• ${event.calendarTitle ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: calColor.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '• NOW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: VocusColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (targetVolume != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                targetVolume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                size: 12,
                                color: VocusColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Target: ${(targetVolume * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: VocusColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (event.description != null &&
                          event.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            event.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: VocusColors.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
