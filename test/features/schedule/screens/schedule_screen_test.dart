import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocus/features/calendar/models/calendar_event.dart';
import 'package:vocus/features/calendar/providers/calendar_provider.dart';
import 'package:vocus/features/schedule/screens/schedule_screen.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets('ScheduleScreen shows skeleton loader when loading', (tester) async {
    final completer = Completer<List<CalendarEvent>>();
    final loadingProvider = FutureProvider<List<CalendarEvent>>((ref) => completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarEventsProvider.overrideWith((ref) => ref.watch(loadingProvider.future)),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();

    // Should find Shimmer instead of CircularProgressIndicator
    expect(find.byType(Shimmer), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Complete to clean up
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('ScheduleScreen has RefreshIndicator and triggers refresh', (tester) async {
    int callCount = 0;
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarEventsProvider.overrideWith((ref) async {
            callCount++;
            return [
              CalendarEvent(
                id: '1',
                title: 'Test Event $callCount',
                startTime: DateTime.now().add(const Duration(hours: 1)),
                endTime: DateTime.now().add(const Duration(hours: 2)),
                calendarId: 'primary',
                calendarTitle: 'Work',
                calendarColor: '#FF0000',
              ),
            ];
          }),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Event 1'), findsOneWidget);
    expect(find.textContaining('Work'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(callCount, 1);

    // Find RefreshIndicator
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Trigger Refresh
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump(); // start refresh
    await tester.pump(const Duration(seconds: 1)); // wait for refresh
    await tester.pumpAndSettle();

    // Verify it refreshed
    expect(find.text('Test Event 2'), findsOneWidget);
    expect(callCount, 2);
  });
}
