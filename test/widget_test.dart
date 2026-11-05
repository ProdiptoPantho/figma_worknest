// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:figma_worknest/api_client.dart';
import 'package:figma_worknest/main.dart';

void main() {
  testWidgets('dashboard renders primary workday controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(WorknestApp(api: _FakeApiClient()));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@company.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'securepass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, Alex'), findsOneWidget);
    expect(find.text('Working time'), findsOneWidget);
    expect(find.text('Clock out'), findsOneWidget);
  });
}

class _FakeApiClient extends HrmApiClient {
  @override
  Future<AuthSession> login(String email, String password) async {
    return const AuthSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      email: 'alex@company.com',
      roles: ['hr manager'],
      permissions: [],
    );
  }
}
