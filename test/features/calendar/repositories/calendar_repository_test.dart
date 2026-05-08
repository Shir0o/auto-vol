import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/repositories/calendar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:mocktail/mocktail.dart';

class MockCalendarApi extends Mock implements google.CalendarApi {}
class MockEventsResource extends Mock implements google.EventsResource {}
class MockEvents extends Mock implements google.Events {}
class MockEvent extends Mock implements google.Event {}
class MockEventDateTime extends Mock implements google.EventDateTime {}
class MockCalendarListResource extends Mock implements google.CalendarListResource {}
class MockCalendarList extends Mock implements google.CalendarList {}
class MockCalendarListEntry extends Mock implements google.CalendarListEntry {}

void main() {
  late CalendarRepository repository;
  late MockCalendarApi mockApi;
  late MockEventsResource mockEventsResource;
  late MockCalendarListResource mockCalendarListResource;

  setUp(() {
    mockApi = MockCalendarApi();
    mockEventsResource = MockEventsResource();
    mockCalendarListResource = MockCalendarListResource();
    repository = CalendarRepository(mockApi);

    when(() => mockApi.events).thenReturn(mockEventsResource);
    when(() => mockApi.calendarList).thenReturn(mockCalendarListResource);
  });

  group('CalendarRepository.fetchCalendars', () {
    test('should fetch and convert google calendar list to CalendarEntry list', () async {
      final mockCalendarList = MockCalendarList();
      final mockEntry = MockCalendarListEntry();

      when(() => mockCalendarListResource.list()).thenAnswer((_) async => mockCalendarList);
      when(() => mockCalendarList.items).thenReturn([mockEntry]);
      when(() => mockEntry.id).thenReturn('cal-1');
      when(() => mockEntry.summary).thenReturn('My Calendar');
      when(() => mockEntry.description).thenReturn('Work');
      when(() => mockEntry.primary).thenReturn(true);

      final results = await repository.fetchCalendars();

      expect(results.length, 1);
      expect(results.first.id, 'cal-1');
      expect(results.first.title, 'My Calendar');
      expect(results.first.isPrimary, true);
    });
  });

  group('CalendarRepository.fetchEvents', () {
    test('should fetch and convert google events to CalendarEvent list', () async {
      final mockEvents = MockEvents();
      final mockEvent = MockEvent();
      final start = MockEventDateTime();
      final end = MockEventDateTime();

      when(() => mockEventsResource.list(
            any(),
            timeMin: any(named: 'timeMin'),
            timeMax: any(named: 'timeMax'),
            singleEvents: any(named: 'singleEvents'),
          )).thenAnswer((_) async => mockEvents);

      when(() => mockEvents.items).thenReturn([mockEvent]);
      when(() => mockEvent.id).thenReturn('123');
      when(() => mockEvent.summary).thenReturn('Test Event');
      when(() => mockEvent.start).thenReturn(start);
      when(() => mockEvent.end).thenReturn(end);
      when(() => start.dateTime).thenReturn(DateTime.now());
      when(() => end.dateTime).thenReturn(DateTime.now().add(const Duration(hours: 1)));

      final results = await repository.fetchEvents('primary');

      expect(results.length, 1);
      expect(results.first.title, 'Test Event');
      expect(results.first.id, '123');
    });
  });
}
