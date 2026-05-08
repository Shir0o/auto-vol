import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as google;
import 'package:mocktail/mocktail.dart';

class MockGoogleEvent extends Mock implements google.Event {}

class MockEventDateTime extends Mock implements google.EventDateTime {}

void main() {
  group('CalendarEvent', () {
    test('should correctly instantiate from JSON-like data', () {
      final startTime = DateTime(2026, 5, 7, 10, 0);
      final endTime = DateTime(2026, 5, 7, 11, 0);

      final event = CalendarEvent(
        id: '1',
        title: 'Meeting',
        description: 'Team sync',
        startTime: startTime,
        endTime: endTime,
        calendarId: 'primary',
      );

      expect(event.id, '1');
      expect(event.title, 'Meeting');
      expect(event.description, 'Team sync');
      expect(event.startTime, startTime);
      expect(event.endTime, endTime);
      expect(event.calendarId, 'primary');
    });

    test('should have a volumeOverride field', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Meeting',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        calendarId: 'primary',
        volumeOverride: 0.5,
      );

      expect(event.volumeOverride, 0.5);
    });

    test('should correctly parse from googleapis.Event', () {
      final googleEvent = MockGoogleEvent();
      final start = MockEventDateTime();
      final end = MockEventDateTime();

      final startTime = DateTime(2026, 5, 7, 10, 0);
      final endTime = DateTime(2026, 5, 7, 11, 0);

      when(() => googleEvent.id).thenReturn('google_123');
      when(() => googleEvent.summary).thenReturn('Google Meeting');
      when(() => googleEvent.description).thenReturn('Detailed description');
      when(() => googleEvent.start).thenReturn(start);
      when(() => googleEvent.end).thenReturn(end);
      when(() => start.dateTime).thenReturn(startTime);
      when(() => end.dateTime).thenReturn(endTime);

      final event = CalendarEvent.fromGoogleEvent(googleEvent, 'calendar_abc');

      expect(event.id, 'google_123');
      expect(event.title, 'Google Meeting');
      expect(event.description, 'Detailed description');
      expect(event.startTime, startTime);
      expect(event.endTime, endTime);
      expect(event.calendarId, 'calendar_abc');
    });

    group('parseVolumeOverride', () {
      test('should parse [vol:0.2] format', () {
        expect(CalendarEvent.parseVolumeOverride('Meeting [vol:0.2]'), 0.2);
        expect(CalendarEvent.parseVolumeOverride('[vol:1.0] Focus'), 1.0);
      });

      test('should parse percentage [vol:20%] format', () {
        expect(CalendarEvent.parseVolumeOverride('Meeting [vol:20%]'), 0.2);
        expect(CalendarEvent.parseVolumeOverride('[vol:100%] Alarm'), 1.0);
      });

      test('should parse !silent and !mute as 0.0', () {
        expect(CalendarEvent.parseVolumeOverride('Deep Work !silent'), 0.0);
        expect(CalendarEvent.parseVolumeOverride('!mute this'), 0.0);
      });

      test('should parse !loud as 1.0', () {
        expect(CalendarEvent.parseVolumeOverride('Emergency !loud'), 1.0);
      });

      test('should return null if no pattern found', () {
        expect(
          CalendarEvent.parseVolumeOverride('Just a normal meeting'),
          null,
        );
      });
    });

    test(
      'fromGoogleEvent should parse volumeOverride from title or description',
      () {
        final googleEvent = MockGoogleEvent();
        final start = MockEventDateTime();
        final end = MockEventDateTime();

        when(() => googleEvent.id).thenReturn('1');
        when(() => googleEvent.summary).thenReturn('Meeting [vol:0.1]');
        when(() => googleEvent.description).thenReturn('Notes');
        when(() => googleEvent.start).thenReturn(start);
        when(() => googleEvent.end).thenReturn(end);
        when(() => start.dateTime).thenReturn(DateTime.now());
        when(() => end.dateTime).thenReturn(DateTime.now());

        final event = CalendarEvent.fromGoogleEvent(googleEvent, 'cal');
        expect(event.volumeOverride, 0.1);

        when(() => googleEvent.summary).thenReturn('Silent meeting');
        when(() => googleEvent.description).thenReturn('Details !silent');
        final event2 = CalendarEvent.fromGoogleEvent(googleEvent, 'cal');
        expect(event2.volumeOverride, 0.0);
      },
    );
  });
}
