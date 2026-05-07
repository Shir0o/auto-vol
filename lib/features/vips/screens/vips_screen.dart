import 'package:volo/core/theme/volo_theme.dart';
import 'package:volo/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class VipsScreen extends StatelessWidget {
  const VipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: VoloColors.deepSpaceGradient)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'VIPs',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: VoloColors.onBackground,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: const Center(
                    child: Text(
                      'No VIPs configured yet.',
                      style: TextStyle(color: VoloColors.outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
