import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:vocus/features/volume/providers/event_overrides_provider.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class FakeEventOverridesNotifier extends EventOverridesNotifier {
  final Map<String, double> _initialState;
  FakeEventOverridesNotifier(this._initialState);
  @override
  FutureOr<Map<String, double>> build() => _initialState;
}

class FakeEnabledCalendarIdsNotifier extends EnabledCalendarIdsNotifier {
  final Set<String> _initialState;
  FakeEnabledCalendarIdsNotifier(this._initialState);
  @override
  Set<String> build() => _initialState;
}

void main() {
  late MockCalendarRepository mockRepository;
  late SharedPreferences prefs;

  setUp(() async {
    mockRepository = MockCalendarRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('availableCalendarsProvider fetches from repository', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarRepositoryProvider.overrideWith((ref) async => mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final calendars = [
      CalendarEntry(id: '1', title: 'Primary', isPrimary: true),
      CalendarEntry(id: '2', title: 'Holidays'),
    ];

    when(
      () => mockRepository.fetchCalendars(),
    ).thenAnswer((_) async => calendars);

    final result = await container.read(availableCalendarsProvider.future);
    expect(result, calendars);
    verify(() => mockRepository.fetchCalendars()).called(1);
  });

  test(
    'enabledCalendarIdsProvider defaults to primary if nothing stored',
    () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          availableCalendarsProvider.overrideWith(
            (ref) async => [
              CalendarEntry(id: 'cal-1', title: 'Primary', isPrimary: true),
              CalendarEntry(id: 'cal-2', title: 'Other'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for availableCalendarsProvider to finish
      await container.read(availableCalendarsProvider.future);

      // Initial state should include cal-1
      final enabledIds = container.read(enabledCalendarIdsProvider);
      expect(enabledIds, contains('cal-1'));
      expect(enabledIds.length, 1);
    },
  );

  test('enabledCalendarIdsProvider toggles IDs and persists', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        availableCalendarsProvider.overrideWith(
          (ref) async => [
            CalendarEntry(id: 'cal-1', title: 'Primary', isPrimary: true),
            CalendarEntry(id: 'cal-2', title: 'Other'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    // Wait for availableCalendarsProvider to finish
    await container.read(availableCalendarsProvider.future);

    await container.read(enabledCalendarIdsProvider.notifier).toggle('cal-2');

    expect(
      container.read(enabledCalendarIdsProvider),
      containsAll(['cal-1', 'cal-2']),
    );
    expect(
      prefs.getStringList('enabled_calendar_ids'),
      containsAll(['cal-1', 'cal-2']),
    );

    await container.read(enabledCalendarIdsProvider.notifier).toggle('cal-1');
    expect(container.read(enabledCalendarIdsProvider), contains('cal-2'));
    expect(
      container.read(enabledCalendarIdsProvider),
      isNot(contains('cal-1')),
    );
  });

  test(
    'calendarEventsProvider aggregates and sorts events from enabled calendars with metadata',
    () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
          enabledCalendarIdsProvider.overrideWith(
            () => FakeEnabledCalendarIdsNotifier({'cal-1', 'cal-2'}),
          ),
          availableCalendarsProvider.overrideWith(
            (ref) async => [
              CalendarEntry(id: 'cal-1', title: 'Work', color: '#FF0000'),
              CalendarEntry(id: 'cal-2', title: 'Personal', color: '#00FF00'),
            ],
          ),
          eventOverridesProvider.overrideWith(
            () => FakeEventOverridesNotifier({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final now = DateTime.now();
      final event1 = CalendarEvent(
        id: 'e1',
        title: 'Event 1',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        calendarId: 'cal-1',
        calendarTitle: 'Work',
        calendarColor: '#FF0000',
      );
      final event2 = CalendarEvent(
        id: 'e2',
        title: 'Event 2',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
        calendarId: 'cal-2',
        calendarTitle: 'Personal',
        calendarColor: '#00FF00',
      );

      when(
        () => mockRepository.fetchEvents(
          'cal-1',
          calendarTitle: 'Work',
          calendarColor: '#FF0000',
        ),
      ).thenAnswer((_) async => [event1]);
      when(
        () => mockRepository.fetchEvents(
          'cal-2',
          calendarTitle: 'Personal',
          calendarColor: '#00FF00',
        ),
      ).thenAnswer((_) async => [event2]);

      final results = await container.read(calendarEventsProvider.future);

      expect(results.length, 2);
      // Should be sorted by start time
      expect(results.first.id, 'e2');
      expect(results.first.calendarTitle, 'Personal');
      expect(results.last.id, 'e1');
      expect(results.last.calendarTitle, 'Work');
    },
  );

  test(
    'calendarEventsProvider filters all-day events when includeAllDayEventsProvider is false',
    () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
          enabledCalendarIdsProvider.overrideWith(
            () => FakeEnabledCalendarIdsNotifier({'primary'}),
          ),
          availableCalendarsProvider.overrideWith(
            (ref) async => [
              CalendarEntry(id: 'primary', title: 'Primary', isPrimary: true),
            ],
          ),
          eventOverridesProvider.overrideWith(
            () => FakeEventOverridesNotifier({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final allDayEvent = CalendarEvent(
        id: '1',
        title: 'All Day Event',
        startTime: DateTime(2026, 5, 8),
        endTime: DateTime(2026, 5, 9),
        calendarId: 'primary',
        isAllDay: true,
      );

      final regularEvent = CalendarEvent(
        id: '2',
        title: 'Regular Event',
        startTime: DateTime(2026, 5, 8, 10),
        endTime: DateTime(2026, 5, 8, 11),
        calendarId: 'primary',
        isAllDay: false,
      );

      when(
        () => mockRepository.fetchEvents(
          any(),
          calendarTitle: any(named: 'calendarTitle'),
          calendarColor: any(named: 'calendarColor'),
        ),
      ).thenAnswer((_) async => [allDayEvent, regularEvent]);

      // Initial state: include all-day is true (default)
      var events = await container.read(calendarEventsProvider.future);
      expect(events.length, 2);
      expect(events.any((e) => e.isAllDay), isTrue);

      // Toggle off include all-day
      await container.read(includeAllDayEventsProvider.notifier).toggle();

      // Refresh events
      events = await container.read(calendarEventsProvider.future);
      expect(events.length, 1);
      expect(events.first.title, 'Regular Event');
      expect(events.any((e) => e.isAllDay), isFalse);
    },
  );

  test('calendarEventsProvider applies volume overrides', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarRepositoryProvider.overrideWith(
          (ref) async => mockRepository,
        ),
        enabledCalendarIdsProvider.overrideWith(
          () => FakeEnabledCalendarIdsNotifier({'primary'}),
        ),
        availableCalendarsProvider.overrideWith(
          (ref) async => [
            CalendarEntry(id: 'primary', title: 'Primary', isPrimary: true),
          ],
        ),
        eventOverridesProvider.overrideWith(
          () => FakeEventOverridesNotifier({'e1': 0.8}),
        ),
      ],
    );
    addTearDown(container.dispose);

    final event = CalendarEvent(
      id: 'e1',
      title: 'Tune Me',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      calendarId: 'primary',
    );

    when(
      () => mockRepository.fetchEvents(
        any(),
        calendarTitle: any(named: 'calendarTitle'),
        calendarColor: any(named: 'calendarColor'),
      ),
    ).thenAnswer((_) async => [event]);

    final results = await container.read(calendarEventsProvider.future);

    expect(results.first.id, 'e1');
    expect(results.first.volumeOverride, 0.8);
  });
}
