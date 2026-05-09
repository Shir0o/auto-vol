import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocus/core/providers/common_providers.dart';
import 'package:vocus/core/services/permission_service.dart';
import 'package:vocus/features/calendar/services/auth_service.dart';
import 'package:vocus/features/onboarding/screens/welcome_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockAuthService extends Mock implements AuthService {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockPermissionService mockPermissionService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockAuthService = MockAuthService();

    when(
      () => mockPermissionService.hasNotificationPermission(),
    ).thenAnswer((_) async => false);
    when(
      () => mockPermissionService.hasNotificationPolicyAccess(),
    ).thenAnswer((_) async => false);
    when(
      () => mockPermissionService.isIgnoringBatteryOptimizations(),
    ).thenAnswer((_) async => false);

    when(() => mockAuthService.signInSilently()).thenAnswer((_) async => null);
  });

  Widget createWelcomeScreen({List overrides = const []}) {
    return ProviderScope(
      overrides: [
        permissionServiceProvider.overrideWithValue(mockPermissionService),
        authServiceProvider.overrideWithValue(mockAuthService),
        ...overrides,
      ],
      child: const MaterialApp(home: WelcomeScreen()),
    );
  }

  group('WelcomeScreen', () {
    testWidgets('renders welcome message and onboarding items', (tester) async {
      await tester.pumpWidget(createWelcomeScreen());

      expect(find.text('Welcome to Vocus'), findsOneWidget);
      expect(find.text('Notification Access'), findsOneWidget);
      expect(find.text('Do Not Disturb Access'), findsOneWidget);
      expect(find.text('Background Activity'), findsOneWidget);
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('calls signIn when Google button is pressed', (tester) async {
      when(
        () => mockAuthService.signIn(),
      ).thenAnswer((_) async => MockGoogleSignInAccount());

      await tester.pumpWidget(createWelcomeScreen());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Authorize'));
      await tester.pump();

      verify(() => mockAuthService.signIn()).called(1);
    });

    testWidgets('shows "Linked" when signed in', (tester) async {
      when(
        () => mockAuthService.signInSilently(),
      ).thenAnswer((_) async => MockGoogleSignInAccount());

      await tester.pumpWidget(createWelcomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Linked'), findsOneWidget);
    });

    testWidgets('calls requestNotificationPermission when button is pressed', (
      tester,
    ) async {
      when(
        () => mockPermissionService.requestNotificationPermission(),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWelcomeScreen());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Allow').first);
      await tester.pump();

      verify(
        () => mockPermissionService.requestNotificationPermission(),
      ).called(1);
    });

    testWidgets('shows "Granted" when permission is already allowed', (
      tester,
    ) async {
      when(
        () => mockPermissionService.hasNotificationPermission(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createWelcomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Granted'), findsAtLeast(1));
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsAtLeast(1));
    });

    testWidgets('Get Started button triggers onboarding completion', (
      tester,
    ) async {
      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getBool('onboarding_completed')).thenReturn(false);
      when(
        () => mockPrefs.setBool('onboarding_completed', true),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createWelcomeScreen(
          overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)],
        ),
      );

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      verify(() => mockPrefs.setBool('onboarding_completed', true)).called(1);
    });
  });
}
