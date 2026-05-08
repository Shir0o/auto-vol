import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocus/core/providers/common_providers.dart';

void main() {
  test('tickProvider exposes an AsyncValue<DateTime>', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final value = container.read(tickProvider);
    expect(value, isA<AsyncValue<DateTime>>());
  });

  test('tickProvider emits periodically once per minute', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      final emissions = <DateTime>[];

      final sub = container.listen<AsyncValue<DateTime>>(tickProvider, (
        _,
        next,
      ) {
        next.whenData(emissions.add);
      });

      // Allow the stream subscription to register before advancing time.
      async.flushMicrotasks();

      async.elapse(const Duration(minutes: 3));
      async.flushMicrotasks();

      expect(emissions.length, greaterThanOrEqualTo(3));

      sub.close();
      container.dispose();
    });
  });

  test('calendarRefreshTickProvider emits every 15 minutes', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      final emissions = <DateTime>[];

      final sub = container.listen<AsyncValue<DateTime>>(
        calendarRefreshTickProvider,
        (_, next) {
          next.whenData(emissions.add);
        },
      );

      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 30));
      async.flushMicrotasks();

      expect(emissions.length, greaterThanOrEqualTo(2));

      sub.close();
      container.dispose();
    });
  });
}
