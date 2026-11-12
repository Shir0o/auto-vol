import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocus/core/theme/vocus_theme.dart';

void main() {
  group('VocusTheme', () {
    test('lightTheme preserves the legible dark cyber aesthetic', () {
      final light = VocusTheme.lightTheme;

      expect(light.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, VocusColors.background);
      expect(light.colorScheme.onSurface, VocusColors.onSurface);
      expect(light.colorScheme.onPrimary, VocusColors.onPrimary);
    });

    test('lightTheme and darkTheme render text the same way', () {
      final light = VocusTheme.lightTheme;
      final dark = VocusTheme.darkTheme;

      expect(light.textTheme.bodyLarge?.color, dark.textTheme.bodyLarge?.color);
      expect(light.colorScheme.surface, dark.colorScheme.surface);
    });
  });
}
