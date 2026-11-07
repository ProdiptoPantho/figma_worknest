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
    expect(find.text('Clocked in at 9:00 AM'), findsOneWidget);
    expect(find.text('Check out'), findsOneWidget);
  });

  testWidgets('attendance page shows today, history, and team data', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Attendance').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Check in, check out, and review working hours.'),
      findsOneWidget,
    );
    expect(find.text('Check-out'), findsWidgets);
    expect(find.textContaining('My attendance —'), findsOneWidget);
    expect(find.text('user3@company.com'), findsWidgets);
    expect(find.text("Today's team attendance"), findsOneWidget);
    expect(find.textContaining('Monthly summary —'), findsOneWidget);
    expect(api.adminDailyCalls, 1);
    expect(api.adminSummaryCalls, 1);
  });

  testWidgets('checking in updates the dashboard through the API', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient(hasTodayRecord: false);
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    expect(find.text('You have not checked in today'), findsOneWidget);

    await tester.ensureVisible(find.text('Clock in'));
    await tester.tap(find.text('Clock in'));
    await tester.pumpAndSettle();

    expect(api.checkInCalls, 1);
    expect(find.text('Checked in successfully.'), findsOneWidget);
    expect(find.text('Clocked in at 9:00 AM'), findsOneWidget);
    expect(find.text('Clock out'), findsOneWidget);
  });

  testWidgets('forgot password sets a new password through the API', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('forgot-email')),
      'user3@company.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(api.requestedResetEmail, 'user3@company.com');
    expect(find.text('Set a new password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reset-token')),
      'test-reset-token',
    );
    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'NewPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm')),
      'Different123!',
    );
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(api.resetEmail, isNull);

    await tester.enterText(
      find.byKey(const Key('reset-confirm')),
      'NewPass123!',
    );
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();

    expect(api.resetEmail, 'user3@company.com');
    expect(api.resetPasswordValue, 'NewPass123!');
    expect(api.resetTokenValue, 'test-reset-token');
    expect(find.text('Set a new password'), findsNothing);
    expect(
      find.text('Password updated. Sign in with your new password.'),
      findsOneWidget,
    );
  });

  testWidgets('a reset link opens the password step directly', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    await tester.pumpWidget(
      WorknestApp(
        api: api,
        resetLink: const PasswordResetLink(
          email: 'user3@company.com',
          token: 'link-reset-token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
    final tokenField = tester.widget<TextFormField>(
      find.byKey(const Key('reset-token')),
    );
    expect(tokenField.controller?.text, 'link-reset-token');

    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'NewPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm')),
      'NewPass123!',
    );
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();

    expect(api.resetEmail, 'user3@company.com');
    expect(api.resetTokenValue, 'link-reset-token');
  });
}

class _FakeApiClient extends HrmApiClient {
  _FakeApiClient({this.hasTodayRecord = true});

  final bool hasTodayRecord;

  String? requestedResetEmail;
  String? resetEmail;
  String? resetPasswordValue;
  String? resetTokenValue;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  int adminDailyCalls = 0;
  int adminSummaryCalls = 0;
  bool _checkedIn = false;

  static final DateTime _day = DateTime(2026, 11, 7);

  AttendanceRecord _record({
    DateTime? checkInAt,
    DateTime? checkOutAt,
    AttendanceStatus status = AttendanceStatus.present,
    int workingMinutes = 0,
  }) {
    return AttendanceRecord(
      id: 'rec-1',
      userId: 'user-1',
      date: _day,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      status: status,
      workingDurationMinutes: workingMinutes,
      lateMinutes: 0,
      notes: null,
    );
  }

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

  @override
  Future<TodayAttendance> getTodayAttendance() async {
    if (!hasTodayRecord && !_checkedIn) {
      return const TodayAttendance(hasRecord: false, record: null);
    }
    return TodayAttendance(
      hasRecord: true,
      record: _record(
        checkInAt: DateTime(2026, 11, 7, 9),
        status: AttendanceStatus.present,
      ),
    );
  }

  @override
  Future<AttendanceHistory> getMyAttendance({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final records = [
      _record(
        checkInAt: DateTime(2026, 11, 6, 9, 2),
        checkOutAt: DateTime(2026, 11, 6, 17, 30),
        workingMinutes: 508,
      ),
      _record(
        checkInAt: DateTime(2026, 11, 5, 9, 20),
        checkOutAt: DateTime(2026, 11, 5, 18, 1),
        status: AttendanceStatus.late,
        workingMinutes: 521,
      ),
    ];
    return AttendanceHistory(
      records: records,
      totalCount: records.length,
      page: 1,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<CheckInResult> checkIn({String? notes}) async {
    checkInCalls++;
    _checkedIn = true;
    return CheckInResult(
      attendanceId: 'rec-new',
      date: _day,
      checkInAt: DateTime(2026, 11, 7, 9),
      status: AttendanceStatus.present,
      message: 'Checked in successfully.',
    );
  }

  @override
  Future<CheckOutResult> checkOut({String? notes}) async {
    checkOutCalls++;
    return CheckOutResult(
      attendanceId: 'rec-1',
      date: _day,
      checkInAt: DateTime(2026, 11, 7, 9),
      checkOutAt: DateTime(2026, 11, 7, 17, 30),
      workingDurationMinutes: 510,
      status: AttendanceStatus.present,
      message: 'Checked out successfully.',
    );
  }

  @override
  Future<AdminDailyReport> getAdminDailyReport(DateTime date) async {
    adminDailyCalls++;
    return AdminDailyReport(
      date: _day,
      records: [
        AdminDailyEntry(
          userId: 'user-1',
          userEmail: 'alex@company.com',
          userGoal: 'HR Manager',
          date: _day,
          checkInAt: DateTime(2026, 11, 7, 9),
          checkOutAt: null,
          status: AttendanceStatus.present,
          workingDurationMinutes: 0,
          lateMinutes: 0,
          hasRecord: true,
        ),
        AdminDailyEntry(
          userId: 'user-3',
          userEmail: 'user3@company.com',
          userGoal: 'Employee',
          date: _day,
          checkInAt: null,
          checkOutAt: null,
          status: AttendanceStatus.holiday,
          workingDurationMinutes: 0,
          lateMinutes: 0,
          hasRecord: false,
        ),
      ],
      totalUsers: 2,
      presentCount: 1,
      lateCount: 0,
      absentCount: 0,
      onLeaveCount: 0,
      noRecordCount: 1,
    );
  }

  @override
  Future<AdminMonthlySummary> getAdminMonthlySummary({
    required int year,
    required int month,
  }) async {
    adminSummaryCalls++;
    return AdminMonthlySummary(
      year: year,
      month: month,
      summaries: [
        MonthlyAttendanceSummary(
          year: year,
          month: month,
          userId: 'user-1',
          userEmail: 'alex@company.com',
          workingDaysInMonth: 21,
          presentDays: 18,
          lateDays: 2,
          absentDays: 1,
          onLeaveDays: 0,
          incompleteDays: 0,
          totalWorkingMinutes: 9000,
          attendancePercentage: 95.2,
          averageWorkingHoursPerDay: 8.1,
        ),
      ],
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    requestedResetEmail = email;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String resetToken,
  }) async {
    resetEmail = email;
    resetPasswordValue = newPassword;
    resetTokenValue = resetToken;
  }
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'alex@company.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'securepass');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}
