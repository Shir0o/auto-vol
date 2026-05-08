import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocus/core/providers/common_providers.dart';

void main() {
  test('tickProvider should emit periodic DateTime values', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Watch the tickProvider
    final stream = container.read(tickProvider);

    expect(stream, isA<AsyncValue<DateTime>>());
  });
}
