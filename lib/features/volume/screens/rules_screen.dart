import 'package:vocus/core/theme/vocus_theme.dart';
import 'package:vocus/core/widgets/glass_card.dart';
import 'package:vocus/features/volume/models/volume_rule.dart';
import 'package:vocus/features/volume/providers/volume_rules_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(volumeRulesProvider);

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
              data: (rules) => rules.isEmpty
                  ? _buildEmptyState()
                  : _buildRulesList(ref, rules),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context, ref),
        backgroundColor: VocusColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
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

  Widget _buildRulesList(WidgetRef ref, List<VolumeRule> rules) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
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
                    rule.volumeLevel == 0 ? Icons.volume_off : Icons.volume_up,
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
        );
      },
    );
  }

  Future<void> _showAddRuleDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    double volume = 0.0;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: VocusColors.surface,
          title: const Text('Add Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Keyword',
                  hintText: 'e.g. Meeting, Focus, Workout',
                  labelStyle: TextStyle(color: VocusColors.outline),
                ),
                style: const TextStyle(color: Colors.white),
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
                if (titleController.text.isNotEmpty) {
                  ref
                      .read(volumeRulesProvider.notifier)
                      .addRule(
                        VolumeRule(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          calendarId: 'primary',
                          eventTitlePattern: titleController.text,
                          volumeLevel: volume,
                          priority: 1,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
