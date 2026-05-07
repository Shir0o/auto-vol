import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: VocusColors.deepSpaceGradient)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: eventsAsync.when(
                    data: (events) => _buildTimeline(events),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flow State',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: VocusColors.onBackground,
            ),
          ),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 18,
              color: VocusColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<CalendarEvent> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventItem(event);
      },
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    final startTimeStr = DateFormat('HH:mm').format(event.startTime);
    final now = DateTime.now();
    final isActive = event.startTime.isBefore(now) && event.endTime.isAfter(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              startTimeStr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? VocusColors.primary : VocusColors.outline,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              opacity: isActive ? 0.2 : 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isActive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: VocusColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isActive) const SizedBox(width: 8),
                      Text(
                        isActive ? 'In Progress' : 'Upcoming',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? VocusColors.primary : VocusColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: VocusColors.onSurface,
                    ),
                  ),
                  if (event.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: VocusColors.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
