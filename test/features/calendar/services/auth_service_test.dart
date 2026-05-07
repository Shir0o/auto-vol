import 'package:volo/features/calendar/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late AuthService authService;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    authService = AuthService(mockGoogleSignIn);
  });

  group('AuthService', () {
    test('signIn should call GoogleSignIn.authenticate', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockAccount);

      final result = await authService.signIn();

      expect(result, mockAccount);
      verify(() => mockGoogleSignIn.authenticate()).called(1);
    });

    test('signOut should call GoogleSignIn.signOut', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await authService.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
