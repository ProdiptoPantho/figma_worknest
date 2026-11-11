import 'package:shared_preferences/shared_preferences.dart';
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  testWidgets('pressing Enter on the password field signs in', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@company.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'securepass');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, Alex'), findsOneWidget);
  });

  testWidgets('my leave page shows balances and history', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('My leave').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Request time away and track your leave history.'),
      findsOneWidget,
    );
    expect(find.text('Available balance'), findsOneWidget);
    expect(find.textContaining('Leave balance'), findsOneWidget);
    expect(find.text('Annual'), findsWidgets);
    expect(find.text('Approved'), findsWidgets);
    expect(api.myLeaveCalls, 1);
  });

  testWidgets('manager can approve a leave request', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    expect(find.text('user3@company.com'), findsWidgets);
    expect(find.text('Approve'), findsWidgets);

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();

    expect(find.text('Approve leave?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Approve')));
    await tester.pumpAndSettle();

    expect(api.approveCalls, 1);
    expect(find.text('Leave request approved.'), findsOneWidget);
  });

  testWidgets('manager can reject a leave request and it updates state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    expect(find.text('user3@company.com'), findsWidgets);
    expect(find.text('Reject'), findsWidgets);

    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();

    expect(find.text('Reject leave?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reject')));
    await tester.pumpAndSettle();

    expect(api.rejectCalls, 1);
    expect(find.text('Leave request rejected.'), findsOneWidget);
  });

  testWidgets('forgot password sends a reset link and confirms by message', (
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
    expect(find.text('Reset your password'), findsNothing);
    expect(
      find.text(
        'If the email exists, a password reset link has been sent to your inbox.',
      ),
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

  testWidgets('toggle dark theme switches application theme mode', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(WorknestApp(api: _FakeApiClient()));
    await _signIn(tester);

    expect(find.text('Dark theme'), findsOneWidget);
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();

    expect(find.text('Light theme'), findsOneWidget);
  });

  testWidgets('request leave dialog enforces mandatory reason', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('New request'));
    await tester.pumpAndSettle();

    expect(find.text('Request leave'), findsOneWidget);
    expect(find.text('Reason *'), findsOneWidget);
    expect(find.text('Add document / attachment'), findsOneWidget);

    // Try submitting without reason
    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please provide a reason for your leave request.'),
      findsOneWidget,
    );
    expect(api.leaveRequestCalls, 0);
  });

  testWidgets('request leave dialog displays exact backend validation error on overlapping dates', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    api.requestLeaveError =
        'You already have a pending or approved leave that overlaps with the requested dates.';
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('New request'));
    await tester.pumpAndSettle();

    // Select start date
    await tester.tap(find.text('Select date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Enter reason
    await tester.enterText(find.byType(TextFormField).first, 'Medical recovery');
    await tester.pumpAndSettle();

    // Submit request
    await tester.tap(find.text('Submit request'));
    await tester.pumpAndSettle();

    // Dialog stays open and displays exact backend error message
    expect(
      find.text('You already have a pending or approved leave that overlaps with the requested dates.'),
      findsOneWidget,
    );
  });

  testWidgets('leave rejection dialog enforces mandatory reason with red asterisk', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();

    expect(find.text('Reason for rejection'), findsOneWidget);
    expect(find.text('Rejection reason *'), findsOneWidget);

    // Clear text and attempt to reject without reason
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)), '');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reject')));
    await tester.pumpAndSettle();

    expect(find.text('Rejection reason is required *'), findsOneWidget);
    expect(api.rejectCalls, 0);

    // Enter valid reason and confirm
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)), 'Staffing coverage requirements');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Reject')));
    await tester.pumpAndSettle();

    expect(api.rejectCalls, 1);
    expect(find.text('Leave request rejected.'), findsOneWidget);
  });

  testWidgets('rbac list users includes project manager and all seeded users', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    final users = await api.listUsers();
    expect(users.length, greaterThanOrEqualTo(5));
    expect(users.any((u) => u.email == 'pm@company.com'), isTrue);
    expect(users.any((u) => u.email == 'admin@company.com'), isTrue);
    expect(users.any((u) => u.email == 'hrmanager@company.com'), isTrue);
  });

  testWidgets('task manager loads categories and displays task counts', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    final categories = await api.getTaskCategories();
    expect(categories, contains('Operations'));
    expect(categories, contains('Compliance'));

    final summary = await api.getTaskSummary();
    expect(summary.totalTasks, greaterThanOrEqualTo(0));
  });

  testWidgets('project manager can assign task to employee', (
    WidgetTester tester,
  ) async {
    final api = _FakeApiClient();
    final task = await api.assignTask(
      title: 'Setup CI/CD pipeline',
      assigneeUserId: '6ad3da0e-3b91-4657-85d0-258a29f25df3',
      assigneeEmail: 'user1@company.com',
      description: 'Configure automated build on GitHub Actions',
      category: 'Projects',
      priority: 'High',
    );

    expect(task.title, 'Setup CI/CD pipeline');
    expect(task.assignedToEmail, 'user1@company.com');
    expect(task.assignedToUserId, '6ad3da0e-3b91-4657-85d0-258a29f25df3');
    expect(task.category, 'Projects');
    expect(task.priority, 'High');

    final assignedList = await api.getAssignedTasks();
    expect(assignedList.any((t) => t.id == task.id), isTrue);
  });

  testWidgets('session restoration automatically navigates to dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeApiClient(
      fakeRestoredSession: const AuthSession(
        accessToken: 'saved-token',
        refreshToken: 'saved-refresh',
        email: 'alex@company.com',
        roles: ['hr manager'],
        permissions: [],
      ),
    );
    await tester.pumpWidget(
      WorknestApp(api: api, autoRestoreSession: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, Alex'), findsOneWidget);
    expect(find.text('Clock out'), findsOneWidget);
  });

  testWidgets('login screen respects dark theme with crisp contrast', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          cardColor: const Color(0xFF1E293B),
        ),
        home: LoginPage(
          api: _FakeApiClient(),
          onAuthenticated: (_) {},
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, const Color(0xFF1E293B));

    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    for (final field in textFields) {
      expect(field.style?.color, const Color(0xFFF1F5F9));
      expect(field.decoration?.fillColor, const Color(0xFF0F172A));
    }
  });

  testWidgets('manager can view document and approve leave request from document viewer', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    expect(find.text('View document'), findsWidgets);

    // Tap View document on the first request
    await tester.tap(find.text('View document').first);
    await tester.pumpAndSettle();

    // Verify document viewer dialog opens with official certificate letterhead & details
    expect(find.text('VERIFIED RECORD'), findsOneWidget);
    expect(find.text('APPLICANT & LEAVE SPECIFICATION'), findsOneWidget);
    expect(find.text('STATEMENT OF REASON & JUSTIFICATION'), findsOneWidget);
    expect(find.text('Approve request'), findsOneWidget);
    expect(find.text('Reject request'), findsOneWidget);

    // Tap Approve request directly inside the document viewer
    await tester.tap(find.text('Approve request'));
    await tester.pumpAndSettle();

    // Verify approval confirmation dialog opens and confirm
    expect(find.text('Approve leave?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Approve')));
    await tester.pumpAndSettle();

    expect(api.approveCalls, 1);
    expect(find.text('Leave request approved.'), findsOneWidget);
  });

  testWidgets('system wide enter button works on leave rejection dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('Leave requests').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();

    expect(find.text('Reject leave?'), findsOneWidget);

    // Press Enter to confirm rejection
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(api.rejectCalls, 1);
    expect(find.text('Leave request rejected.'), findsOneWidget);
  });

  testWidgets('attendance complete banner in dark mode uses dark teal surface, not blinding white', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient(checkedOutToday: true);
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    // Switch to dark theme
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();

    expect(find.text('Attendance complete for today.'), findsOneWidget);

    final text = tester.widget<Text>(find.text('Attendance complete for today.'));
    expect(text.style?.color, const Color(0xFF2DD4BF));

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.text('Attendance complete for today.'),
        matching: find.byType(Container),
      ).first,
    );
    final decor = container.decoration as BoxDecoration?;
    expect(decor?.color, const Color(0xFF132A26));
  });

  testWidgets('employee can view provided document in app from my leave history', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    await tester.tap(find.text('My leave').first);
    await tester.pumpAndSettle();

    expect(find.text('View document'), findsWidgets);

    // Click View document on the employee's request
    await tester.tap(find.text('View document').first);
    await tester.pumpAndSettle();

    // Verify in-app document viewer sheet and interactive toolbar
    expect(find.text('Document Sheet'), findsOneWidget);
    expect(find.text('Audit & Details'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('VERIFIED RECORD'), findsOneWidget);
    expect(find.text('APPLICANT & LEAVE SPECIFICATION'), findsOneWidget);
    expect(find.text('STATEMENT OF REASON & JUSTIFICATION'), findsOneWidget);

    // Switch to Audit & Details tab
    await tester.tap(find.text('Audit & Details'));
    await tester.pumpAndSettle();

    expect(find.text('FILE VERIFICATION AUDIT'), findsOneWidget);
    expect(find.text('Document Name'), findsOneWidget);

    // Close the viewer
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('FILE VERIFICATION AUDIT'), findsNothing);
  });

  testWidgets('user can resize navbar with drag handle and collapse/expand', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    // Initial sidebar width is 224
    final sidebarFinder = find.byKey(const ValueKey('sidebar_container'));
    expect(sidebarFinder, findsOneWidget);
    var sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, 224.0);

    // Resize by dragging the resize handle to the right
    final handleFinder = find.byKey(const ValueKey('sidebar_resize_handle'));
    expect(handleFinder, findsOneWidget);
    await tester.drag(handleFinder, const Offset(60, 0));
    await tester.pumpAndSettle();

    sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    final resizedWidth = sidebarBox.size.width;
    expect(resizedWidth, greaterThan(224.0));

    // Click collapse button in header
    final collapseBtn = find.byKey(const ValueKey('sidebar_collapse_button'));
    expect(collapseBtn, findsOneWidget);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Verify collapsed to compact rail (72px)
    sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, 72.0);

    // Click expand button to restore previous expanded width
    final expandBtn = find.byKey(const ValueKey('sidebar_collapse_button'));
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, resizedWidth);

    // Double tap resize handle to toggle collapse
    await tester.tap(handleFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(handleFinder);
    await tester.pumpAndSettle();

    sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, 72.0);
  });

  testWidgets('user can change navbar size via preset menu', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApiClient();
    await tester.pumpWidget(WorknestApp(api: api));
    await _signIn(tester);

    final sidebarFinder = find.byKey(const ValueKey('sidebar_container'));
    var sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, 224.0);

    // Open preset menu and select Spacious (320px)
    final presetsBtn = find.byKey(const ValueKey('sidebar_presets_button'));
    expect(presetsBtn, findsOneWidget);
    await tester.tap(presetsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Spacious (320px)'), findsOneWidget);
    await tester.tap(find.text('Spacious (320px)'));
    await tester.pumpAndSettle();

    sidebarBox = tester.renderObject<RenderBox>(sidebarFinder);
    expect(sidebarBox.size.width, 320.0);
  });

  testWidgets('admin or HR manager can add employee with email, password, and assignable role type', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final api = _FakeApiClient();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(WorknestApp(api: api));
    await tester.pumpAndSettle();
    await _signIn(tester);

    // Navigate to Employee management page
    final employeeNav = find.text('Employee management');
    expect(employeeNav, findsOneWidget);
    await tester.tap(employeeNav);
    await tester.pumpAndSettle();

    // Verify "Add employee" button is present and click it
    final addBtn = find.byKey(const ValueKey('add_employee_button'));
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify Add Employee Dialog elements
    expect(find.text('Add employee'), findsWidgets);
    expect(find.byKey(const ValueKey('add_employee_email_input')), findsOneWidget);
    expect(find.byKey(const ValueKey('add_employee_password_input')), findsOneWidget);
    expect(find.byKey(const ValueKey('add_employee_role_dropdown')), findsOneWidget);

    // Test password generator
    final genBtn = find.byKey(const ValueKey('generate_employee_password_button'));
    expect(genBtn, findsOneWidget);
    await tester.tap(genBtn);
    await tester.pump();

    // Fill in email and role
    await tester.enterText(find.byKey(const ValueKey('add_employee_email_input')), 'newdev@company.com');
    await tester.enterText(find.byKey(const ValueKey('add_employee_password_input')), 'SecretPass123!');

    // Select Project Manager role
    await tester.tap(find.byKey(const ValueKey('add_employee_role_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Project Manager').last);
    await tester.pumpAndSettle();

    // Submit via button
    final submitBtn = find.byKey(const ValueKey('submit_add_employee_button'));
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify employee was created and appears in the directory list
    expect(find.text('newdev@company.com'), findsOneWidget);
  });

  testWidgets('overview displays dynamic user name and avatar, not hardcoded Alex', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const session = AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'sara.connor@company.com',
      roles: ['super admin'],
      permissions: [],
      fullName: 'Sara Connor',
    );
    final api = _FakeApiClient(fakeRestoredSession: session);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(WorknestApp(api: api, initialSession: session));
    await tester.pumpAndSettle();

    // Verify dynamic name is displayed in greeting
    expect(find.textContaining('Sara Connor'), findsWidgets);
    expect(find.text('Good afternoon, Alex'), findsNothing);
    // Verify avatar shows S
    expect(find.text('S'), findsWidgets);
  });

  testWidgets('standard employee only sees tasks connected to them and not other employees tasks', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const employeeSession = AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'user3@company.com',
      roles: ['user'],
      permissions: [],
    );
    final api = _FakeApiClient();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(WorknestApp(api: api, initialSession: employeeSession));
    await tester.pumpAndSettle();

    // Navigate to tasks
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    // user3@company.com should see task-3 (assigned to user3@company.com)
    expect(find.textContaining('two-factor authentication'), findsOneWidget);

    // user3@company.com should NOT see user1 or user2 tasks
    expect(find.textContaining('Employee Handbook 2026'), findsNothing);
    expect(find.textContaining('Submit timesheet'), findsNothing);
  });

  testWidgets('super admin role gets full access to all navigation sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const adminSession = AuthSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'admin@company.com',
      roles: ['super admin'],
      permissions: [],
    );
    final api = _FakeApiClient();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(WorknestApp(api: api, initialSession: adminSession));
    await tester.pumpAndSettle();

    // Verify full access navigation items
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Employee management'), findsOneWidget);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Role management'), findsOneWidget);
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text('Super Admin / Owner'), findsOneWidget);
  });
}

class _FakeApiClient extends HrmApiClient {
  _FakeApiClient({
    this.hasTodayRecord = true,
    this.checkedOutToday = false,
    this.fakeRestoredSession,
  });

  final bool hasTodayRecord;
  final bool checkedOutToday;
  final AuthSession? fakeRestoredSession;

  String? requestedResetEmail;
  String? resetEmail;
  String? resetPasswordValue;
  String? resetTokenValue;
  String? requestLeaveError;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  int adminDailyCalls = 0;
  int adminSummaryCalls = 0;
  int myLeaveCalls = 0;
  int leaveRequestCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;
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
  Future<AuthSession?> restoreSession() async => fakeRestoredSession;

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
        checkOutAt: checkedOutToday ? DateTime(2026, 11, 7, 17) : null,
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
  Future<List<LeaveTypeInfo>> getLeaveTypes() async {
    return const [
      LeaveTypeInfo(
        leaveType: 'Annual',
        allowance: 20,
        description: 'Planned time off',
      ),
      LeaveTypeInfo(
        leaveType: 'Sick',
        allowance: 10,
        description: 'Health related leave',
      ),
      LeaveTypeInfo(
        leaveType: 'Casual',
        allowance: 5,
        description: 'Short personal errands',
      ),
      LeaveTypeInfo(
        leaveType: 'Unpaid',
        allowance: 0,
        description: 'Unpaid time off',
      ),
    ];
  }

  LeaveRequestRecord _leaveRecord({
    String id = 'leave-1',
    String userEmail = 'user3@company.com',
    LeaveStatus status = LeaveStatus.pending,
    String leaveType = 'Annual',
    int totalDays = 2,
  }) {
    return LeaveRequestRecord(
      id: id,
      userId: 'user-3',
      userEmail: userEmail,
      leaveType: leaveType,
      startDate: DateTime(2026, 11, 16),
      endDate: DateTime(2026, 11, 17),
      totalDays: totalDays,
      reason: 'Family trip',
      status: status,
      reviewComment: null,
      reviewedByEmail: null,
      createdAt: DateTime(2026, 11, 1, 10),
      reviewedAt: null,
    );
  }

  @override
  Future<MyLeave> getMyLeave({int? year}) async {
    myLeaveCalls++;
    return MyLeave(
      year: year ?? 2026,
      balances: const [
        LeaveBalance(
          leaveType: 'Annual',
          allowance: 20,
          usedDays: 4,
          pendingDays: 2,
          remainingDays: 14,
        ),
        LeaveBalance(
          leaveType: 'Sick',
          allowance: 10,
          usedDays: 1,
          pendingDays: 0,
          remainingDays: 9,
        ),
      ],
      requests: [
        _leaveRecord(id: 'leave-approved', status: LeaveStatus.approved),
      ],
      pendingCount: 1,
      approvedDays: 4,
    );
  }

  @override
  Future<LeaveRequestRecord> requestLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    leaveRequestCalls++;
    if (requestLeaveError != null) {
      throw ApiException(requestLeaveError!, 400);
    }
    return _leaveRecord(leaveType: leaveType);
  }

  @override
  Future<void> cancelLeaveRequest(String requestId) async {}

  @override
  Future<AdminLeaveList> getLeaveRequests({
    LeaveStatus? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    final requests = [
      _leaveRecord(id: 'leave-pending'),
      _leaveRecord(id: 'leave-done', status: LeaveStatus.approved),
    ];
    final filtered = status == null
        ? requests
        : requests.where((request) => request.status == status).toList();
    return AdminLeaveList(
      requests: filtered,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  @override
  Future<void> approveLeaveRequest(String requestId, {String? comment}) async {
    approveCalls++;
  }

  @override
  Future<void> rejectLeaveRequest(String requestId, {String? comment}) async {
    rejectCalls++;
  }

  final List<ApiUser> _fakeUsers = [
    const ApiUser(id: 'a34f2cde-fda4-4451-a66d-b6e281d630fa', email: 'admin@company.com', roles: ['super admin'], status: 'Active'),
    const ApiUser(id: '2237bc48-8948-4d7d-b22d-48e3635707ec', email: 'hrmanager@company.com', roles: ['hr manager'], status: 'Active'),
    const ApiUser(id: 'c8f7e2d1-4b3a-4e9f-8a7c-1d2e3f4a5b6c', email: 'pm@company.com', roles: ['project manager'], status: 'Active'),
    const ApiUser(id: '6ad3da0e-3b91-4657-85d0-258a29f25df3', email: 'user1@company.com', roles: ['employee'], status: 'Active'),
    const ApiUser(id: '37a4d393-814d-495e-9930-772d704660af', email: 'user2@company.com', roles: ['employee'], status: 'Active'),
    const ApiUser(id: '813407fd-da7a-4fdb-8aeb-097744f994ad', email: 'user3@company.com', roles: ['employee'], status: 'Active'),
  ];

  @override
  Future<List<ApiUser>> listUsers() async {
    return List.of(_fakeUsers);
  }

  @override
  Future<ApiUser> createEmployee({
    required String email,
    required String password,
    required String roleName,
    String? fullName,
  }) async {
    final newUser = ApiUser(
      id: 'fake-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      roles: [roleName],
      status: 'Active',
    );
    _fakeUsers.insert(0, newUser);
    return newUser;
  }

  @override
  Future<LeaveSummary> getLeaveSummary({int? year}) async {
    return LeaveSummary(
      year: year ?? 2026,
      pendingCount: 1,
      approvedCount: 1,
      rejectedCount: 0,
      cancelledCount: 0,
      approvedDays: 4,
      byType: const [
        LeaveTypeTotal(leaveType: 'Annual', approvedDays: 3),
        LeaveTypeTotal(leaveType: 'Sick', approvedDays: 1),
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
