import 'package:artemis_work_planner/src/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_setup.dart';

void main() {
  setUp(() {
    mockSecureStorage();
    initTestServices(authenticated: false);
  });

  Widget buildScreen() => testWidget(const RegisterScreen());

  group('RegisterScreen', () {
    testWidgets('shows "Create Account" in the AppBar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows all four form fields', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Full Name (optional)'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Registration Code (optional)'),
          findsOneWidget);
    });

    testWidgets('has a "Create Account" submit button', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(
          find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);
    });

    testWidgets('shows "Email is required" when email field is empty',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows password length validation for short passwords',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'new@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('At least 8 characters required'), findsOneWidget);
    });

    testWidgets('shows "Already have an account? Sign In" navigation link',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('shows helper text hints for password and registration code',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Leave blank to join the waitlist'), findsOneWidget);
    });
  });
}
