import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/services/permission_service.dart';
import 'package:vocus/features/calendar/services/auth_service.dart';
import 'package:vocus/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  testWidgets('VocusApp renders MainScreen when onboarding is completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final prefs = await SharedPreferences.getInstance();

    final mockAuthService = MockAuthService();
    final mockPermissionService = MockPermissionService();

    when(() => mockAuthService.signInSilently()).thenAnswer((_) async => null);
    when(
      () => mockPermissionService.requestInitialPermissions(),
    ).thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuthService),
          permissionServiceProvider.overrideWithValue(mockPermissionService),
        ],
        child: const VocusApp(),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    expect(find.text('Schedule'), findsNWidgets(2));
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('VocusApp renders WelcomeScreen when onboarding is NOT completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': false});
    final prefs = await SharedPreferences.getInstance();

    final mockAuthService = MockAuthService();
    final mockPermissionService = MockPermissionService();

    when(() => mockAuthService.signInSilently()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authServiceProvider.overrideWithValue(mockAuthService),
          permissionServiceProvider.overrideWithValue(mockPermissionService),
        ],
        child: const VocusApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome to Vocus'), findsOneWidget);
    expect(find.text('Notification Access'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
