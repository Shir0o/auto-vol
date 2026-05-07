import 'package:auto_vol/core/theme/aura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AuraColors.deepSpaceGradient,
            ),
          ),
          // Ambient Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AuraColors.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  AuraColors.secondary.withOpacity(0.1),
                  BlendMode.srcOver,
                ),
                child: Container(),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: _buildStatusIndicator(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AuraColors.surfaceVariant,
            child: const Icon(Icons.person, color: AuraColors.outline),
          ),
          const Text(
            'Aura',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AuraColors.primary,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_suggest, color: AuraColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Organic Shape Glows
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AuraColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              Icons.sync,
              size: 80,
              color: AuraColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Calendar Sync Active',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AuraColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Volume managed by your calendar',
          style: TextStyle(
            fontSize: 16,
            color: AuraColors.outline,
          ),
        ),
      ],
    );
  }
}
