import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';

void main() {
  runApp(const WorknestApp());
}

/// Email and token captured from a password-reset link.
class PasswordResetLink {
  const PasswordResetLink({required this.email, required this.token});

  final String email;
  final String token;
}

PasswordResetLink? _resetLinkFromUri(Uri uri) {
  Uri? candidate;
  if (uri.path.endsWith('/reset-password')) {
    candidate = uri;
  } else if (uri.fragment.contains('reset-password')) {
    final fragment = uri.fragment;
    candidate = Uri.tryParse(
      fragment.startsWith('/') ? fragment : '/$fragment',
    );
  }
  if (candidate == null) return null;

  final token = candidate.queryParameters['token']?.trim() ?? '';
  final email = candidate.queryParameters['email']?.trim() ?? '';
  if (token.isEmpty || email.isEmpty) return null;
  return PasswordResetLink(email: email, token: token);
}

class WorknestApp extends StatefulWidget {
  const WorknestApp({super.key, this.api, this.resetLink});

  final HrmApiClient? api;
  final PasswordResetLink? resetLink;

  @override
  State<WorknestApp> createState() => _WorknestAppState();
}

class _WorknestAppState extends State<WorknestApp> {
  late final HrmApiClient _api;
  AuthSession? _session;
  PasswordResetLink? _pendingReset;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? HrmApiClient();
    _pendingReset = widget.resetLink ?? _resetLinkFromUri(Uri.base);
    if (_pendingReset != null && kIsWeb) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse('${Uri.base.origin}/'),
        replace: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF103A48);
    return MaterialApp(
      title: 'PeopleHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F7F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F61D5),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            height: 1.15,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            height: 1.2,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFF60717A),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ).copyWith(
                overlayColor: WidgetStatePropertyAll(Color(0x2293E8D8)),
                animationDuration: const Duration(milliseconds: 180),
              ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style:
              OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ).copyWith(
                overlayColor: const WidgetStatePropertyAll(Color(0x143568D5)),
                animationDuration: const Duration(milliseconds: 180),
              ),
        ),
      ),
      home: _session != null
          ? DashboardPage(
              session: _session!,
              api: _api,
              onLogout: () async {
                await _api.logout();
                if (mounted) setState(() => _session = null);
              },
            )
          : LoginPage(
              api: _api,
              initialReset: _pendingReset,
              onAuthenticated: (session) => setState(() {
                _session = session;
                _pendingReset = null;
              }),
            ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.api,
    required this.onAuthenticated,
    this.initialReset,
  });

  final HrmApiClient api;
  final ValueChanged<AuthSession> onAuthenticated;
  final PasswordResetLink? initialReset;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final reset = widget.initialReset;
    if (reset != null) {
      _emailController.text = reset.email;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showForgotPassword(link: reset);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final session = await widget.api.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) widget.onAuthenticated(session);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage =
              'The API took too long to respond. Please try again in a moment.';
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not reach the HR API. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showForgotPassword({PasswordResetLink? link}) async {
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ForgotPasswordDialog(
        api: widget.api,
        initialEmail: link?.email ?? _emailController.text.trim(),
        initialToken: link?.token ?? '',
        startAtReset: link != null,
      ),
    );
    if (email == null || !mounted) return;
    setState(() {
      _emailController.text = email;
      _passwordController.clear();
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Password updated. Sign in with your new password.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.hub_rounded,
                            color: Color(0xFF59CDB6),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'PeopleHub',
                            style: TextStyle(
                              color: Color(0xFF103A48),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Color(0xFF103A48),
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Sign in to your secure HR workspace.',
                        style: TextStyle(
                          color: Color(0xFF83939A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Work email',
                          hintText: 'you@company.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty ||
                              !email.contains('@') ||
                              !email.contains('.')) {
                            return 'Enter a valid work email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) < 8
                            ? 'Password must be at least 8 characters'
                            : null,
                      ),
                      const SizedBox(height: 11),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _showForgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB05B68),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _signIn,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Your session is kept in memory and cleared on logout.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8A999E),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.api,
    required this.initialEmail,
    required this.initialToken,
    required this.startAtReset,
  });

  final HrmApiClient api;
  final String initialEmail;
  final String initialToken;
  final bool startAtReset;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late bool _resetStep;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _tokenController = TextEditingController(text: widget.initialToken);
    _resetStep = widget.startAtReset && widget.initialToken.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Enter a valid work email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value?.length ?? 0) < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateToken(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Enter the reset code from your email';
    }
    return null;
  }

  /// Accepts either the raw token or the full reset link from the email.
  ({String email, String token}) _resetCredentials() {
    final raw = _tokenController.text.trim();
    if (raw.contains('token=')) {
      final parsed = Uri.tryParse(raw);
      if (parsed != null) {
        final fragment = parsed.fragment;
        final source = fragment.contains('token=')
            ? Uri.tryParse(fragment.startsWith('/') ? fragment : '/$fragment')
            : null;
        final resolved = source ?? parsed;
        final token = resolved.queryParameters['token']?.trim() ?? '';
        if (token.isNotEmpty) {
          return (
            email:
                resolved.queryParameters['email']?.trim() ??
                _emailController.text.trim(),
            token: token,
          );
        }
      }
    }
    return (email: _emailController.text.trim(), token: raw);
  }

  Future<void> _requestReset() async {
    if (!_requestFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.requestPasswordReset(_emailController.text);
      if (mounted) {
        setState(() {
          _resetStep = true;
          _busy = false;
          _passwordController.clear();
          _confirmController.clear();
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _busy = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'The API took too long to respond. Please try again.';
          _busy = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the HR API. Check your connection and try again.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final credentials = _resetCredentials();
    if (credentials.token.isEmpty) {
      setState(() => _error = 'Enter the reset code from your email.');
      return;
    }
    _emailController.text = credentials.email;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.resetPassword(
        email: credentials.email,
        newPassword: _passwordController.text,
        resetToken: credentials.token,
      );
      if (mounted) {
        Navigator.of(context).pop(credentials.email);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _busy = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'The API took too long to respond. Please try again.';
          _busy = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the HR API. Check your connection and try again.';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
      title: Row(
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            color: Color(0xFF59CDB6),
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _resetStep ? 'Set a new password' : 'Reset your password',
              style: const TextStyle(
                color: Color(0xFF103A48),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: _resetStep ? _buildResetStep() : _buildRequestStep(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  if (_resetStep) {
                    setState(() {
                      _resetStep = false;
                      _error = null;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
          child: Text(_resetStep ? 'Back' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : (_resetStep ? _resetPassword : _requestReset),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_resetStep ? 'Set new password' : 'Send reset link'),
        ),
      ],
    );
  }

  Widget _buildRequestStep() {
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the work email linked to your PeopleHub account.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF60717A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const Key('forgot-email'),
            controller: _emailController,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Work email',
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: _validateEmail,
          ),
          if (_error != null) _DialogError(message: _error!),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6F1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 17,
                  color: Color(0xFF2A7C68),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Open the reset link we sent to your email, or paste the code below. It expires in one hour.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF37685C),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Account: ${_emailController.text.trim()}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF60717A)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('reset-token'),
            controller: _tokenController,
            enabled: !_busy,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reset code or link',
              hintText: 'Paste the code from your email',
              prefixIcon: Icon(Icons.key_rounded),
            ),
            validator: _validateToken,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('reset-password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_busy,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New password',
              helperText: 'At least 8 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('reset-confirm'),
            controller: _confirmController,
            obscureText: _obscureConfirmation,
            enabled: !_busy,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: _validateConfirmation,
          ),
          const SizedBox(height: 12),
          const Text(
            'This replaces your current password and signs out your other sessions.',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF8A999E),
              height: 1.4,
            ),
          ),
          if (_error != null) _DialogError(message: _error!),
        ],
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: const TextStyle(fontSize: 11, color: Color(0xFFB05B68)),
      ),
    );
  }
}

enum _Role {
  superAdmin('Super Admin / Owner'),
  hrManager('HR Manager'),
  payrollOfficer('Payroll Officer / Accountant'),
  departmentManager('Department Manager'),
  employee('Employee');

  const _Role(this.label);
  final String label;
}

enum _Permission {
  viewDashboard,
  manageCompany,
  manageEmployees,
  manageAttendance,
  manageLeave,
  managePayroll,
  manageReports,
  manageTeam,
  selfService,
}

enum _NavPage {
  overview,
  employees,
  calendar,
  leaveRequests,
  myLeave,
  team,
  reports,
  roles,
  payroll,
}

class _RolePolicy {
  static const Map<_Role, Set<_Permission>> permissions = {
    _Role.superAdmin: {
      _Permission.viewDashboard,
      _Permission.manageCompany,
      _Permission.manageEmployees,
      _Permission.manageAttendance,
      _Permission.manageLeave,
      _Permission.managePayroll,
      _Permission.manageReports,
      _Permission.manageTeam,
      _Permission.selfService,
    },
    _Role.hrManager: {
      _Permission.viewDashboard,
      _Permission.manageEmployees,
      _Permission.manageAttendance,
      _Permission.manageLeave,
      _Permission.manageReports,
      _Permission.manageTeam,
      _Permission.selfService,
    },
    _Role.payrollOfficer: {
      _Permission.viewDashboard,
      _Permission.managePayroll,
      _Permission.manageReports,
      _Permission.selfService,
    },
    _Role.departmentManager: {
      _Permission.viewDashboard,
      _Permission.manageAttendance,
      _Permission.manageLeave,
      _Permission.manageTeam,
      _Permission.manageReports,
      _Permission.selfService,
    },
    _Role.employee: {_Permission.viewDashboard, _Permission.selfService},
  };

  static bool can(_Role role, _Permission permission) =>
      permissions[role]?.contains(permission) ?? false;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final HrmApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late _Role _role;
  bool _isClockedIn = false;
  bool _breakStarted = false;
  Duration _worked = Duration.zero;
  Timer? _timer;

  TodayAttendance? _today;
  bool _attendanceLoading = true;
  bool _attendanceBusy = false;
  String? _attendanceError;

  final _allNavigation = const [
    _NavItem(
      Icons.grid_view_rounded,
      'Overview',
      _Permission.viewDashboard,
      _NavPage.overview,
    ),
    _NavItem(
      Icons.badge_outlined,
      'Employee management',
      _Permission.manageEmployees,
      _NavPage.employees,
    ),
    _NavItem(
      Icons.event_available_outlined,
      'Attendance',
      _Permission.manageAttendance,
      _NavPage.calendar,
    ),
    _NavItem(
      Icons.receipt_long_outlined,
      'Leave requests',
      _Permission.manageLeave,
      _NavPage.leaveRequests,
    ),
    _NavItem(
      Icons.event_note_outlined,
      'My leave',
      _Permission.selfService,
      _NavPage.myLeave,
    ),
    _NavItem(
      Icons.people_alt_outlined,
      'Team',
      _Permission.manageTeam,
      _NavPage.team,
    ),
    _NavItem(
      Icons.bar_chart_outlined,
      'Reports',
      _Permission.manageReports,
      _NavPage.reports,
    ),
    _NavItem(
      Icons.admin_panel_settings_outlined,
      'Role management',
      _Permission.manageCompany,
      _NavPage.roles,
    ),
    _NavItem(
      Icons.payments_outlined,
      'Payroll',
      _Permission.managePayroll,
      _NavPage.payroll,
    ),
  ];

  List<_NavItem> get _navigation => _allNavigation
      .where(
        (item) =>
            _RolePolicy.can(_role, item.permission) &&
            (item.page != _NavPage.myLeave || _role == _Role.employee),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _role = _roleFromApi(widget.session.roles);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn && !_breakStarted && mounted) {
        setState(() => _worked += const Duration(seconds: 1));
      }
    });
    _loadTodayAttendance();
  }

  bool get _isManager {
    final roles = widget.session.roles.map((role) => role.toLowerCase());
    return roles.contains('super admin') || roles.contains('hr manager');
  }

  static _Role _roleFromApi(List<String> roles) {
    final normalized = roles.map((role) => role.toLowerCase()).toList();
    if (normalized.contains('super admin')) return _Role.superAdmin;
    if (normalized.contains('hr manager')) return _Role.hrManager;
    if (normalized.contains('payroll officer')) return _Role.payrollOfficer;
    if (normalized.contains('department manager')) {
      return _Role.departmentManager;
    }
    return _Role.employee;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Duration _workedFor(AttendanceRecord? record) {
    final start = record?.checkInAt;
    if (start == null) return Duration.zero;
    final end = record?.checkOutAt ?? DateTime.now();
    final diff = end.difference(start);
    return diff.isNegative ? Duration.zero : diff;
  }

  String _formatClock(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _attendanceStatusDetail() {
    if (_attendanceLoading) return 'Loading attendance…';
    if (_attendanceError != null) return 'Attendance unavailable';
    final record = _today?.record;
    if (record?.checkInAt == null) return 'You have not checked in today';
    if (record!.checkOutAt != null) {
      return 'Checked out at ${_formatClock(record.checkOutAt)}';
    }
    return 'Clocked in at ${_formatClock(record.checkInAt)}';
  }

  Future<void> _loadTodayAttendance() async {
    if (mounted) {
      setState(() {
        _attendanceLoading = true;
        _attendanceError = null;
      });
    }
    try {
      final today = await widget.api.getTodayAttendance();
      if (!mounted) return;
      final record = today.record;
      setState(() {
        _today = today;
        _attendanceLoading = false;
        _isClockedIn =
            record != null &&
            record.checkInAt != null &&
            record.checkOutAt == null;
        _worked = _workedFor(record);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _attendanceLoading = false;
        _attendanceError = error.message;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _attendanceLoading = false;
        _attendanceError = 'The API took too long to respond.';
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _attendanceLoading = false;
        _attendanceError = 'Could not load attendance. Check your connection.';
      });
    }
  }

  Future<void> _toggleClock() async {
    if (_attendanceBusy || _attendanceLoading) return;
    final record = _today?.record;
    if (record?.checkOutAt != null) {
      _showMessage('You already checked out today.');
      return;
    }
    setState(() => _attendanceBusy = true);
    try {
      if (record?.checkInAt != null) {
        final result = await widget.api.checkOut();
        if (!mounted) return;
        _showMessage(result.message);
      } else {
        final result = await widget.api.checkIn();
        if (!mounted) return;
        _showMessage(result.message);
      }
      await _loadTodayAttendance();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } on TimeoutException {
      if (mounted) _showMessage('The API took too long to respond. Try again.');
    } on Exception {
      if (mounted) _showMessage('Could not update attendance. Try again.');
    } finally {
      if (mounted) setState(() => _attendanceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          drawer: compact
              ? Drawer(
                  child: _Sidebar(
                    items: _navigation,
                    selectedIndex: _selectedIndex,
                    role: _role,
                    onLogout: widget.onLogout,
                    onSelected: (index) {
                      setState(() => _selectedIndex = index);
                      Navigator.of(context).pop();
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                _Sidebar(
                  items: _navigation,
                  selectedIndex: _selectedIndex,
                  role: _role,
                  onLogout: widget.onLogout,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      if (compact)
                        _MobileHeader(
                          title: _navigation[_selectedIndex].label,
                          role: _role,
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 20 : 32,
                            compact ? 12 : 24,
                            compact ? 20 : 32,
                            28,
                          ),
                          child:
                              _navigation[_selectedIndex].page ==
                                  _NavPage.overview
                              ? _DashboardContent(
                                  compact: compact,
                                  worked: _formatDuration(_worked),
                                  workedDetail:
                                      '${_formatDuration(_worked)} worked',
                                  workedProgress: (_worked.inMinutes / 480)
                                      .clamp(0.0, 1.0),
                                  statusDetail: _attendanceStatusDetail(),
                                  isClockedIn: _isClockedIn,
                                  breakStarted: _breakStarted,
                                  busy: _attendanceBusy,
                                  today: _today,
                                  attendanceLoading: _attendanceLoading,
                                  attendanceError: _attendanceError,
                                  isManager: _isManager,
                                  onClockToggle: _toggleClock,
                                  onBreakToggle: () {
                                    setState(
                                      () => _breakStarted = !_breakStarted,
                                    );
                                    _showMessage(
                                      _breakStarted
                                          ? 'Break started.'
                                          : 'Welcome back.',
                                    );
                                  },
                                  onRefreshAttendance: _loadTodayAttendance,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.employees
                              ? _EmployeeManagementContent(
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.calendar
                              ? _AttendanceContent(
                                  api: widget.api,
                                  session: widget.session,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.leaveRequests
                              ? _TimeOffContent(onAction: _showMessage)
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.myLeave
                              ? _MyLeaveContent(onAction: _showMessage)
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.team
                              ? _TeamContent(
                                  api: widget.api,
                                  isManager: _isManager,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.reports
                              ? _ReportsContent(onAction: _showMessage)
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.roles
                              ? _RoleManagementContent(
                                  api: widget.api,
                                  onAction: _showMessage,
                                )
                              : _ModulePlaceholder(
                                  title: _navigation[_selectedIndex].label,
                                  icon: _navigation[_selectedIndex].icon,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.title, required this.role});

  final String title;
  final _Role role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E9EB))),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF103A48)),
            ),
          ),
          const Icon(Icons.hub_rounded, color: Color(0xFF59CDB6), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF103A48),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            role.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF83939A), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.role,
    required this.onLogout,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final _Role role;
  final VoidCallback onLogout;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      color: const Color(0xFF103A48),
      padding: const EdgeInsets.fromLTRB(18, 24, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14, bottom: 34),
            child: Row(
              children: [
                Icon(Icons.hub_rounded, color: Color(0xFF8EE6D4), size: 25),
                SizedBox(width: 9),
                Flexible(
                  child: Text(
                    'PeopleHub',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < items.length; index++)
            _SidebarItem(
              item: items[index],
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFFDCEAE8),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Color(0xFF103A48),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    role.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.unfold_more_rounded,
                  color: Color(0xFFA8C1C7),
                  size: 17,
                ),
              ],
            ),
          ),
          if (_RolePolicy.can(role, _Permission.manageCompany))
            _SidebarItem(
              item: const _NavItem(
                Icons.settings_outlined,
                'Settings',
                _Permission.manageCompany,
                _NavPage.roles,
              ),
              onTap: () {},
            ),
          _SidebarItem(
            item: const _NavItem(
              Icons.logout_rounded,
              'Sign out',
              _Permission.selfService,
              _NavPage.overview,
            ),
            onTap: onLogout,
          ),
          _SidebarItem(
            item: const _NavItem(
              Icons.help_outline_rounded,
              'Help center',
              _Permission.selfService,
              _NavPage.overview,
            ),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 14, top: 22),
            child: Text(
              'PeopleHub • v2.4',
              style: TextStyle(color: Color(0xFF8AA7AF), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  final _NavItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF1E5968) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF93E8D8)
                      : const Color(0xFFB6C8CD),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFB6C8CD),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.compact,
    required this.worked,
    required this.workedDetail,
    required this.workedProgress,
    required this.statusDetail,
    required this.isClockedIn,
    required this.breakStarted,
    required this.busy,
    required this.today,
    required this.attendanceLoading,
    required this.attendanceError,
    required this.isManager,
    required this.onClockToggle,
    required this.onBreakToggle,
    required this.onRefreshAttendance,
    required this.onAction,
  });

  final bool compact;
  final String worked;
  final String workedDetail;
  final double workedProgress;
  final String statusDetail;
  final bool isClockedIn;
  final bool breakStarted;
  final bool busy;
  final TodayAttendance? today;
  final bool attendanceLoading;
  final String? attendanceError;
  final bool isManager;
  final VoidCallback onClockToggle;
  final VoidCallback onBreakToggle;
  final Future<void> Function() onRefreshAttendance;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good afternoon, Alex',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Tuesday, November 18, 2026',
                    style: TextStyle(color: Color(0xFF83939A), fontSize: 12),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFFDCEAE8),
              child: Text(
                'A',
                style: TextStyle(
                  color: Color(0xFF103A48),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _MetricGrid(
          children: [
            _MetricCard(
              label: 'Attendance',
              value: '18 / 20',
              note: 'days this month',
              progress: 0.9,
              color: Color(0xFFDDF6EB),
            ),
            _MetricCard(
              label: 'On-time rate',
              value: '96%',
              note: 'Above your 90% goal',
              progress: 0.96,
              color: Colors.white,
            ),
            _MetricCard(
              label: 'Leave balance',
              value: '12 days',
              note: 'Annual leave available',
              progress: 0.62,
              color: Colors.white,
            ),
            _MetricCard(
              label: 'Weekly hours',
              value: '32h 24m',
              note: 'of 40 hours scheduled',
              progress: 0.81,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 18),
        compact
            ? Column(
                children: [
                  _WorkingTimeCard(
                    worked: worked,
                    workedDetail: workedDetail,
                    progress: workedProgress,
                    statusDetail: statusDetail,
                    isClockedIn: isClockedIn,
                    breakStarted: breakStarted,
                    busy: busy,
                    onClockToggle: onClockToggle,
                    onBreakToggle: onBreakToggle,
                  ),
                  const SizedBox(height: 18),
                  _AttendanceCard(
                    today: today,
                    loading: attendanceLoading,
                    busy: busy,
                    error: attendanceError,
                    onRefresh: onRefreshAttendance,
                    onClockToggle: onClockToggle,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _WorkingTimeCard(
                      worked: worked,
                      workedDetail: workedDetail,
                      progress: workedProgress,
                      statusDetail: statusDetail,
                      isClockedIn: isClockedIn,
                      breakStarted: breakStarted,
                      busy: busy,
                      onClockToggle: onClockToggle,
                      onBreakToggle: onBreakToggle,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: _AttendanceCard(
                      today: today,
                      loading: attendanceLoading,
                      busy: busy,
                      error: attendanceError,
                      onRefresh: onRefreshAttendance,
                      onClockToggle: onClockToggle,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 18),
        compact
            ? Column(
                children: [
                  _QuickActions(onAction: onAction),
                  const SizedBox(height: 18),
                  _RecentActivity(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _QuickActions(onAction: onAction)),
                  const SizedBox(width: 18),
                  const Expanded(flex: 3, child: _RecentActivity()),
                ],
              ),
        const SizedBox(height: 20),
        const Text(
          'All times shown in your local timezone (GMT+6).',
          style: TextStyle(fontSize: 11, color: Color(0xFF9AA8AD)),
        ),
      ],
    );
  }
}

class _TeamContent extends StatefulWidget {
  const _TeamContent({
    required this.api,
    required this.isManager,
    required this.onAction,
  });

  final HrmApiClient api;
  final bool isManager;
  final ValueChanged<String> onAction;

  @override
  State<_TeamContent> createState() => _TeamContentState();
}

class _TeamContentState extends State<_TeamContent> {
  bool _loading = true;
  String? _error;
  AdminDailyReport? _daily;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.isManager) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.api.getAdminDailyReport(DateTime.now());
      if (!mounted) return;
      setState(() {
        _daily = report;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'The API took too long to respond.';
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load team attendance.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = _daily;
    final total = daily?.totalUsers ?? 0;
    final present = daily?.presentCount ?? 0;
    final late = daily?.lateCount ?? 0;
    final onLeave = daily?.onLeaveCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your team, at a glance',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'A quick view of your team attendance and requests.',
                    style: TextStyle(color: Color(0xFF83939A), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh team attendance',
              onPressed: _loading ? null : _load,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Color(0xFF6E8087),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _MetricGrid(
          children: [
            _MetricCard(
              label: 'Present today',
              value: _loading ? '—' : '$present',
              note: total > 0 ? 'out of $total employees' : 'No data',
              progress: total > 0 ? present / total : 0,
              color: const Color(0xFFDDF6EB),
            ),
            _MetricCard(
              label: 'On leave today',
              value: _loading ? '—' : '$onLeave',
              note: total > 0 ? 'of your team' : 'No data',
              progress: total > 0 ? onLeave / total : 0,
              color: Colors.white,
            ),
            _MetricCard(
              label: 'Late arrivals',
              value: _loading ? '—' : '$late',
              note: late > 0 ? 'Needs attention' : 'All on time',
              progress: total > 0 ? late / total : 0,
              color: Colors.white,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _Panel(
            title: 'Could not load team attendance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB05B68),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _load,
                  child: const Text('Retry', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final attendance = _Panel(
              title: "Today's team attendance",
              trailing: Text(
                total > 0 ? '$total people' : '',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AA0)),
              ),
              child: !widget.isManager
                  ? const Text(
                      'Team-wide attendance is available to HR managers and admins.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8B9AA0)),
                    )
                  : _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _TeamAttendanceTable(report: daily),
            );
            final requests = _RequestsToReview(onAction: widget.onAction);
            return compact
                ? Column(
                    children: [
                      attendance,
                      const SizedBox(height: 18),
                      requests,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: attendance),
                      const SizedBox(width: 18),
                      Expanded(child: requests),
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _TeamAttendanceTable extends StatelessWidget {
  const _TeamAttendanceTable({required this.report});

  final AdminDailyReport? report;

  @override
  Widget build(BuildContext context) {
    final entries = report?.records ?? const <AdminDailyEntry>[];
    if (entries.isEmpty) {
      return const Text(
        'No team attendance data for today.',
        style: TextStyle(fontSize: 11, color: Color(0xFF8B9AA0)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 50,
        columnSpacing: 24,
        columns: const ['Employee', 'Check-in', 'Status', 'Worked']
            .map(
              (title) => DataColumn(
                label: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A999E),
                  ),
                ),
              ),
            )
            .toList(),
        rows: entries
            .map(
              (entry) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      entry.userEmail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _clockLabel(entry.checkInAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  DataCell(_StatusPill(status: entry.status)),
                  DataCell(
                    Text(
                      _minutesLabel(entry.workingDurationMinutes),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RequestsToReview extends StatelessWidget {
  const _RequestsToReview({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Requests to review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ava Thompson',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF41555D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Product designer',
            style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Annual leave • Nov 16–17 • 2 days',
            style: TextStyle(fontSize: 10, color: Color(0xFF60717A)),
          ),
          const SizedBox(height: 9),
          const Text(
            'Design chore: 90% • No conflicts',
            style: TextStyle(fontSize: 10, color: Color(0xFF2A9A75)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => onAction('Leave request approved.'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3568D5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAction('Leave request rejected.'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB05B68),
                    side: const BorderSide(color: Color(0xFFE8BBC2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? children.length.clamp(1, 4)
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.note,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF708087)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF103A48),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFDDE7E8),
              color: const Color(0xFF62CDB7),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingTimeCard extends StatelessWidget {
  const _WorkingTimeCard({
    required this.worked,
    required this.workedDetail,
    required this.progress,
    required this.statusDetail,
    required this.isClockedIn,
    required this.breakStarted,
    required this.busy,
    required this.onClockToggle,
    required this.onBreakToggle,
  });

  final String worked;
  final String workedDetail;
  final double progress;
  final String statusDetail;
  final bool isClockedIn;
  final bool breakStarted;
  final bool busy;
  final VoidCallback onClockToggle;
  final VoidCallback onBreakToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF103A48),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Working time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3EEDA),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isClockedIn ? 'Clocked in' : 'Clocked out',
                  style: const TextStyle(
                    color: Color(0xFF0F674C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            worked,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            statusDetail,
            style: const TextStyle(color: Color(0xFFA8C1C7), fontSize: 11),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFF315C68),
              color: const Color(0xFF6DDBC5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                workedDetail,
                style: const TextStyle(color: Color(0xFFA8C1C7), fontSize: 10),
              ),
              const Text(
                '8h daily goal',
                style: TextStyle(color: Color(0xFFA8C1C7), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                icon: breakStarted
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: breakStarted ? 'End break' : 'Take a break',
                onPressed: onBreakToggle,
                outlined: true,
              ),
              _ActionButton(
                icon: isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                label: isClockedIn ? 'Clock out' : 'Clock in',
                onPressed: busy ? null : onClockToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: outlined
            ? const Color(0xFF2A5D6A)
            : const Color(0xFF3568D5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.today,
    required this.loading,
    required this.busy,
    required this.error,
    required this.onRefresh,
    required this.onClockToggle,
  });

  final TodayAttendance? today;
  final bool loading;
  final bool busy;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onClockToggle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: "Today's attendance",
      trailing: IconButton(
        tooltip: 'Refresh attendance',
        onPressed: loading ? null : () => onRefresh(),
        icon: const Icon(
          Icons.refresh_rounded,
          size: 17,
          color: Color(0xFF6E8087),
        ),
        visualDensity: VisualDensity.compact,
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFB05B68)),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => onRefresh(),
            child: const Text('Retry', style: TextStyle(fontSize: 11)),
          ),
        ],
      );
    }

    final record = today?.record;
    if (record == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You have not checked in today.',
            style: TextStyle(fontSize: 11, color: Color(0xFF667980)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onClockToggle,
              icon: const Icon(Icons.login_rounded, size: 15),
              label: const Text(
                'Check in',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3568D5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final checkedOut = record.checkOutAt != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine(label: 'Check-in', value: _clockLabel(record.checkInAt)),
        _InfoLine(label: 'Check-out', value: _clockLabel(record.checkOutAt)),
        _InfoLine(
          label: 'Worked',
          value: _minutesLabel(record.workingDurationMinutes),
        ),
        _InfoLine(
          label: 'Status',
          value: record.status.label,
          valueColor: _attendanceStatusColor(record.status),
        ),
        if (record.lateMinutes > 0)
          _InfoLine(
            label: 'Late',
            value: '${record.lateMinutes} min',
            valueColor: const Color(0xFFB07B22),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: checkedOut
              ? Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Attendance complete for today.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF667980)),
                  ),
                )
              : FilledButton.icon(
                  onPressed: busy ? null : onClockToggle,
                  icon: const Icon(Icons.logout_rounded, size: 15),
                  label: const Text(
                    'Check out',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3568D5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Quick actions',
      child: Column(
        children: [
          _QuickAction(
            icon: Icons.event_available_outlined,
            label: 'Request time off',
            onTap: () => onAction('Time off request started.'),
          ),
          _QuickAction(
            icon: Icons.description_outlined,
            label: 'View payslips',
            onTap: () => onAction('Payslips are opening soon.'),
          ),
          _QuickAction(
            icon: Icons.person_outline_rounded,
            label: 'Team directory',
            onTap: () => onAction('Team directory selected.'),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent activity',
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'View all',
          style: TextStyle(fontSize: 11, color: Color(0xFF3264CF)),
        ),
      ),
      child: const Column(
        children: [
          _Activity(
            icon: Icons.access_time_rounded,
            title: 'You clocked in',
            detail: 'Remote • On time',
            date: '9:00 AM',
          ),
          _Activity(
            icon: Icons.check_circle_outline_rounded,
            title: 'Annual leave approved',
            detail: 'Nov 16–17 • 2 days',
            date: 'Yesterday',
          ),
          _Activity(
            icon: Icons.description_outlined,
            title: 'October payslip is ready',
            detail: 'Available in your documents',
            date: 'Nov 2',
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE1E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF103A48),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF849399)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF41555D),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF3568D5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF41555D)),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: Color(0xFF8B9AA0),
            ),
          ],
        ),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({
    required this.icon,
    required this.title,
    required this.detail,
    required this.date,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF52B89D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF41555D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8B9AA0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AA0)),
          ),
        ],
      ),
    );
  }
}

class _AttendanceContent extends StatefulWidget {
  const _AttendanceContent({
    required this.api,
    required this.session,
    required this.onAction,
  });

  final HrmApiClient api;
  final AuthSession session;
  final ValueChanged<String> onAction;

  @override
  State<_AttendanceContent> createState() => _AttendanceContentState();
}

class _AttendanceContentState extends State<_AttendanceContent> {
  final DateTime _now = DateTime.now();
  late final DateTime _monthStart;
  late final DateTime _monthEnd;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  TodayAttendance? _today;
  AttendanceHistory? _history;
  AdminDailyReport? _daily;
  AdminMonthlySummary? _monthly;

  bool get _isManager {
    final roles = widget.session.roles.map((role) => role.toLowerCase());
    return roles.contains('super admin') || roles.contains('hr manager');
  }

  @override
  void initState() {
    super.initState();
    _monthStart = DateTime(_now.year, _now.month, 1);
    _monthEnd = DateTime(_now.year, _now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await widget.api.getTodayAttendance();
      final history = await widget.api.getMyAttendance(
        from: _monthStart,
        to: _monthEnd,
        pageSize: 100,
      );
      AdminDailyReport? daily;
      AdminMonthlySummary? monthly;
      if (_isManager) {
        daily = await widget.api.getAdminDailyReport(_now);
        monthly = await widget.api.getAdminMonthlySummary(
          year: _now.year,
          month: _now.month,
        );
      }
      if (!mounted) return;
      setState(() {
        _today = today;
        _history = history;
        _daily = daily;
        _monthly = monthly;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'The API took too long to respond. Please try again.';
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the HR API. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.api.checkIn();
      widget.onAction(result.message);
      await _load();
    } on ApiException catch (error) {
      widget.onAction(error.message);
    } on TimeoutException {
      widget.onAction('The API took too long to respond. Try again.');
    } on Exception {
      widget.onAction('Could not check in. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.api.checkOut();
      widget.onAction(result.message);
      await _load();
    } on ApiException catch (error) {
      widget.onAction(error.message);
    } on TimeoutException {
      widget.onAction('The API took too long to respond. Try again.');
    } on Exception {
      widget.onAction('Could not check out. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<_SummaryItem> _managerSummary() {
    final daily = _daily;
    if (daily == null) return const [];
    return [
      _SummaryItem('Present', '${daily.presentCount}', const Color(0xFFDDF6EB)),
      _SummaryItem('Late', '${daily.lateCount}', const Color(0xFFFFF3D6)),
      _SummaryItem('Absent', '${daily.absentCount}', const Color(0xFFFFE5E8)),
      _SummaryItem(
        'On leave',
        '${daily.onLeaveCount}',
        const Color(0xFFE7EFFD),
      ),
    ];
  }

  List<_SummaryItem> _personalSummary() {
    final records = _history?.records ?? const <AttendanceRecord>[];
    int count(AttendanceStatus status) =>
        records.where((record) => record.status == status).length;
    return [
      _SummaryItem(
        'Present',
        '${count(AttendanceStatus.present)}',
        const Color(0xFFDDF6EB),
      ),
      _SummaryItem(
        'Late',
        '${count(AttendanceStatus.late)}',
        const Color(0xFFFFF3D6),
      ),
      _SummaryItem(
        'Absent',
        '${count(AttendanceStatus.absent)}',
        const Color(0xFFFFE5E8),
      ),
      _SummaryItem(
        'On leave',
        '${count(AttendanceStatus.onLeave)}',
        const Color(0xFFE7EFFD),
      ),
    ];
  }

  Widget _buildToday() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final record = _today?.record;
    if (record == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You have not checked in today.',
            style: TextStyle(fontSize: 11, color: Color(0xFF667980)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _checkIn,
            icon: const Icon(Icons.login_rounded, size: 15),
            label: const Text(
              'Check in',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3568D5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    final checkedOut = record.checkOutAt != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoLine(label: 'Check-in', value: _clockLabel(record.checkInAt)),
        _InfoLine(label: 'Check-out', value: _clockLabel(record.checkOutAt)),
        _InfoLine(
          label: 'Worked',
          value: _minutesLabel(record.workingDurationMinutes),
        ),
        _InfoLine(
          label: 'Status',
          value: record.status.label,
          valueColor: _attendanceStatusColor(record.status),
        ),
        if (record.lateMinutes > 0)
          _InfoLine(
            label: 'Late',
            value: '${record.lateMinutes} min',
            valueColor: const Color(0xFFB07B22),
          ),
        const SizedBox(height: 10),
        if (checkedOut)
          const Text(
            'Your attendance is complete for today.',
            style: TextStyle(fontSize: 10, color: Color(0xFF667980)),
          )
        else
          FilledButton.icon(
            onPressed: _busy ? null : _checkOut,
            icon: const Icon(Icons.logout_rounded, size: 15),
            label: const Text(
              'Check out',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3568D5),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTable() {
    final records = _history?.records ?? const <AttendanceRecord>[];
    if (records.isEmpty) {
      return const Text(
        'No attendance records for this month yet.',
        style: TextStyle(fontSize: 11, color: Color(0xFF8B9AA0)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 50,
        columnSpacing: 26,
        columns: const ['Date', 'Check-in', 'Check-out', 'Worked', 'Status']
            .map(
              (title) => DataColumn(
                label: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A999E),
                  ),
                ),
              ),
            )
            .toList(),
        rows: records
            .map(
              (record) => DataRow(
                cells: [
                  DataCell(_cellText(_dateLabel(record.date))),
                  DataCell(_cellText(_clockLabel(record.checkInAt))),
                  DataCell(_cellText(_clockLabel(record.checkOutAt))),
                  DataCell(
                    _cellText(_minutesLabel(record.workingDurationMinutes)),
                  ),
                  DataCell(_StatusPill(status: record.status)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDailyTable() {
    final daily = _daily;
    if (daily == null || daily.records.isEmpty) {
      return const Text(
        'No team attendance data for today.',
        style: TextStyle(fontSize: 11, color: Color(0xFF8B9AA0)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 50,
        columnSpacing: 26,
        columns: const ['Employee', 'Check-in', 'Check-out', 'Worked', 'Status']
            .map(
              (title) => DataColumn(
                label: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A999E),
                  ),
                ),
              ),
            )
            .toList(),
        rows: daily.records
            .map(
              (entry) => DataRow(
                cells: [
                  DataCell(_cellText(entry.userEmail)),
                  DataCell(_cellText(_clockLabel(entry.checkInAt))),
                  DataCell(_cellText(_clockLabel(entry.checkOutAt))),
                  DataCell(
                    _cellText(_minutesLabel(entry.workingDurationMinutes)),
                  ),
                  DataCell(_StatusPill(status: entry.status)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMonthlyTable() {
    final monthly = _monthly;
    if (monthly == null || monthly.summaries.isEmpty) {
      return const Text(
        'No monthly summaries available.',
        style: TextStyle(fontSize: 11, color: Color(0xFF8B9AA0)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 50,
        columnSpacing: 22,
        columns:
            const [
                  'Employee',
                  'Present',
                  'Late',
                  'Absent',
                  'Leave',
                  'Attendance',
                ]
                .map(
                  (title) => DataColumn(
                    label: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A999E),
                      ),
                    ),
                  ),
                )
                .toList(),
        rows: monthly.summaries
            .map(
              (summary) => DataRow(
                cells: [
                  DataCell(_cellText(summary.userEmail)),
                  DataCell(_cellText('${summary.presentDays}')),
                  DataCell(_cellText('${summary.lateDays}')),
                  DataCell(_cellText('${summary.absentDays}')),
                  DataCell(_cellText('${summary.onLeaveDays}')),
                  DataCell(
                    _cellText(
                      '${summary.attendancePercentage.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _cellText(String value) {
    return Text(
      value,
      style: const TextStyle(fontSize: 11, color: Color(0xFF41555D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Attendance',
      subtitle: 'Check in, check out, and review working hours.',
      action: OutlinedButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh'),
      ),
      children: [
        if (_error != null) ...[
          _Panel(
            title: 'Could not load attendance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB05B68),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _load,
                  child: const Text('Retry', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        _Panel(title: "Today's attendance", child: _buildToday()),
        const SizedBox(height: 18),
        if (_isManager) ...[
          if (_daily != null) ...[
            _SummaryRow(items: _managerSummary()),
            const SizedBox(height: 18),
            _Panel(
              title: "Today's team attendance",
              trailing: Text(
                '${_daily!.totalUsers} people',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AA0)),
              ),
              child: _buildDailyTable(),
            ),
            const SizedBox(height: 18),
          ],
        ] else if (_history != null) ...[
          _SummaryRow(items: _personalSummary()),
          const SizedBox(height: 18),
        ],
        if (_history != null)
          _Panel(
            title: 'My attendance — ${_monthLabel(_now.month)} ${_now.year}',
            child: _buildHistoryTable(),
          ),
        if (_isManager && _monthly != null) ...[
          const SizedBox(height: 18),
          _Panel(
            title: 'Monthly summary — ${_monthLabel(_now.month)} ${_now.year}',
            child: _buildMonthlyTable(),
          ),
        ],
      ],
    );
  }
}

String _clockLabel(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _minutesLabel(int minutes) {
  if (minutes <= 0) return '--';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '${remainder}m';
  return '${hours}h ${remainder}m';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _monthLabel(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

Color _attendanceStatusColor(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return const Color(0xFF2A9A75);
    case AttendanceStatus.late:
      return const Color(0xFFB07B22);
    case AttendanceStatus.absent:
      return const Color(0xFFB05B68);
    case AttendanceStatus.onLeave:
      return const Color(0xFF3568D5);
    case AttendanceStatus.incomplete:
      return const Color(0xFFB07B22);
    case AttendanceStatus.holiday:
      return const Color(0xFF8B9AA0);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _attendanceStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TimeOffContent extends StatelessWidget {
  const _TimeOffContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Time off',
      subtitle: 'Review requests and keep leave balances accurate.',
      action: FilledButton.icon(
        onPressed: () => onAction('New leave request opened.'),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('New request'),
      ),
      children: [
        const _SummaryRow(
          items: [
            _SummaryItem('Pending review', '6', Color(0xFFFFF3D6)),
            _SummaryItem('Approved this month', '18', Color(0xFFDDF6EB)),
            _SummaryItem('Days taken', '42', Color(0xFFE7EFFD)),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Leave requests',
          trailing: DropdownButton<String>(
            value: 'All statuses',
            underline: const SizedBox(),
            items: ['All statuses', 'Pending', 'Approved', 'Rejected']
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
            onChanged: (_) {},
          ),
          child: _RequestTable(onAction: onAction),
        ),
      ],
    );
  }
}

class _MyLeaveContent extends StatelessWidget {
  const _MyLeaveContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'My leave',
      subtitle: 'Request time away and track your leave history.',
      action: FilledButton.icon(
        onPressed: () => onAction('New leave request opened.'),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Request leave'),
      ),
      children: [
        const _SummaryRow(
          items: [
            _SummaryItem('Available balance', '12 days', Color(0xFFDDF6EB)),
            _SummaryItem('Pending requests', '1', Color(0xFFFFF3D6)),
            _SummaryItem('Used this year', '6 days', Color(0xFFE7EFFD)),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'My leave history',
          child: const _EmployeeTable(
            rows: [
              [
                'Annual leave',
                'Nov 16–17',
                '2 days',
                'Pending',
                'Awaiting review',
              ],
              [
                'Annual leave',
                'Oct 7–10',
                '4 days',
                'Approved',
                'Approved by HR',
              ],
              ['Sick leave', 'Sep 2', '1 day', 'Approved', 'Approved by HR'],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Reports',
      subtitle: 'Understand workforce trends and operational health.',
      action: FilledButton.icon(
        onPressed: () => onAction('Report export prepared.'),
        icon: const Icon(Icons.download_outlined, size: 16),
        label: const Text('Export report'),
      ),
      children: [
        const _SummaryRow(
          items: [
            _SummaryItem('Headcount', '124', Color(0xFFE7EFFD)),
            _SummaryItem('Attendance rate', '90%', Color(0xFFDDF6EB)),
            _SummaryItem('Avg. hours', '7h 42m', Color(0xFFFFF3D6)),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final panels = [
              _Panel(title: 'Attendance trend', child: _BarChart()),
              _Panel(
                title: 'Department headcount',
                child: const _DepartmentList(),
              ),
            ];
            if (constraints.maxWidth < 760) {
              return Column(
                children: [panels[0], const SizedBox(height: 18), panels[1]],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panels[0]),
                const SizedBox(width: 18),
                Expanded(child: panels[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmployeeManagementContent extends StatelessWidget {
  const _EmployeeManagementContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Employee management',
      subtitle: 'Manage employee records, departments, and employment status.',
      action: FilledButton.icon(
        onPressed: () => onAction('New employee form opened.'),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add employee'),
      ),
      children: [
        _Panel(
          title: 'Employees',
          trailing: SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search employees',
                prefixIcon: Icon(Icons.search, size: 17),
                isDense: true,
              ),
              onChanged: (_) {},
            ),
          ),
          child: const _EmployeeTable(
            rows: [
              [
                'Maya Chen',
                'Engineering',
                'Product engineer',
                'Active',
                'Full time',
              ],
              ['Noah Williams', 'Design', 'UX designer', 'Active', 'Full time'],
              [
                'Ava Thompson',
                'Product',
                'Product designer',
                'Active',
                'Full time',
              ],
              [
                'Liam Patel',
                'Sales',
                'Account executive',
                'Inactive',
                'Contract',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleManagementContent extends StatefulWidget {
  const _RoleManagementContent({required this.api, required this.onAction});

  final HrmApiClient api;
  final ValueChanged<String> onAction;

  @override
  State<_RoleManagementContent> createState() => _RoleManagementContentState();
}

class _RoleManagementContentState extends State<_RoleManagementContent> {
  List<ApiRole> _roles = const [];
  List<ApiUser> _users = const [];
  String? _error;
  String? _updatingUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        widget.api.listRoles(),
        widget.api.listUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _roles = result[0] as List<ApiRole>;
        _users = result[1] as List<ApiUser>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeRole(ApiUser user, ApiRole nextRole) async {
    if (_updatingUserId != null) return;
    setState(() => _updatingUserId = user.id);
    try {
      final currentRoles = user.roles
          .map(
            (name) => _roles
                .where((role) => role.name.toLowerCase() == name.toLowerCase())
                .firstOrNull,
          )
          .whereType<ApiRole>()
          .toList();

      for (final currentRole in currentRoles) {
        if (currentRole.id != nextRole.id &&
            currentRole.name.toLowerCase() != 'user') {
          await widget.api.removeRole(user.id, currentRole.id);
        }
      }

      final alreadyHasNextRole = currentRoles.any(
        (role) => role.id == nextRole.id,
      );
      if (!alreadyHasNextRole) {
        await widget.api.assignRole(user.id, nextRole.id);
      }

      widget.onAction('${user.email} is now assigned ${nextRole.name}.');
      await _load();
    } on ApiException catch (error) {
      if (mounted) widget.onAction(error.message);
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Role management',
      subtitle:
          'Assign access according to each person’s job responsibilities.',
      action: FilledButton.icon(
        onPressed: () => widget.onAction(
          'Account invitations are managed by the API registration flow.',
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
        label: const Text('Invite employee'),
      ),
      children: [
        _Panel(
          title: 'People and access',
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : _users.isEmpty
              ? const Text('No accounts were returned by the API.')
              : Column(
                  children: [
                    for (final user in _users)
                      _ApiRoleAssignmentRow(
                        user: user,
                        roles: _roles,
                        updating: _updatingUserId == user.id,
                        onChanged: (role) => _changeRole(user, role),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ApiRoleAssignmentRow extends StatelessWidget {
  const _ApiRoleAssignmentRow({
    required this.user,
    required this.roles,
    required this.updating,
    required this.onChanged,
  });

  final ApiUser user;
  final List<ApiRole> roles;
  final bool updating;
  final ValueChanged<ApiRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final current =
        user.roles
            .where((name) => name.toLowerCase() != 'user')
            .firstOrNull
            ?.toLowerCase() ??
        (user.roles.isEmpty ? null : 'user');
    final selected = roles
        .where((role) => role.name.toLowerCase() == current)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFDCEAE8),
            child: Icon(
              Icons.person_outline,
              size: 18,
              color: Color(0xFF103A48),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A999E),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<ApiRole>(
            value: selected,
            hint: const Text('Select role', style: TextStyle(fontSize: 11)),
            underline: const SizedBox(),
            items: roles
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.name,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
            onChanged: updating
                ? null
                : (role) {
                    if (role != null) onChanged(role);
                  },
          ),
          if (updating)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF83939A),
                    fontSize: 12,
                  ),
                ),
              ],
            );
            if (action == null || constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  if (action != null) ...[const SizedBox(height: 16), action!],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                action!,
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        ...children,
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.items});
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? items.length
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        const gap = 14.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFE1E9EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF708087),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF103A48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  const _EmployeeTable({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columnSpacing: 28,
        columns: const [
          DataColumn(
            label: Text(
              'Employee',
              style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
            ),
          ),
          DataColumn(
            label: Text(
              'Department',
              style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
            ),
          ),
          DataColumn(
            label: Text(
              'Check-in',
              style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
            ),
          ),
          DataColumn(
            label: Text(
              'Note',
              style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
            ),
          ),
        ],
        rows: rows
            .map(
              (row) => DataRow(
                cells: row
                    .map(
                      (value) => DataCell(
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF41555D),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RequestTable extends StatelessWidget {
  const _RequestTable({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final requests = [
      ['Ava Thompson', 'Annual leave', 'Nov 16–17', 'Pending'],
      ['Maya Chen', 'Sick leave', 'Nov 12', 'Approved'],
      ['Noah Williams', 'Personal leave', 'Nov 24–25', 'Pending'],
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        columnSpacing: 34,
        columns: const ['Employee', 'Type', 'Dates', 'Status', 'Action']
            .map(
              (title) => DataColumn(
                label: Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
                ),
              ),
            )
            .toList(),
        rows: requests
            .map(
              (request) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      request[0],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      request[1],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      request[2],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      request[3],
                      style: TextStyle(
                        fontSize: 11,
                        color: request[3] == 'Pending'
                            ? const Color(0xFFB07B22)
                            : const Color(0xFF2A9A75),
                      ),
                    ),
                  ),
                  DataCell(
                    request[3] == 'Pending'
                        ? TextButton(
                            onPressed: () => onAction('Request reviewed.'),
                            child: const Text(
                              'Review',
                              style: TextStyle(fontSize: 11),
                            ),
                          )
                        : const Text('—'),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const values = [0.58, 0.72, 0.64, 0.82, 0.74, 0.92, 0.88];
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: values
            .asMap()
            .entries
            .map(
              (entry) => Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24,
                    height: 130 * entry.value,
                    decoration: BoxDecoration(
                      color: entry.key == 5
                          ? const Color(0xFF3568D5)
                          : const Color(0xFF9CDACB),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'W${entry.key + 1}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8A999E),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DepartmentList extends StatelessWidget {
  const _DepartmentList();

  @override
  Widget build(BuildContext context) {
    const departments = [
      ('Engineering', '42', 0.86),
      ('Product & design', '28', 0.58),
      ('Sales', '31', 0.68),
      ('Operations', '23', 0.48),
    ];
    return Column(
      children: departments.map((department) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      department.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF41555D),
                      ),
                    ),
                  ),
                  Text(
                    department.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF103A48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: department.$3,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE4ECEE),
                  color: const Color(0xFF67C8B3),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  const _ModulePlaceholder({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          children: [
            Icon(icon, size: 44, color: const Color(0xFF7E9BA2)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'This module is ready for its next workflow.',
              style: TextStyle(color: Color(0xFF7E8D93)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.permission, this.page);
  final IconData icon;
  final String label;
  final _Permission permission;
  final _NavPage page;
}
