import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/features/calendar/models/calendar_entry.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

class FakeEnabledCalendarIdsNotifier extends EnabledCalendarIdsNotifier {
  final Set<String> _initialState;
  FakeEnabledCalendarIdsNotifier(this._initialState);
  @override
  Set<String> build() => _initialState;
}

void main() {
  late MockCalendarRepository mockRepository;

  setUp(() {
    mockRepository = MockCalendarRepository();
  });

  test('availableCalendarsProvider fetches from repository', () async {
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) async => mockRepository),
      ],
    );
    addTearDown(container.dispose);

    final calendars = [
      CalendarEntry(id: '1', title: 'Primary', isPrimary: true),
      CalendarEntry(id: '2', title: 'Holidays'),
    ];

    when(() => mockRepository.fetchCalendars()).thenAnswer((_) async => calendars);

    final result = await container.read(availableCalendarsProvider.future);
    expect(result, calendars);
    verify(() => mockRepository.fetchCalendars()).called(1);
  });

  test('enabledCalendarIdsProvider defaults to primary if nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        availableCalendarsProvider.overrideWith((ref) async => [
          CalendarEntry(id: 'cal-1', title: 'Primary', isPrimary: true),
          CalendarEntry(id: 'cal-2', title: 'Other'),
        ]),
      ],
    );
    addTearDown(container.dispose);

    // Wait for availableCalendarsProvider to finish
    await container.read(availableCalendarsProvider.future);

    // Initial state should include cal-1
    final enabledIds = container.read(enabledCalendarIdsProvider);
    expect(enabledIds, contains('cal-1'));
    expect(enabledIds.length, 1);
  });

  test('enabledCalendarIdsProvider toggles IDs and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        availableCalendarsProvider.overrideWith((ref) async => [
          CalendarEntry(id: 'cal-1', title: 'Primary', isPrimary: true),
          CalendarEntry(id: 'cal-2', title: 'Other'),
        ]),
      ],
    );
    addTearDown(container.dispose);

    // Wait for availableCalendarsProvider to finish
    await container.read(availableCalendarsProvider.future);

    await container.read(enabledCalendarIdsProvider.notifier).toggle('cal-2');
    
    expect(container.read(enabledCalendarIdsProvider), containsAll(['cal-1', 'cal-2']));
    expect(prefs.getStringList('enabled_calendar_ids'), containsAll(['cal-1', 'cal-2']));

    await container.read(enabledCalendarIdsProvider.notifier).toggle('cal-1');
    expect(container.read(enabledCalendarIdsProvider), contains('cal-2'));
    expect(container.read(enabledCalendarIdsProvider), isNot(contains('cal-1')));
  });

  test('calendarEventsProvider aggregates and sorts events from enabled calendars', () async {
    final container = ProviderContainer(
      overrides: [
        calendarRepositoryProvider.overrideWith((ref) async => mockRepository),
        enabledCalendarIdsProvider.overrideWith(() => FakeEnabledCalendarIdsNotifier({'cal-1', 'cal-2'})),
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
    );
    final event2 = CalendarEvent(
      id: 'e2',
      title: 'Event 2',
      startTime: now.add(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      calendarId: 'cal-2',
    );

    when(() => mockRepository.fetchEvents('cal-1')).thenAnswer((_) async => [event1]);
    when(() => mockRepository.fetchEvents('cal-2')).thenAnswer((_) async => [event2]);

    final results = await container.read(calendarEventsProvider.future);

    expect(results.length, 2);
    // Should be sorted by start time
    expect(results.first.id, 'e2');
    expect(results.last.id, 'e1');
  });
}
