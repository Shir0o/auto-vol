import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(volumeRulesProvider);
    final overridesAsync = ref.watch(eventOverridesProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Rules'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: VocusColors.deepSpaceGradient,
            ),
          ),
          SafeArea(
            child: rulesAsync.when(
              data: (rules) {
                final overrides = overridesAsync.value ?? {};
                final events = eventsAsync.value ?? [];

                if (rules.isEmpty && overrides.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildCombinedList(
                  context,
                  ref,
                  rules,
                  overrides,
                  events,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        backgroundColor: VocusColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VocusColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rule, color: VocusColors.primary),
              title: const Text('Add General Rule'),
              subtitle: const Text('Based on event title keywords'),
              onTap: () {
                Navigator.pop(context);
                _showRuleDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: VocusColors.primary),
              title: const Text('Add Manual Override'),
              subtitle: const Text('For a specific calendar event'),
              onTap: () {
                Navigator.pop(context);
                _showEventPicker(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEventPicker(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.read(calendarEventsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VocusColors.surface,
        title: const Text('Select Event'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const Center(child: Text('No upcoming events found'));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${event.calendarTitle ?? 'Calendar'} • ${_formatTime(event.startTime)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showOverrideDialog(context, ref, event);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: VocusColors.outline),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverrideDialog(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) {
    double volume = 0.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: VocusColors.surface,
          title: Text('Override "${event.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set a specific volume for this instance of the event.',
                style: TextStyle(fontSize: 12, color: VocusColors.outline),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Volume'),
                  Text('${(volume * 100).toInt()}%'),
                ],
              ),
              Slider(
                value: volume,
                onChanged: (val) => setState(() => volume = val),
                activeColor: VocusColors.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: VocusColors.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(eventOverridesProvider.notifier)
                    .setOverride(event.id, volume);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rule_folder_outlined,
            size: 64,
            color: VocusColors.outline.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No rules defined',
            style: TextStyle(color: VocusColors.outline, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add a rule to automatically change volume when specific events start.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VocusColors.outline, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList(
    BuildContext context,
    WidgetRef ref,
    List<VolumeRule> rules,
    Map<String, double> overrides,
    List<CalendarEvent> events,
  ) {
    // Map event IDs to titles for the overrides
    final eventMap = {for (var e in events) e.id: e};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGuideCard(),
        if (overrides.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'Manual Overrides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VocusColors.primary,
              ),
            ),
          ),
          ...overrides.entries.map((entry) {
            final event = eventMap[entry.key];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VocusColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        entry.value == 0 ? Icons.volume_off : Icons.volume_up,
                        color: VocusColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event?.title ?? 'Unknown Event (${entry.key})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            entry.value == 0
                                ? 'Muted'
                                : 'Volume: ${(entry.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              color: VocusColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => ref
                          .read(eventOverridesProvider.notifier)
                          .removeOverride(entry.key),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
        if (rules.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'General Rules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: VocusColors.primary,
              ),
            ),
          ),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                onTap: () => _showRuleDialog(context, ref, rule: rule),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: VocusColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rule.volumeLevel == 0
                            ? Icons.volume_off
                            : Icons.volume_up,
                        color: VocusColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.eventTitlePattern,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${rule.calendarId} • Priority: ${rule.priority}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: VocusColors.outline,
                            ),
                          ),
                          Text(
                            rule.volumeLevel == 0
                                ? 'Muted'
                                : 'Volume: ${(rule.volumeLevel * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              color: VocusColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => ref
                          .read(volumeRulesProvider.notifier)
                          .deleteRule(rule.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuideCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: VocusColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'How Automation Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: VocusColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              'Manual Overrides: Direct tunes for specific events. Always take precedence.',
            ),
            _buildGuideItem(
              'General Rules: Apply when an event title contains your keyword.',
            ),
            _buildGuideItem(
              'Priority: If events overlap, the rule with the highest number wins.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: VocusColors.primary, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: VocusColors.outline,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRuleDialog(
    BuildContext context,
    WidgetRef ref, {
    VolumeRule? rule,
  }) async {
    final titleController = TextEditingController(
      text: rule?.eventTitlePattern,
    );
    double volume = rule?.volumeLevel ?? 0.0;
    int priority = rule?.priority ?? 1;
    String? selectedCalendarId = rule?.calendarId;

    final calendarsAsync = ref.read(availableCalendarsProvider);
    final calendars = calendarsAsync.value ?? [];

    if (selectedCalendarId == null && calendars.isNotEmpty) {
      selectedCalendarId = calendars
          .firstWhere((c) => c.isPrimary, orElse: () => calendars.first)
          .id;
    } else if (selectedCalendarId == null) {
      selectedCalendarId = 'primary';
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: VocusColors.surface,
          title: Text(rule == null ? 'Add Rule' : 'Edit Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Keyword',
                    hintText: 'e.g. Meeting, Focus, Workout',
                    helperText: 'Matches if title contains this text',
                    helperStyle: TextStyle(fontSize: 11),
                    labelStyle: TextStyle(color: VocusColors.outline),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Calendar',
                  style: TextStyle(color: VocusColors.outline, fontSize: 12),
                ),
                DropdownButton<String>(
                  value: selectedCalendarId,
                  isExpanded: true,
                  dropdownColor: VocusColors.surface,
                  items: [
                    if (calendars.isEmpty)
                      const DropdownMenuItem(
                        value: 'primary',
                        child: Text('Primary'),
                      ),
                    ...calendars.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedCalendarId = val),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priority'),
                          Text(
                            'Higher numbers win overlaps',
                            style: TextStyle(
                              fontSize: 11,
                              color: VocusColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: priority > 1
                              ? () => setState(() => priority--)
                              : null,
                        ),
                        Text('$priority'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => priority++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Volume'),
                    Text('${(volume * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: volume,
                  onChanged: (val) => setState(() => volume = val),
                  activeColor: VocusColors.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: VocusColors.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final newRule = VolumeRule(
                    id:
                        rule?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    calendarId: selectedCalendarId ?? 'primary',
                    eventTitlePattern: titleController.text,
                    volumeLevel: volume,
                    priority: priority,
                  );

                  if (rule == null) {
                    ref.read(volumeRulesProvider.notifier).addRule(newRule);
                  } else {
                    ref.read(volumeRulesProvider.notifier).updateRule(newRule);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(rule == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
