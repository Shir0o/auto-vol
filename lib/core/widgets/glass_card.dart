import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vocus/core/theme/vocus_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final decoration = BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: radius,
      border:
          border ??
          Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
    );
    final contentPadding = padding ?? const EdgeInsets.all(16);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: onTap == null
            // Non-interactive cards stay light and pure: no Material, no ink.
            ? Container(
                padding: contentPadding,
                decoration: decoration,
                child: child,
              )
            // Interactive cards get a tactile cyber-cyan ripple with the full
            // card surface acting as the hit target.
            : Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: decoration,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: radius,
                    // Bounds InkResponse.effectiveRadius for the ripple.
                    radius: 24,
                    splashColor: VocusColors.primary.withValues(alpha: 0.15),
                    highlightColor: VocusColors.primary.withValues(alpha: 0.08),
                    child: Container(padding: contentPadding, child: child),
                  ),
                ),
              ),
      ),
    );
  }
}
