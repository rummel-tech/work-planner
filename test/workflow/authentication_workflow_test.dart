import 'package:artemis_work_planner/src/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';

void main() {
  group('Workflow 3: Authentication', () {
    late FakeAuthService auth;

    setUp(() {
      auth = FakeAuthService(authenticated: false);
    });

    test('new user is not authenticated', () async {
      expect(await auth.isAuthenticated(), isFalse);
      expect(await auth.getAccessToken(), isNull);
      expect(await auth.getUserId(), isNull);
      expect(await auth.getEmail(), isNull);
    });

    test('login with valid credentials authenticates the user', () async {
      await auth.login(email: 'test@test.com', password: 'password123');
      expect(await auth.isAuthenticated(), isTrue);
      expect(await auth.getAccessToken(), 'fake_token');
      expect(await auth.getRefreshToken(), 'fake_refresh');
      expect(await auth.getUserId(), 'test-user-id');
      expect(await auth.getEmail(), 'test@test.com');
    });

    test('login with wrong credentials throws AuthException', () async {
      expect(
        () => auth.login(email: 'wrong@test.com', password: 'bad'),
        throwsA(isA<AuthException>()),
      );
    });

    test('user remains unauthenticated after failed login attempt', () async {
      try {
        await auth.login(email: 'bad@test.com', password: 'wrong');
      } on AuthException {
        // expected
      }
      expect(await auth.isAuthenticated(), isFalse);
      expect(await auth.getAccessToken(), isNull);
    });

    test('register creates an authenticated session', () async {
      final result = await auth.register(
        email: 'newuser@test.com',
        password: 'securepass',
        fullName: 'Jane Doe',
        registrationCode: 'INVITE123',
      );
      expect(result['status'], 'registered');
      expect(await auth.isAuthenticated(), isTrue);
    });

    test(
      'register without a code also authenticates (fake always succeeds)',
      () async {
        final result = await auth.register(
          email: 'waitlister@test.com',
          password: 'pass1234',
        );
        expect(result['status'], 'registered');
        expect(await auth.isAuthenticated(), isTrue);
      },
    );

    test('logout removes authentication and clears tokens', () async {
      await auth.login(email: 'test@test.com', password: 'password123');
      expect(await auth.isAuthenticated(), isTrue);

      await auth.logout();

      expect(await auth.isAuthenticated(), isFalse);
      expect(await auth.getAccessToken(), isNull);
      expect(await auth.getRefreshToken(), isNull);
      expect(await auth.getUserId(), isNull);
      expect(await auth.getEmail(), isNull);
    });

    test('pre-authenticated user has tokens immediately', () async {
      final preAuth = FakeAuthService(authenticated: true);
      expect(await preAuth.isAuthenticated(), isTrue);
      expect(await preAuth.getAccessToken(), 'fake_token');
      expect(await preAuth.getRefreshToken(), 'fake_refresh');
    });

    test('full auth lifecycle: unauthenticated -> login -> logout', () async {
      expect(await auth.isAuthenticated(), isFalse);

      await auth.login(email: 'test@test.com', password: 'password123');
      expect(await auth.isAuthenticated(), isTrue);

      await auth.logout();
      expect(await auth.isAuthenticated(), isFalse);

      // Can log back in after logout
      await auth.login(email: 'test@test.com', password: 'password123');
      expect(await auth.isAuthenticated(), isTrue);
    });
  });
}
