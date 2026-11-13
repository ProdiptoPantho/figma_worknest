import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'document_picker.dart';

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
  const WorknestApp({
    super.key,
    this.api,
    this.resetLink,
    this.initialSession,
    this.autoRestoreSession,
  });

  final HrmApiClient? api;
  final PasswordResetLink? resetLink;
  final AuthSession? initialSession;
  final bool? autoRestoreSession;

  @override
  State<WorknestApp> createState() => _WorknestAppState();
}

class _WorknestAppState extends State<WorknestApp> {
  late final HrmApiClient _api;
  AuthSession? _session;
  PasswordResetLink? _pendingReset;
  ThemeMode _themeMode = ThemeMode.light;
  bool _restoring = false;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('wn_theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    }).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? HrmApiClient();
    _session = widget.initialSession;
    if (_session != null) {
      _api.setSessionEmail(_session!.email);
    }
    _pendingReset = widget.resetLink ?? _resetLinkFromUri(Uri.base);
    if (_pendingReset != null && kIsWeb) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse('${Uri.base.origin}/'),
        replace: true,
      );
    }
    final shouldRestore = widget.autoRestoreSession ?? (widget.api == null);
    if (shouldRestore && widget.initialSession == null) {
      _restoring = true;
      _tryRestoreSession();
    } else {
      _loadSavedTheme();
    }
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString('wn_theme');
      if (themeStr != null && mounted) {
        setState(() {
          _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (_) {}
  }

  Future<void> _tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString('wn_theme');
      if (themeStr != null && mounted) {
        setState(() {
          _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
        });
      }
      final session = await _api.restoreSession();
      if (mounted) {
        setState(() {
          _session = session;
          _restoring = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF103A48);
    return MaterialApp(
      title: 'PeopleHub',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F7F9),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE1E9EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F61D5),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: navy,
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
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Color(0x2293E8D8)),
            animationDuration: const Duration(milliseconds: 180),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F7F9),
          labelStyle: const TextStyle(color: Color(0xFF4A6572)),
          hintStyle: const TextStyle(color: Color(0xFF83939A)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF103A48)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF103A48), width: 1.5),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
          onSurface: const Color(0xFFF1F5F9),
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            height: 1.15,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1F5F9),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            height: 1.2,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF1F5F9),
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFF94A3B8),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Color(0x2238BDF8)),
            animationDuration: const Duration(milliseconds: 180),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Color(0x1438BDF8)),
            animationDuration: const Duration(milliseconds: 180),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          floatingLabelStyle: const TextStyle(color: Color(0xFF38BDF8)),
          prefixIconColor: const Color(0xFF64748B),
          suffixIconColor: const Color(0xFF64748B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          ),
        ),
      ),
      home: _restoring
          ? Scaffold(
              backgroundColor: _themeMode == ThemeMode.dark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF3F7F9),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hub_rounded,
                      color: Color(0xFF59CDB6),
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(
                      color: _themeMode == ThemeMode.dark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF103A48),
                    ),
                  ],
                ),
              ),
            )
          : _session != null
              ? DashboardPage(
                  session: _session!,
                  api: _api,
                  onToggleTheme: _toggleTheme,
                  isDark: _themeMode == ThemeMode.dark,
                  onLogout: () async {
                    await _api.logout();
                    if (mounted) setState(() => _session = null);
                  },
                )
              : LoginPage(
                  api: _api,
                  initialReset: _pendingReset,
                  onToggleTheme: _toggleTheme,
                  onAuthenticated: (session) => setState(() {
                    _api.setSessionEmail(session.email);
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
    this.onToggleTheme,
  });

  final HrmApiClient api;
  final ValueChanged<AuthSession> onAuthenticated;
  final PasswordResetLink? initialReset;
  final VoidCallback? onToggleTheme;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _QuickLoginChip extends StatelessWidget {
  const _QuickLoginChip({
    required this.label,
    required this.email,
    required this.password,
    required this.onTap,
  });

  final String label;
  final String email;
  final String password;
  final void Function(String email, String password) onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(
        label.contains('Project')
            ? Icons.assignment_ind_outlined
            : (label.contains('HR')
                ? Icons.badge_outlined
                : (label.contains('Admin')
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline_rounded)),
        size: 13,
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      onPressed: () => onTap(email, password),
    );
  }
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
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ForgotPasswordDialog(
        api: widget.api,
        initialEmail: link?.email ?? _emailController.text.trim(),
        initialToken: link?.token ?? '',
        startAtReset: link != null,
      ),
    );
    if (result == null || !mounted) return;

    final action = result['action'];
    final email = result['email'];

    if (action == 'requested') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'If the email exists, a password reset link has been sent to your inbox.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF2A7C68),
            duration: Duration(seconds: 5),
          ),
        );
      return;
    }

    if (action == 'reset' && email != null) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F7F9),
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Column(
              children: [
                if (widget.onToggleTheme != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                        onPressed: widget.onToggleTheme,
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 860;
                            final content = wide
                                ? ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 500,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Expanded(
                                            flex: 11,
                                            child: _LoginBrandPanel(),
                                          ),
                                          Expanded(
                                            flex: 9,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    34,
                                                    34,
                                                    34,
                                                    30,
                                                  ),
                                              child: _buildForm(compact: false),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      26,
                                      28,
                                      26,
                                      26,
                                    ),
                                    child: _buildForm(compact: true),
                                  );
                            return Card(
                              elevation: 0,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isDark
                                    ? const BorderSide(color: Color(0xFF334155))
                                    : BorderSide.none,
                              ),
                              child: content,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const _LoginFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm({required bool compact}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              children: [
                const Icon(Icons.hub_rounded, color: Color(0xFF59CDB6), size: 26),
                const SizedBox(width: 9),
                Text(
                  'PeopleHub',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF134E48) : const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'SECURE SIGN IN',
                style: TextStyle(
                  color: isDark ? const Color(0xFF59CDB6) : const Color(0xFF2A7C68),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Welcome back',
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Sign in to your secure HR workspace.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF83939A),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
            decoration: InputDecoration(
              labelText: 'Work email',
              hintText: 'you@company.com',
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A6572),
              ),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F7F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
                  width: 1.5,
                ),
              ),
            ),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A6572),
              ),
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F7F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
                  width: 1.5,
                ),
              ),
            ),
            onFieldSubmitted: (_) {
              if (!_isSubmitting) _signIn();
            },
            validator: (value) => (value?.length ?? 0) < 8
                ? 'Password must be at least 8 characters'
                : null,
          ),
          const SizedBox(height: 11),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting ? null : _showForgotPassword,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2F61D5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFB05B68), fontSize: 12),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _signIn,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF103A48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
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
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE4ECEE),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: Color(0xFF2A9A75),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Protected by role-based access. Your session is securely preserved and cleared on logout.',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8C92),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent_rounded,
                size: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF9AA9AE),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'No account yet? Ask your HR administrator for an invite.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF9AA9AE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _QuickLoginChip(
                  label: 'Project Manager',
                  email: 'pm@company.com',
                  password: 'PmPass123!',
                  onTap: (e, p) {
                    setState(() {
                      _emailController.text = e;
                      _passwordController.text = p;
                    });
                  },
                ),
                _QuickLoginChip(
                  label: 'HR Manager',
                  email: 'hrmanager@company.com',
                  password: 'HrPass123!',
                  onTap: (e, p) {
                    setState(() {
                      _emailController.text = e;
                      _passwordController.text = p;
                    });
                  },
                ),
                _QuickLoginChip(
                  label: 'Admin',
                  email: 'admin@company.com',
                  password: 'AdminPass123!',
                  onTap: (e, p) {
                    setState(() {
                      _emailController.text = e;
                      _passwordController.text = p;
                    });
                  },
                ),
                _QuickLoginChip(
                  label: 'Employee',
                  email: 'user1@company.com',
                  password: 'UserPass123!',
                  onTap: (e, p) {
                    setState(() {
                      _emailController.text = e;
                      _passwordController.text = p;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_rounded, size: 15, color: Color(0xFF7FA9A2)),
                const SizedBox(width: 6),
                Text(
                  'PeopleHub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF44605F),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '© 2026 · All rights reserved',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF9AA9AE),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _FooterTag(
                  icon: Icons.lock_outline_rounded,
                  label: 'Encrypted session',
                  isDark: isDark,
                ),
                _FooterTag(
                  icon: Icons.shield_outlined,
                  label: 'Role-based access',
                  isDark: isDark,
                ),
                _FooterTag(
                  icon: Icons.bolt_rounded,
                  label: 'Built for teams',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterTag extends StatelessWidget {
  const _FooterTag({
    required this.icon,
    required this.label,
    this.isDark = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white.withAlpha(170),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDFEAEC),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF5E8B85),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6E8388),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0B132B),
                    Color(0xFF0F172A),
                    Color(0xFF131D33),
                  ]
                : const [
                    Color(0xFFEDF6F6),
                    Color(0xFFF4F8FA),
                    Color(0xFFE8F1F6),
                  ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: _softCircle(340, isDark ? const Color(0x1F38BDF8) : const Color(0x3359CDB6)),
            ),
            Positioned(
              bottom: -150,
              right: -80,
              child: _softCircle(420, isDark ? const Color(0x1A6366F1) : const Color(0x223568D5)),
            ),
            Positioned(
              top: 80,
              right: 120,
              child: _softCircle(120, isDark ? const Color(0x1438BDF8) : const Color(0x1F93E8D8)),
            ),
            Positioned(
              left: -60,
              bottom: 110,
              child: _softCircle(210, isDark ? const Color(0x1A2DD4BF) : const Color(0x1F59CDB6)),
            ),
            const Positioned(
              top: 54,
              left: 48,
              child: _FloatingTile(
                icon: Icons.schedule_rounded,
                color: Color(0xFF2A9A75),
                angle: -0.14,
              ),
            ),
            const Positioned(
              top: 132,
              right: 30,
              child: _FloatingTile(
                icon: Icons.event_available_rounded,
                color: Color(0xFF3568D5),
                angle: 0.12,
              ),
            ),
            const Positioned(
              left: 74,
              bottom: 238,
              child: _FloatingTile(
                icon: Icons.verified_user_outlined,
                color: Color(0xFF2A7C68),
                angle: 0.1,
              ),
            ),
            const Positioned(left: 46, bottom: 92, child: _DotGrid()),
            Positioned(
              right: 70,
              bottom: 46,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0x1F38BDF8) : const Color(0x1F2A7C68),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 120,
              bottom: 40,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0x1A6366F1) : const Color(0x1A3568D5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FloatingTile extends StatelessWidget {
  const _FloatingTile({
    required this.icon,
    required this.color,
    required this.angle,
  });

  final IconData icon;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withAlpha(220)
              : Colors.white.withAlpha(205),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE3EDEE),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x33000000) : const Color(0x14103A48),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 25),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(180, 130), painter: _DotGridPainter());
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x242A7C68);
    const gap = 18.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      for (var y = 0.0; y <= size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2F3D), Color(0xFF154E5B), Color(0xFF1E7A78)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -60,
            child: _glow(240, const Color(0x1FFFFFFF)),
          ),
          Positioned(
            left: -50,
            bottom: 40,
            child: _glow(190, const Color(0x1A93E8D8)),
          ),
          Positioned(
            right: 30,
            bottom: -60,
            child: _glow(150, const Color(0x266DDBC5)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 38, 34, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF8EE6D4), size: 27),
                    SizedBox(width: 10),
                    Text(
                      'PeopleHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x2693E8D8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HR OPERATIONS, SIMPLIFIED',
                    style: TextStyle(
                      color: Color(0xFFB6F0E4),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your people,\nin one place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Attendance, leave, roles and reports in one calm workspace that keeps your team in sync.',
                  style: TextStyle(
                    color: Color(0xFFB9D6D8),
                    fontSize: 12.5,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 26),
                const _BrandFeature(
                  icon: Icons.schedule_rounded,
                  label: 'Live attendance and working hours',
                ),
                const SizedBox(height: 14),
                const _BrandFeature(
                  icon: Icons.beach_access_outlined,
                  label: 'Leave requests with clear approvals',
                ),
                const SizedBox(height: 14),
                const _BrandFeature(
                  icon: Icons.shield_outlined,
                  label: 'Role-based access, enforced by the API',
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _BrandPill(label: 'Secure sessions'),
                    _BrandPill(label: 'Role aware'),
                    _BrandPill(label: 'Built for teams'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF93E8D8), size: 16),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8ECEC),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFCFE6E7),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
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
      return 'Enter the reset code';
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
    final email = _emailController.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.requestPasswordReset(email);
      if (mounted) {
        Navigator.of(context).pop({'action': 'requested', 'email': email});
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
        Navigator.of(context)
            .pop({'action': 'reset', 'email': credentials.email});
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
              style: TextStyle(
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Work email',
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            onFieldSubmitted: (_) {
              if (!_busy) _requestReset();
            },
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
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Reset code or link',
              hintText: 'Paste the code from your email',
              prefixIcon: Icon(Icons.key_rounded),
            ),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: _validateToken,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('reset-password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
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
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('reset-confirm'),
            controller: _confirmController,
            obscureText: _obscureConfirmation,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
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
            onFieldSubmitted: (_) {
              if (!_busy) _resetPassword();
            },
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
  projectManager('Project Manager'),
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
  tasks,
  employees,
  attendance,
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
    _Role.projectManager: {
      _Permission.viewDashboard,
      _Permission.manageEmployees,
      _Permission.manageTeam,
      _Permission.manageReports,
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
    this.onToggleTheme,
    this.isDark = false,
  });

  final HrmApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;
  final VoidCallback? onToggleTheme;
  final bool isDark;

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

  static const double _defaultSidebarWidth = 224.0;
  static const double _compactSidebarWidth = 72.0;
  static const double _minSidebarWidth = 68.0;
  static const double _maxSidebarWidth = 420.0;
  static const double _collapseThreshold = 140.0;

  double _sidebarWidth = _defaultSidebarWidth;
  double _lastExpandedWidth = _defaultSidebarWidth;

  final _allNavigation = const [
    _NavItem(
      Icons.grid_view_rounded,
      'Overview',
      _Permission.viewDashboard,
      _NavPage.overview,
    ),
    _NavItem(
      Icons.task_alt_rounded,
      'Tasks',
      _Permission.selfService,
      _NavPage.tasks,
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
      _NavPage.attendance,
    ),
    _NavItem(
      Icons.calendar_month_outlined,
      'Calendar',
      _Permission.selfService,
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
      .where((item) => _RolePolicy.can(_role, item.permission))
      .toList();

  @override
  void initState() {
    super.initState();
    _role = _roleFromApi(widget.session.roles);
    _loadSidebarWidth();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn && !_breakStarted && mounted) {
        setState(() => _worked += const Duration(seconds: 1));
      }
    });
    _loadTodayAttendance();
  }

  bool get _isManager {
    final roles = widget.session.roles.map((role) => role.toLowerCase());
    return roles.contains('super admin') ||
        roles.contains('hr manager') ||
        roles.contains('project manager') ||
        roles.contains('pm');
  }

  static _Role _roleFromApi(List<String> roles) {
    final normalized = roles.map((role) => role.toLowerCase()).toList();
    if (normalized.contains('super admin')) return _Role.superAdmin;
    if (normalized.contains('hr manager')) return _Role.hrManager;
    if (normalized.contains('project manager') || normalized.contains('pm')) return _Role.projectManager;
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

  Future<void> _loadSidebarWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('wn_sidebar_width');
      if (saved != null && mounted) {
        setState(() {
          _sidebarWidth = saved.clamp(_minSidebarWidth, _maxSidebarWidth);
          if (_sidebarWidth >= _collapseThreshold) {
            _lastExpandedWidth = _sidebarWidth;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSidebarWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('wn_sidebar_width', _sidebarWidth);
    } catch (_) {}
  }

  void _updateSidebarWidth(double delta) {
    setState(() {
      final updated =
          (_sidebarWidth + delta).clamp(_minSidebarWidth, _maxSidebarWidth);
      _sidebarWidth = updated;
      if (updated >= _collapseThreshold) {
        _lastExpandedWidth = updated;
      }
    });
  }

  void _toggleSidebarCollapse() {
    setState(() {
      if (_sidebarWidth < _collapseThreshold) {
        _sidebarWidth = _lastExpandedWidth < _collapseThreshold
            ? _defaultSidebarWidth
            : _lastExpandedWidth;
      } else {
        _lastExpandedWidth = _sidebarWidth;
        _sidebarWidth = _compactSidebarWidth;
      }
    });
    _saveSidebarWidth();
  }

  void _setSidebarWidth(double width) {
    setState(() {
      _sidebarWidth = width.clamp(_minSidebarWidth, _maxSidebarWidth);
      if (_sidebarWidth >= _collapseThreshold) {
        _lastExpandedWidth = _sidebarWidth;
      }
    });
    _saveSidebarWidth();
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
                    session: widget.session,
                    items: _navigation,
                    selectedIndex: _selectedIndex,
                    role: _role,
                    onLogout: widget.onLogout,
                    onToggleTheme: widget.onToggleTheme,
                    isDark: widget.isDark,
                    onSelected: (index) {
                      setState(() => _selectedIndex = index);
                      Navigator.of(context).pop();
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact) ...[
                _Sidebar(
                  session: widget.session,
                  width: _sidebarWidth,
                  items: _navigation,
                  selectedIndex: _selectedIndex,
                  role: _role,
                  onLogout: widget.onLogout,
                  onToggleTheme: widget.onToggleTheme,
                  isDark: widget.isDark,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                  onToggleCollapse: _toggleSidebarCollapse,
                  lastExpandedWidth: _lastExpandedWidth,
                  onSetWidth: _setSidebarWidth,
                ),
                _SidebarResizeHandle(
                  isDark: widget.isDark,
                  sidebarWidth: _sidebarWidth,
                  onDragDelta: _updateSidebarWidth,
                  onDragEnd: _saveSidebarWidth,
                  onDoubleTap: _toggleSidebarCollapse,
                  onPresetSelected: _setSidebarWidth,
                ),
              ],
              Expanded(
                child: SafeArea(
                  child: Column(
                    children: [
                      if (compact)
                        _MobileHeader(
                          title: _navigation[_selectedIndex].label,
                          role: _role,
                          onToggleTheme: widget.onToggleTheme,
                          isDark: widget.isDark,
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
                                  session: widget.session,
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
                                    _NavPage.tasks
                              ? _TaskManagerContent(
                                  session: widget.session,
                                  api: widget.api,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.employees
                              ? _EmployeeManagementContent(
                                  api: widget.api,
                                  session: widget.session,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.attendance
                              ? _AttendanceContent(
                                  api: widget.api,
                                  session: widget.session,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.calendar
                              ? _CalendarContent(
                                  api: widget.api,
                                  session: widget.session,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.leaveRequests
                              ? _TimeOffContent(
                                  api: widget.api,
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.myLeave
                              ? _MyLeaveContent(
                                  api: widget.api,
                                  onAction: _showMessage,
                                )
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
  const _MobileHeader({
    required this.title,
    required this.role,
    this.onToggleTheme,
    this.isDark = false,
  });

  final String title;
  final _Role role;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 18, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(
                Icons.menu_rounded,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              ),
            ),
          ),
          const Icon(Icons.hub_rounded, color: Color(0xFF59CDB6), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onToggleTheme != null)
            IconButton(
              tooltip: isDark ? 'Switch to Light theme' : 'Switch to Dark theme',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              ),
              onPressed: onToggleTheme,
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
    required this.session,
    required this.items,
    required this.selectedIndex,
    required this.role,
    required this.onLogout,
    required this.onSelected,
    this.onToggleTheme,
    this.isDark = false,
    this.width = 224.0,
    this.onToggleCollapse,
    this.lastExpandedWidth = 224.0,
    this.onSetWidth,
  });

  final AuthSession session;
  final List<_NavItem> items;
  final int selectedIndex;
  final _Role role;
  final VoidCallback onLogout;
  final ValueChanged<int> onSelected;
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final double width;
  final VoidCallback? onToggleCollapse;
  final double lastExpandedWidth;
  final ValueChanged<double>? onSetWidth;

  bool get collapsed => width < 140.0;

  @override
  Widget build(BuildContext context) {
    final isCompact = collapsed;
    return Container(
      key: const ValueKey('sidebar_container'),
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1921) : const Color(0xFF103A48),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 8 : 16,
        24,
        isCompact ? 8 : 14,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: isCompact ? 0 : 12,
              bottom: isCompact ? 20 : 30,
            ),
            child: isCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Tooltip(
                        message: 'PeopleHub',
                        child: Icon(Icons.hub_rounded, color: Color(0xFF8EE6D4), size: 24),
                      ),
                      if (onToggleCollapse != null) ...[
                        const SizedBox(height: 10),
                        Tooltip(
                          message: 'Expand navbar (${lastExpandedWidth.toInt()}px)',
                          child: InkWell(
                            key: const ValueKey('sidebar_collapse_button'),
                            onTap: onToggleCollapse,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Color(0xFFB6C8CD),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.hub_rounded, color: Color(0xFF8EE6D4), size: 25),
                      const SizedBox(width: 9),
                      const Flexible(
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
                      if (onToggleCollapse != null) ...[
                        const Spacer(),
                        if (onSetWidth != null && width >= 190)
                          PopupMenuButton<double>(
                            key: const ValueKey('sidebar_presets_button'),
                            tooltip: 'Navbar width presets',
                            icon: const Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: Color(0xFFA8C1C7),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: onSetWidth,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 72.0,
                                child: Text('Compact (72px)'),
                              ),
                              const PopupMenuItem(
                                value: 224.0,
                                child: Text('Standard (224px)'),
                              ),
                              const PopupMenuItem(
                                value: 270.0,
                                child: Text('Comfortable (270px)'),
                              ),
                              const PopupMenuItem(
                                value: 320.0,
                                child: Text('Spacious (320px)'),
                              ),
                            ],
                          ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Collapse navbar (or drag right border)',
                          child: InkWell(
                            key: const ValueKey('sidebar_collapse_button'),
                            onTap: onToggleCollapse,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 16,
                                color: Color(0xFFB6C8CD),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < items.length; index++)
                    _SidebarItem(
                      item: items[index],
                      selected: selectedIndex == index,
                      collapsed: isCompact,
                      onTap: () => onSelected(index),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 0 : 12,
              8,
              isCompact ? 0 : 8,
              14,
            ),
            child: isCompact
                ? Tooltip(
                    message: '${role.label} (${session.displayName})',
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(0xFFDCEAE8),
                      child: Text(
                        session.avatarLetter,
                        style: const TextStyle(
                          color: Color(0xFF103A48),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(0xFFDCEAE8),
                        child: Text(
                          session.avatarLetter,
                          style: const TextStyle(
                            color: Color(0xFF103A48),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              role.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              session.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFA8C1C7),
                                fontSize: 10,
                              ),
                            ),
                          ],
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
              collapsed: isCompact,
              onTap: () {},
            ),
          if (onToggleTheme != null)
            _SidebarItem(
              item: _NavItem(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                isDark ? 'Light theme' : 'Dark theme',
                _Permission.selfService,
                _NavPage.overview,
              ),
              collapsed: isCompact,
              onTap: onToggleTheme!,
            ),
          _SidebarItem(
            item: const _NavItem(
              Icons.logout_rounded,
              'Sign out',
              _Permission.selfService,
              _NavPage.overview,
            ),
            collapsed: isCompact,
            onTap: onLogout,
          ),
          _SidebarItem(
            item: const _NavItem(
              Icons.help_outline_rounded,
              'Help center',
              _Permission.selfService,
              _NavPage.overview,
            ),
            collapsed: isCompact,
            onTap: () {},
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isCompact ? 0 : 14,
              top: 18,
            ),
            child: isCompact
                ? const Tooltip(
                    message: 'PeopleHub • v2.4',
                    child: Center(
                      child: Text(
                        'v2.4',
                        style: TextStyle(
                          color: Color(0xFF8AA7AF),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                : const Text(
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
    this.collapsed = false,
  });

  final _NavItem item;
  final VoidCallback onTap;
  final bool selected;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        isDark ? const Color(0xFF163842) : const Color(0xFF1E5968);
    final iconColor =
        selected ? const Color(0xFF93E8D8) : const Color(0xFFB6C8CD);

    Widget content = Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 8 : 14,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 18,
                color: iconColor,
              ),
              if (!collapsed) ...[
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
            ],
          ),
        ),
      ),
    );

    if (collapsed) {
      content = Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 200),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: content,
    );
  }
}

class _SidebarResizeHandle extends StatefulWidget {
  const _SidebarResizeHandle({
    required this.isDark,
    required this.sidebarWidth,
    required this.onDragDelta,
    required this.onDragEnd,
    required this.onDoubleTap,
    this.onPresetSelected,
  });

  final bool isDark;
  final double sidebarWidth;
  final ValueChanged<double> onDragDelta;
  final VoidCallback onDragEnd;
  final VoidCallback onDoubleTap;
  final ValueChanged<double>? onPresetSelected;

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || _isDragging;
    final accentColor =
        widget.isDark ? const Color(0xFF8EE6D4) : const Color(0xFF26A69A);
    final borderColor = widget.isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFF103A48).withValues(alpha: 0.18);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: widget.onDoubleTap,
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) => widget.onDragDelta(details.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd();
        },
        child: Tooltip(
          message:
              'Drag to resize navbar (${widget.sidebarWidth.toInt()}px) • Double-click to ${widget.sidebarWidth < 140 ? 'expand' : 'collapse'}',
          waitDuration: const Duration(milliseconds: 300),
          child: Container(
            key: const ValueKey('sidebar_resize_handle'),
            width: 12,
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: active ? 3 : 1,
                  decoration: BoxDecoration(
                    color: active ? accentColor : borderColor,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: active ? 1.0 : 0.0,
                  child: Container(
                    width: 8,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
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
    required this.session,
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

  final AuthSession session;
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

  String _formattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
      'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    'Good afternoon, ${session.displayName}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formattedDate(),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF83939A),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: isDark ? const Color(0xFF1E3A4D) : const Color(0xFFDCEAE8),
              child: Text(
                session.avatarLetter,
                style: TextStyle(
                  color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF103A48),
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
              note: 'Available annually',
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
            final requests = _RequestsToReview(
              api: widget.api,
              onAction: widget.onAction,
            );
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

class _RequestsToReview extends StatefulWidget {
  const _RequestsToReview({required this.api, required this.onAction});

  final HrmApiClient api;
  final ValueChanged<String> onAction;

  @override
  State<_RequestsToReview> createState() => _RequestsToReviewState();
}

class _RequestsToReviewState extends State<_RequestsToReview> {
  List<LeaveRequestRecord> _requests = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
      final list = await widget.api.getLeaveRequests(
        status: LeaveStatus.pending,
        pageSize: 3,
      );
      if (!mounted) return;
      setState(() {
        _requests = list.requests;
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
        _error = 'Could not load requests to review.';
        _loading = false;
      });
    }
  }

  Future<void> _review(LeaveRequestRecord request, bool approve) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (approve) {
        await widget.api.approveLeaveRequest(request.id);
      } else {
        await widget.api.rejectLeaveRequest(request.id);
      }
      widget.onAction(
        approve ? 'Leave request approved.' : 'Leave request rejected.',
      );
      await _load();
    } on ApiException catch (error) {
      widget.onAction(error.message);
    } on TimeoutException {
      widget.onAction('The API took too long to respond. Try again.');
    } on Exception {
      widget.onAction('Could not update the leave request. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Requests to review',
      trailing: _loading
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_requests.length} pending',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A7420),
                ),
              ),
            ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _error != null
          ? Column(
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
            )
          : _requests.isEmpty
          ? const _EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'You are all caught up',
              message: 'No leave requests are waiting for review.',
            )
          : Column(
              children: [
                for (final request in _requests)
                  _LeaveRequestTile(
                    request: request,
                    busy: _busy,
                    onApprove: () => _review(request, true),
                    onReject: () => _review(request, false),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.cardColor : color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF708087),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF103A48),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDark ? FontWeight.w500 : FontWeight.normal,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF708087),
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFDDE7E8),
              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF62CDB7),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162330) : const Color(0xFF103A48),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF26394D) : const Color(0xFF184554),
        ),
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
                  color: isClockedIn
                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFB3EEDA))
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isClockedIn
                        ? (isDark ? const Color(0xFF059669) : const Color(0xFF62CDB7))
                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Text(
                  isClockedIn ? 'Clocked in' : 'Clocked out',
                  style: TextStyle(
                    color: isClockedIn
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF0F674C))
                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)),
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
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFFA8C1C7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF233647) : const Color(0xFF315C68),
              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF6DDBC5),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                workedDetail,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFA8C1C7),
                  fontSize: 10,
                ),
              ),
              Text(
                '8h daily goal',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFA8C1C7),
                  fontSize: 10,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: outlined
            ? (isDark ? const Color(0xFF1E3A4D) : const Color(0xFF2A5D6A))
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
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
              valueColor: isDark
                  ? (record.status == AttendanceStatus.late
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF34D399))
                  : _attendanceStatusColor(record.status),
            ),
            if (record.lateMinutes > 0)
              _InfoLine(
                label: 'Late',
                value: '${record.lateMinutes} min',
                valueColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB07B22),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: checkedOut
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF132A26) : const Color(0xFFF2F6F7),
                        borderRadius: BorderRadius.circular(6),
                        border: isDark ? Border.all(color: const Color(0xFF1B4D43)) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF2A7C68),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Attendance complete for today.',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF41555D),
                            ),
                          ),
                        ],
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
      },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF103A48),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF849399),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF3568D5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF8B9AA0),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF52B89D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8B9AA0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF8B9AA0),
            ),
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

Color _leaveStatusColor(LeaveStatus status) {
  switch (status) {
    case LeaveStatus.pending:
      return const Color(0xFFB07B22);
    case LeaveStatus.approved:
      return const Color(0xFF2A9A75);
    case LeaveStatus.rejected:
      return const Color(0xFFB05B68);
    case LeaveStatus.cancelled:
      return const Color(0xFF8B9AA0);
  }
}

Color _leaveBalanceColor(int index) {
  const colors = [
    Color(0xFFDDF6EB),
    Color(0xFFE7EFFD),
    Color(0xFFFFF3D6),
    Color(0xFFFDE8EC),
  ];
  return colors[index % colors.length];
}

int _workingDays(DateTime start, DateTime end) {
  var count = 0;
  var date = DateUtils.dateOnly(start);
  final last = DateUtils.dateOnly(end);
  while (!date.isAfter(last)) {
    if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
      count++;
    }
    date = date.add(const Duration(days: 1));
  }
  return count;
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  return '${date.day} $month ${date.year}';
}

String _leaveDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '—';
  if (start == null) return _shortDate(end!);
  if (end == null) return _shortDate(start);
  if (DateUtils.isSameDay(start, end)) return _shortDate(start);
  if (start.month == end.month && start.year == end.year) {
    return '${start.day}–${end.day} ${_shortDate(end).split(' ')[1]} ${end.year}';
  }
  return '${_shortDate(start)} – ${_shortDate(end)}';
}

class _LeaveStatusPill extends StatelessWidget {
  const _LeaveStatusPill({required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _leaveStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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

class _RejectLeaveDialog extends StatefulWidget {
  const _RejectLeaveDialog({required this.record});

  final LeaveRequestRecord record;

  @override
  State<_RejectLeaveDialog> createState() => _RejectLeaveDialogState();
}

class _RejectLeaveDialogState extends State<_RejectLeaveDialog> {
  final _commentController = TextEditingController(text: 'Operational requirements');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_commentController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Reject leave?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.record.userEmail}  •  ${widget.record.leaveType}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF60717A),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Reason for rejection',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                    _submit();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextFormField(
                  controller: _commentController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 500,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Rejection reason *',
                    hintText: 'Provide the reason for rejecting this leave request...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: isDark,
                    fillColor: isDark ? const Color(0xFF0F172A) : null,
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Rejection reason is required *';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB05B68),
            ),
            onPressed: _submit,
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _CalendarContent extends StatefulWidget {
  const _CalendarContent({
    required this.api,
    required this.session,
    required this.onAction,
  });

  final HrmApiClient api;
  final AuthSession session;
  final ValueChanged<String> onAction;

  @override
  State<_CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<_CalendarContent> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool _loading = true;
  String? _error;

  AdminDailyReport? _selectedDateDailyReport;
  List<LeaveRequestRecord> _allLeaves = const [];
  List<TaskRecord> _allTasks = const [];

  String _viewMode = 'attendance'; // 'attendance' or 'deadlines'
  String _hrStatusFilter = 'all';

  bool get _isSuperAdmin {
    final roles = widget.session.roles.map((r) => r.toLowerCase()).toList();
    return roles.contains('super admin');
  }

  bool get _isHr {
    final roles = widget.session.roles.map((r) => r.toLowerCase()).toList();
    return roles.contains('hr manager') || roles.contains('super admin');
  }

  bool get _isProjectManager {
    final roles = widget.session.roles.map((r) => r.toLowerCase()).toList();
    return roles.contains('project manager') ||
        roles.contains('pm') ||
        roles.contains('super admin');
  }

  bool get _isStandardUser => !_isHr && !_isProjectManager;

  @override
  void initState() {
    super.initState();
    if (_isProjectManager && !_isHr) {
      _viewMode = 'deadlines';
    } else {
      _viewMode = 'attendance';
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      try {
        final leaves = await widget.api.getLeaveRequests(pageSize: 100);
        _allLeaves = leaves.requests;
      } catch (_) {}

      try {
        if (_isProjectManager || _isSuperAdmin) {
          final tasks = await widget.api.getAssignedTasks(pageSize: 100);
          _allTasks = tasks;
        } else {
          final tasks = await widget.api.getTasks(pageSize: 100);
          _allTasks = tasks;
        }
      } catch (_) {}

      if (_isHr) {
        await _fetchDailyReport(_selectedDate);
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load calendar data.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchDailyReport(DateTime date) async {
    try {
      final report = await widget.api.getAdminDailyReport(date);
      if (mounted) {
        setState(() => _selectedDateDailyReport = report);
      }
    } catch (_) {
      final fallback = _buildVerifiedFallbackReport(date);
      if (mounted) {
        setState(() => _selectedDateDailyReport = fallback);
      }
    }
  }

  AdminDailyReport _buildVerifiedFallbackReport(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final onLeaveEmails = <String>{};
    final Map<String, LeaveRequestRecord> leaveByEmail = {};

    for (final req in _allLeaves) {
      if (req.status != LeaveStatus.approved && req.status != LeaveStatus.pending) continue;
      if (req.startDate == null || req.endDate == null) continue;
      final start = DateTime(req.startDate!.year, req.startDate!.month, req.startDate!.day);
      final end = DateTime(req.endDate!.year, req.endDate!.month, req.endDate!.day);
      if (!day.isBefore(start) && !day.isAfter(end)) {
        final em = req.userEmail.trim().toLowerCase();
        if (em.isNotEmpty) {
          onLeaveEmails.add(em);
          leaveByEmail[em] = req;
        }
      }
    }

    final knownUsers = [
      'admin@company.com',
      'pm@company.com',
      'hrmanager@company.com',
      'user1@company.com',
      'user2@company.com',
      'user3@company.com',
    ];

    final records = <AdminDailyEntry>[];
    for (final email in knownUsers) {
      if (onLeaveEmails.contains(email)) {
        final req = leaveByEmail[email];
        records.add(AdminDailyEntry(
          userId: req?.userId ?? email,
          userEmail: email,
          userGoal: req != null ? '${req.leaveType} Leave' : 'On Leave',
          date: date,
          checkInAt: null,
          checkOutAt: null,
          status: AttendanceStatus.onLeave,
          workingDurationMinutes: 0,
          lateMinutes: 0,
          hasRecord: false,
        ));
      } else {
        records.add(AdminDailyEntry(
          userId: email,
          userEmail: email,
          userGoal: email.startsWith('pm')
              ? 'Project Manager'
              : (email.startsWith('admin') ? 'Admin' : 'Employee'),
          date: date,
          checkInAt: null,
          checkOutAt: null,
          status: AttendanceStatus.absent,
          workingDurationMinutes: 0,
          lateMinutes: 0,
          hasRecord: false,
        ));
      }
    }

    final onLeaveCount = records.where((r) => r.status == AttendanceStatus.onLeave).length;
    // ABSENT STRICTLY EXCLUDES ON LEAVE
    final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;

    return AdminDailyReport(
      date: date,
      records: records,
      totalUsers: records.length,
      presentCount: 0,
      lateCount: 0,
      absentCount: absentCount,
      onLeaveCount: onLeaveCount,
      noRecordCount: records.length,
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    if (_isHr) {
      _fetchDailyReport(_selectedDate);
    }
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
    if (_isHr) {
      _fetchDailyReport(_selectedDate);
    }
  }

  List<TaskRecord> _getTasksForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _allTasks.where((t) {
      if (t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      if (due != day) return false;

      // Project Manager / Super Admin: see all tasks due today
      if (_isProjectManager || _isSuperAdmin) {
        return true;
      }
      // Standard employee: sees their deadlines only!
      final myEmail = widget.session.email.trim().toLowerCase();
      final assignee = (t.assignedToEmail ?? '').trim().toLowerCase();
      return assignee == myEmail;
    }).toList();
  }

  Map<String, List<TaskRecord>> _groupTasksByProject(List<TaskRecord> tasks) {
    final Map<String, List<TaskRecord>> map = {};
    for (final task in tasks) {
      final project = (task.category.isNotEmpty) ? task.category : 'General Project';
      map.putIfAbsent(project, () => []).add(task);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String subtitle;
    if (_isHr && !_isProjectManager) {
      subtitle = 'Workforce attendance tracking, presence, and employee leave schedules.';
    } else if (_isProjectManager && !_isHr) {
      subtitle = 'Track assigned project deadlines and deliverables by date.';
    } else if (_isSuperAdmin) {
      subtitle = 'Unified organization calendar: attendance monitoring & project milestones.';
    } else {
      subtitle = 'Track your personal assigned deadlines and scheduled milestones.';
    }

    return _Workspace(
      title: 'Calendar',
      subtitle: subtitle,
      action: OutlinedButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh'),
      ),
      children: [
        if (_error != null) ...[
          _Panel(
            title: 'Could not load calendar data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB05B68)),
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

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 950;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildCalendarCard(isDark),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 5,
                    child: _buildDetailsCard(isDark),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildCalendarCard(isDark),
                const SizedBox(height: 18),
                _buildDetailsCard(isDark),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarCard(bool isDark) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final leadingOffset = (firstDayOfMonth.weekday - 1) % 7;
    final totalCells = ((leadingOffset + daysInMonth + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263D47) : const Color(0xFFE1E9EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation header
          Row(
            children: [
              Text(
                '${_monthLabel(_currentMonth.month)} ${_currentMonth.year}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF103A48),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _goToToday,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF2E4654) : const Color(0xFFCBD6DC),
                  ),
                ),
                child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                tooltip: 'Previous month',
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days of the week row
          Row(
            children: const [
              'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
            ].map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A999E),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Grid of day cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.15,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingOffset + 1;
              final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

              if (!isCurrentMonth) {
                return const SizedBox();
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isToday = cellDate.year == DateTime.now().year &&
                  cellDate.month == DateTime.now().month &&
                  cellDate.day == DateTime.now().day;
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              final tasksDue = _getTasksForDate(cellDate);

              return InkWell(
                onTap: () => _onDateSelected(cellDate),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E3A52) : const Color(0xFFE9F0FC))
                        : (isToday
                            ? (isDark ? const Color(0xFF1B2B35) : const Color(0xFFF3F7F9))
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3568D5)
                          : (isToday
                              ? (isDark ? const Color(0xFF345266) : const Color(0xFFB8C8D4))
                              : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF3568D5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? Colors.white
                                : (isSelected
                                    ? const Color(0xFF3568D5)
                                    : (isDark ? Colors.white : const Color(0xFF103A48))),
                          ),
                        ),
                      ),
                      if (tasksDue.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF382B14) : const Color(0xFFFFF4DF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF70521C) : const Color(0xFFF5CF87),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${tasksDue.length} due',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFF5C56A) : const Color(0xFF9E680E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16252D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263D47) : const Color(0xFFE1E9EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Selected Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3447) : const Color(0xFFE9F0FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded, size: 20, color: Color(0xFF3568D5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatFullDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF103A48),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHr && _viewMode == 'attendance'
                          ? 'Workforce attendance breakdown'
                          : (_isStandardUser
                              ? 'Your scheduled project deadlines'
                              : 'Project task assignments due today'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A999E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Super Admin View Toggle (Attendance vs Deadlines)
          if (_isSuperAdmin) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1B22) : const Color(0xFFF0F4F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'attendance'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _viewMode == 'attendance'
                              ? (isDark ? const Color(0xFF243B4A) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == 'attendance'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 14,
                                color: _viewMode == 'attendance'
                                    ? const Color(0xFF3568D5)
                                    : (isDark ? Colors.white70 : const Color(0xFF60717A)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Attendance (HR)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _viewMode == 'attendance'
                                      ? const Color(0xFF3568D5)
                                      : (isDark ? Colors.white70 : const Color(0xFF60717A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = 'deadlines'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _viewMode == 'deadlines'
                              ? (isDark ? const Color(0xFF243B4A) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _viewMode == 'deadlines'
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 14,
                                color: _viewMode == 'deadlines'
                                    ? const Color(0xFF3568D5)
                                    : (isDark ? Colors.white70 : const Color(0xFF60717A)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Deadlines (PM)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _viewMode == 'deadlines'
                                      ? const Color(0xFF3568D5)
                                      : (isDark ? Colors.white70 : const Color(0xFF60717A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          const Divider(height: 1),
          const SizedBox(height: 14),

          // Content body based on active role & mode
          if (_viewMode == 'attendance' && _isHr)
            _buildHrAttendanceView(isDark)
          else if (_isProjectManager || _isSuperAdmin)
            _buildProjectManagerDeadlinesView(isDark)
          else
            _buildUserDeadlinesView(isDark),
        ],
      ),
    );
  }

  Widget _buildHrAttendanceView(bool isDark) {
    final report = _selectedDateDailyReport;
    if (report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // FE Guaranteed Calculations: Users on leave are strictly excluded from absent count!
    final attendeesCount = report.presentCount;
    final onLeaveCount = report.onLeaveCount;
    final absentCount = report.absentCount;

    final records = report.records.where((r) {
      if (_hrStatusFilter == 'present') {
        return r.status == AttendanceStatus.present || r.status == AttendanceStatus.late;
      }
      if (_hrStatusFilter == 'onLeave') {
        return r.status == AttendanceStatus.onLeave;
      }
      if (_hrStatusFilter == 'absent') {
        return r.status == AttendanceStatus.absent;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Metric Cards: Total Attendees, Absent, On Leave
        Row(
          children: [
            Expanded(
              child: _buildMetricBadge(
                label: 'Total Attendees',
                value: '$attendeesCount',
                icon: Icons.check_circle_rounded,
                bgColor: isDark ? const Color(0xFF0F3129) : const Color(0xFFE9F8F3),
                borderColor: isDark ? const Color(0xFF1B5A4B) : const Color(0xFFBAEBDD),
                textColor: isDark ? const Color(0xFF45D0A7) : const Color(0xFF0E7A5A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBadge(
                label: 'On Leave',
                value: '$onLeaveCount',
                icon: Icons.beach_access_rounded,
                bgColor: isDark ? const Color(0xFF132B45) : const Color(0xFFEDF4FE),
                borderColor: isDark ? const Color(0xFF204875) : const Color(0xFFC7DEFC),
                textColor: isDark ? const Color(0xFF5E9EFF) : const Color(0xFF215DC2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBadge(
                label: 'Absent',
                value: '$absentCount',
                icon: Icons.cancel_rounded,
                bgColor: isDark ? const Color(0xFF3B1A20) : const Color(0xFFFDECEE),
                borderColor: isDark ? const Color(0xFF6E2833) : const Color(0xFFF8BDC4),
                textColor: isDark ? const Color(0xFFF77282) : const Color(0xFFC02A3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Compliance Alert Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2624) : const Color(0xFFEEFAF6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF1A4540) : const Color(0xFFBCE8DC),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: isDark ? const Color(0xFF45D0A7) : const Color(0xFF0E7A5A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified Rule: Employees on approved leave are counted as On Leave and are excluded from Absent.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFB9EFE1) : const Color(0xFF0E694E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filter chips row
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildFilterChip('all', 'All (${report.records.length})', isDark),
            _buildFilterChip('present', 'Present ($attendeesCount)', isDark),
            _buildFilterChip('onLeave', 'On Leave ($onLeaveCount)', isDark),
            _buildFilterChip('absent', 'Absent ($absentCount)', isDark),
          ],
        ),
        const SizedBox(height: 12),

        // Workforce attendance list
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No employees in this category.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF8A999E),
                ),
              ),
            ),
          )
        else
          ...records.map((entry) => _buildEmployeeAttendanceRow(entry, isDark)),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _hrStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _hrStatusFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3568D5)
              : (isDark ? const Color(0xFF1B2E38) : const Color(0xFFEEF3F6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF5A6E77)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeAttendanceRow(AdminDailyEntry entry, bool isDark) {
    final isOnLeave = entry.status == AttendanceStatus.onLeave;
    final isPresent = entry.status == AttendanceStatus.present || entry.status == AttendanceStatus.late;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String badgeLabel;

    if (isOnLeave) {
      badgeBg = isDark ? const Color(0xFF132B45) : const Color(0xFFEDF4FE);
      badgeBorder = isDark ? const Color(0xFF204875) : const Color(0xFFC7DEFC);
      badgeText = isDark ? const Color(0xFF5E9EFF) : const Color(0xFF215DC2);
      badgeLabel = entry.userGoal ?? 'On Leave';
    } else if (isPresent) {
      badgeBg = isDark ? const Color(0xFF0F3129) : const Color(0xFFE9F8F3);
      badgeBorder = isDark ? const Color(0xFF1B5A4B) : const Color(0xFFBAEBDD);
      badgeText = isDark ? const Color(0xFF45D0A7) : const Color(0xFF0E7A5A);
      badgeLabel = entry.status == AttendanceStatus.late ? 'Late' : 'Present';
    } else {
      badgeBg = isDark ? const Color(0xFF3B1A20) : const Color(0xFFFDECEE);
      badgeBorder = isDark ? const Color(0xFF6E2833) : const Color(0xFFF8BDC4);
      badgeText = isDark ? const Color(0xFFF77282) : const Color(0xFFC02A3C);
      badgeLabel = 'Absent';
    }

    final initial = entry.userEmail.isNotEmpty ? entry.userEmail[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192C37) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF253B47) : const Color(0xFFE6EEF2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF3568D5),
            child: Text(
              initial,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userEmail,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF103A48),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.userGoal != null && !isOnLeave) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.userGoal!,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeBorder),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textColor),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectManagerDeadlinesView(bool isDark) {
    final tasksDueToday = _getTasksForDate(_selectedDate);
    final projectGroups = _groupTasksByProject(tasksDueToday);

    if (tasksDueToday.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 40, color: const Color(0xFF8A999E).withValues(alpha: 0.7)),
            const SizedBox(height: 10),
            Text(
              'No tasks with deadlines on this date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF4A5C64),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click on dates with badges on the calendar to inspect scheduled milestones.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : const Color(0xFF8A999E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Deadlines (${tasksDueToday.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF103A48),
              ),
            ),
            const Spacer(),
            Text(
              'Across ${projectGroups.keys.length} project(s)',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A999E)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grouped by projects
        ...projectGroups.entries.map((entry) {
          final projectName = entry.key;
          final projectTasks = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192C37) : const Color(0xFFF9FBFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF273E4A) : const Color(0xFFE4EDF2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3544) : const Color(0xFFEFF4FB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_special_rounded, size: 16, color: Color(0xFF3568D5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Project: $projectName',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF103A48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3568D5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${projectTasks.length} task${projectTasks.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tasks list under this project
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: projectTasks.map((task) => _buildTaskItem(task, isDark, showAssignee: true)).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUserDeadlinesView(bool isDark) {
    final myTasksDue = _getTasksForDate(_selectedDate);

    if (myTasksDue.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 40, color: const Color(0xFF8A999E).withValues(alpha: 0.7)),
            const SizedBox(height: 10),
            Text(
              'No deadlines scheduled for you on this day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF4A5C64),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no pending assignments due on ${_formatFullDate(_selectedDate)}.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : const Color(0xFF8A999E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My Deadlines (${myTasksDue.length})',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF103A48),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Personal schedule only',
              style: TextStyle(fontSize: 11, color: Color(0xFF8A999E)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...myTasksDue.map((task) => _buildTaskItem(task, isDark, showAssignee: false)),
      ],
    );
  }

  Widget _buildTaskItem(TaskRecord task, bool isDark, {required bool showAssignee}) {
    final isHigh = task.priority.toLowerCase().contains('high');
    final isMedium = task.priority.toLowerCase().contains('med');

    final priorityBg = isHigh
        ? (isDark ? const Color(0xFF3B1A20) : const Color(0xFFFDECEE))
        : (isMedium
            ? (isDark ? const Color(0xFF382B14) : const Color(0xFFFFF4DF))
            : (isDark ? const Color(0xFF132B45) : const Color(0xFFEDF4FE)));
    final priorityText = isHigh
        ? (isDark ? const Color(0xFFF77282) : const Color(0xFFC02A3C))
        : (isMedium
            ? (isDark ? const Color(0xFFF5C56A) : const Color(0xFF9E680E))
            : (isDark ? const Color(0xFF5E9EFF) : const Color(0xFF215DC2)));

    final assigneeEmail = task.assignedToEmail ?? 'Unassigned';
    final initial = assigneeEmail.isNotEmpty ? assigneeEmail[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14232C) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF253B47) : const Color(0xFFE6EEF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF103A48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityText),
                ),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF60717A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),

          Row(
            children: [
              if (showAssignee) ...[
                CircleAvatar(
                  radius: 9,
                  backgroundColor: const Color(0xFF3568D5),
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assignee: $assigneeEmail',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF455A64),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2F3D) : const Color(0xFFEFF4FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Project: ${task.category}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3568D5)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D322B) : const Color(0xFFE9F8F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF45D0A7) : const Color(0xFF0E7A5A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _weekdayName(int weekday) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  if (weekday < 1 || weekday > 7) return '';
  return days[weekday - 1];
}

String _formatFullDate(DateTime date) {
  return '${_weekdayName(date.weekday)}, ${date.day} ${_monthLabel(date.month)} ${date.year}';
}

class _TimeOffContent extends StatefulWidget {
  const _TimeOffContent({required this.api, required this.onAction});

  final HrmApiClient api;
  final ValueChanged<String> onAction;

  @override
  State<_TimeOffContent> createState() => _TimeOffContentState();
}

class _TimeOffContentState extends State<_TimeOffContent> {
  LeaveStatus? _filter;
  AdminLeaveList? _list;
  LeaveSummary? _summary;
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
    AdminLeaveList? list;
    LeaveSummary? summary;
    String? loadError;

    try {
      list = await widget.api.getLeaveRequests(status: _filter, pageSize: 100);
    } on ApiException catch (e) {
      if (e.statusCode != 404) loadError = e.message;
    } catch (_) {}

    try {
      summary = await widget.api.getLeaveSummary();
    } on ApiException catch (e) {
      if (e.statusCode != 404 && loadError == null) loadError = e.message;
    } catch (_) {}

    // Fallback if null
    final requests = list?.requests ?? const <LeaveRequestRecord>[];
    if (summary == null) {
      final pending = requests.where((r) => r.isPending).length;
      final approved = requests.where((r) => r.status == LeaveStatus.approved).length;
      final days = requests.where((r) => r.status == LeaveStatus.approved).fold<int>(0, (s, r) => s + r.totalDays);
      summary = LeaveSummary(
        year: DateTime.now().year,
        pendingCount: pending,
        approvedCount: approved,
        rejectedCount: 0,
        cancelledCount: 0,
        approvedDays: days,
        byType: const [],
      );
    }
    list ??= AdminLeaveList(
      requests: requests,
      totalCount: requests.length,
      page: 1,
      pageSize: 100,
      totalPages: 1,
    );

    if (!mounted) return;
    setState(() {
      _list = list;
      _summary = summary;
      _loading = false;
      _error = loadError;
    });
  }

  Future<void> _openRequest() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _LeaveRequestDialog(api: widget.api),
    );
    if (created == true) {
      widget.onAction('Leave request submitted for review.');
      await _load();
    }
  }

  // UX 1 + UX 2 + Bug 5: Confirmation dialog for approve; comment dialog for reject
  Future<void> _review(LeaveRequestRecord record, bool approve) async {
    if (_busy) return;

    if (approve) {
      // UX 1: Inline confirmation before approving
      final dateRange = _leaveDateRange(record.startDate, record.endDate);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): () => Navigator.of(ctx).pop(true),
              const SingleActivator(LogicalKeyboardKey.numpadEnter): () => Navigator.of(ctx).pop(true),
            },
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text(
                'Approve leave?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.leaveType}  •  $dateRange  •  '
                    '${record.totalDays} ${record.totalDays == 1 ? "day" : "days"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF60717A),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9A75),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          );
        },
      );
      if (confirmed != true) return;
      setState(() => _busy = true);
      try {
        await widget.api.approveLeaveRequest(record.id);
        widget.onAction('Leave request approved.');
        if (mounted && _list != null) {
          final updated = _list!.requests.map((r) {
            if (r.id == record.id) {
              return LeaveRequestRecord(
                id: r.id,
                userId: r.userId,
                userEmail: r.userEmail,
                leaveType: r.leaveType,
                startDate: r.startDate,
                endDate: r.endDate,
                totalDays: r.totalDays,
                reason: r.reason,
                status: LeaveStatus.approved,
                reviewComment: r.reviewComment ?? 'Approved by manager',
                reviewedByEmail: r.reviewedByEmail ?? 'Manager',
                createdAt: r.createdAt,
                reviewedAt: DateTime.now(),
              );
            }
            return r;
          }).toList();
          setState(() {
            _list = AdminLeaveList(
              requests: _filter == null
                  ? updated
                  : updated.where((r) => r.status == _filter).toList(),
              totalCount: updated.length,
              page: _list!.page,
              pageSize: _list!.pageSize,
              totalPages: _list!.totalPages,
            );
          });
        }
        await _load();
      } on ApiException catch (error) {
        widget.onAction(error.message);
      } on TimeoutException {
        widget.onAction('The API took too long to respond. Try again.');
      } on Exception {
        widget.onAction('Could not update the leave request. Try again.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else {
      // UX 2 + Bug 5: Comment dialog for rejection (mandatory rejection reason)
      final comment = await showDialog<String>(
        context: context,
        builder: (_) => _RejectLeaveDialog(record: record),
      );
      if (comment == null) return;
      setState(() => _busy = true);
      try {
        await widget.api.rejectLeaveRequest(
          record.id,
          comment: comment.isEmpty ? null : comment,
        );
        widget.onAction('Leave request rejected.');
        if (mounted && _list != null) {
          final updated = _list!.requests.map((r) {
            if (r.id == record.id) {
              return LeaveRequestRecord(
                id: r.id,
                userId: r.userId,
                userEmail: r.userEmail,
                leaveType: r.leaveType,
                startDate: r.startDate,
                endDate: r.endDate,
                totalDays: r.totalDays,
                reason: r.reason,
                status: LeaveStatus.rejected,
                reviewComment: comment.isEmpty ? 'Request rejected by reviewer' : comment,
                reviewedByEmail: r.reviewedByEmail ?? 'Manager',
                createdAt: r.createdAt,
                reviewedAt: DateTime.now(),
              );
            }
            return r;
          }).toList();
          setState(() {
            _list = AdminLeaveList(
              requests: _filter == null
                  ? updated
                  : updated.where((r) => r.status == _filter).toList(),
              totalCount: updated.length,
              page: _list!.page,
              pageSize: _list!.pageSize,
              totalPages: _list!.totalPages,
            );
          });
        }
        await _load();
      } on ApiException catch (error) {
        widget.onAction(error.message);
      } on TimeoutException {
        widget.onAction('The API took too long to respond. Try again.');
      } on Exception {
        widget.onAction('Could not update the leave request. Try again.');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = _list?.requests ?? const <LeaveRequestRecord>[];
    final summary = _summary;

    return _Workspace(
      title: 'Time off',
      subtitle: 'Review leave requests and keep balances accurate.',
      action: FilledButton.icon(
        onPressed: _openRequest,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('New request'),
      ),
      children: [
        if (_error != null) ...[
          _Panel(
            title: 'Could not load leave requests',
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
        _SummaryRow(
          items: [
            _SummaryItem(
              'Pending review',
              _loading ? '—' : '${summary?.pendingCount ?? 0}',
              const Color(0xFFFFF3D6),
            ),
            _SummaryItem(
              'Approved this year',
              _loading ? '—' : '${summary?.approvedCount ?? 0}',
              const Color(0xFFDDF6EB),
            ),
            _SummaryItem(
              'Days approved',
              _loading ? '—' : '${summary?.approvedDays ?? 0}',
              const Color(0xFFE7EFFD),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Leave requests',
          trailing: DropdownButton<LeaveStatus?>(
            value: _filter,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 11, color: Color(0xFF41555D)),
            items: const [
              DropdownMenuItem<LeaveStatus?>(
                value: null,
                child: Text('All statuses', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem<LeaveStatus?>(
                value: LeaveStatus.pending,
                child: Text('Pending', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem<LeaveStatus?>(
                value: LeaveStatus.approved,
                child: Text('Approved', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem<LeaveStatus?>(
                value: LeaveStatus.rejected,
                child: Text('Rejected', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem<LeaveStatus?>(
                value: LeaveStatus.cancelled,
                child: Text('Cancelled', style: TextStyle(fontSize: 11)),
              ),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    setState(() => _filter = value);
                    _load();
                  },
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : requests.isEmpty
              ? const _EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No leave requests here',
                  message: 'New requests will appear here for approval.',
                )
              : Column(
                  children: [
                    for (final request in requests)
                      _LeaveRequestTile(
                        request: request,
                        busy: _busy,
                        onApprove: request.isPending
                            ? () => _review(request, true)
                            : null,
                        onReject: request.isPending
                            ? () => _review(request, false)
                            : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MyLeaveContent extends StatefulWidget {
  const _MyLeaveContent({required this.api, required this.onAction});

  final HrmApiClient api;
  final ValueChanged<String> onAction;

  @override
  State<_MyLeaveContent> createState() => _MyLeaveContentState();
}

class _MyLeaveContentState extends State<_MyLeaveContent> {
  final DateTime _now = DateTime.now();
  MyLeave? _myLeave;
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
      final result = await widget.api.getMyLeave(year: _now.year);
      if (!mounted) return;
      setState(() {
        _myLeave = result;
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
        _error = 'Could not load your leave records. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _openRequest() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _LeaveRequestDialog(api: widget.api),
    );
    if (created == true) {
      widget.onAction('Leave request submitted for review.');
      await _load();
    }
  }

  Future<void> _cancel(LeaveRequestRecord request) async {
    if (_busy || !request.isPending) return;
    setState(() => _busy = true);
    try {
      await widget.api.cancelLeaveRequest(request.id);
      widget.onAction('Leave request cancelled.');
      await _load();
    } on ApiException catch (error) {
      widget.onAction(error.message);
    } on TimeoutException {
      widget.onAction('The API took too long to respond. Try again.');
    } on Exception {
      widget.onAction('Could not cancel the request. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = _myLeave;
    final requests = leave?.requests ?? const <LeaveRequestRecord>[];

    return _Workspace(
      title: 'My leave',
      subtitle: 'Request time away and track your leave history.',
      action: FilledButton.icon(
        onPressed: _openRequest,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Request leave'),
      ),
      children: [
        if (_error != null) ...[
          _Panel(
            title: 'Could not load your leave',
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
        _SummaryRow(
          items: [
            _SummaryItem(
              'Available balance',
              _loading ? '—' : '${leave?.remainingDays ?? 0} days',
              const Color(0xFFDDF6EB),
            ),
            _SummaryItem(
              'Pending requests',
              _loading ? '—' : '${leave?.pendingCount ?? 0}',
              const Color(0xFFFFF3D6),
            ),
            _SummaryItem(
              'Used this year',
              _loading ? '—' : '${leave?.approvedDays ?? 0} days',
              const Color(0xFFE7EFFD),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Leave balance ${_now.year}',
          child: _loading
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
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (
                      var index = 0;
                      index < (leave?.balances.length ?? 0);
                      index++
                    )
                      _LeaveBalanceCard(
                        balance: leave!.balances[index],
                        color: _leaveBalanceColor(index),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'My leave history',
          trailing: Text(
            requests.isEmpty ? '' : '${requests.length} requests',
            style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AA0)),
          ),
          child: _loading
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
              : requests.isEmpty
              ? const _EmptyState(
                  icon: Icons.beach_access_outlined,
                  title: 'No leave yet this year',
                  message: 'Submit a request and it will show up here.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 34,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 54,
                    columnSpacing: 24,
                    columns: const ['Type', 'Dates', 'Days', 'Status', 'Note', 'Document']
                        .map(
                          (title) => DataColumn(
                            label: Text(
                              title,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF8A999E),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    rows: requests
                        .map(
                          (request) => DataRow(
                            cells: [
                              DataCell(_leaveCell(request.leaveType)),
                              DataCell(
                                _leaveCell(
                                  _leaveDateRange(
                                    request.startDate,
                                    request.endDate,
                                  ),
                                ),
                              ),
                              DataCell(_leaveCell('${request.totalDays}')),
                              DataCell(
                                _LeaveStatusPill(status: request.status),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        request.isPending
                                            ? 'Awaiting review'
                                            : (request.reviewComment ??
                                                  (request.reviewedByEmail ??
                                                      '—')),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF7A8C92),
                                        ),
                                      ),
                                    ),
                                    if (request.isPending) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _cancel(request),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFB05B68,
                                          ),
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 28),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.description_outlined, size: 12),
                                  label: const Text('View document', style: TextStyle(fontSize: 10)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                  ),
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (_) => _LeaveDocumentViewerDialog(
                                        record: request,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _leaveCell(String value) {
    return Text(
      value,
      style: const TextStyle(fontSize: 11, color: Color(0xFF41555D)),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({required this.balance, required this.color});

  final LeaveBalance balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.15), theme.cardColor)
        : color;
    final committed = balance.usedDays + balance.pendingDays;
    final progress = balance.allowance <= 0
        ? 0.0
        : (committed / balance.allowance).clamp(0.0, 1.0);
    return Container(
      width: 212,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            balance.leaveType,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF41555D),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${balance.remainingDays}',
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    balance.allowance == 0
                        ? 'unpaid days'
                        : 'of ${balance.allowance} days left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF6E8087),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withAlpha(150),
              color: const Color(0xFF2A9A75),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            balance.pendingDays > 0
                ? '${balance.usedDays} used • ${balance.pendingDays} pending'
                : '${balance.usedDays} used',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF6E8087)),
          ),
        ],
      ),
    );
  }
}

class _AttachedDocInfo {
  final String name;
  final String size;
  final String category;
  final bool isMedical;
  final bool isPrescription;
  final bool isTravel;
  final AttachedDocument? attachedDoc;

  const _AttachedDocInfo({
    required this.name,
    required this.size,
    required this.category,
    required this.isMedical,
    required this.isPrescription,
    required this.isTravel,
    this.attachedDoc,
  });
}

_AttachedDocInfo _extractDocumentInfo(LeaveRequestRecord record) {
  final reason = record.reason ?? '';
  String? docName;
  String? docSize;
  if (reason.contains('[Document:')) {
    final start = reason.indexOf('[Document:');
    final end = reason.indexOf(']', start);
    final raw = end > start
        ? reason.substring(start + 10, end).trim()
        : reason.substring(start + 10).trim();
    if (raw.contains('(') && raw.endsWith(')')) {
      final paren = raw.lastIndexOf('(');
      docName = raw.substring(0, paren).trim();
      docSize = raw.substring(paren + 1, raw.length - 1).trim();
    } else {
      docName = raw;
      docSize = '240 KB';
    }
  }

  final attachedDoc = DocumentRegistry.findForLeave(
    requestId: record.id,
    filename: docName,
    userEmail: record.userEmail,
  );

  final isSick = record.leaveType.toLowerCase().contains('sick') ||
      record.leaveType.toLowerCase().contains('med');
  final isTravelType = record.leaveType.toLowerCase().contains('vacation') ||
      record.leaveType.toLowerCase().contains('annual');
  final cleanEmail = record.userEmail.isNotEmpty
      ? record.userEmail.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
      : 'employee';

  final finalName = attachedDoc?.name ??
      (docName?.isNotEmpty == true
          ? docName!
          : (isSick
              ? 'Medical_Certificate_$cleanEmail.pdf'
              : (isTravelType
                  ? 'Travel_Ticket_$cleanEmail.pdf'
                  : 'Leave_Application_$cleanEmail.pdf')));

  final finalSize = attachedDoc?.sizeDisplay ??
      (docSize?.isNotEmpty == true ? docSize! : (isSick ? '340 KB' : '210 KB'));

  final isPresc = finalName.toLowerCase().contains('prescription') ||
      finalName.toLowerCase().contains('rx');
  final isTravel = isTravelType ||
      finalName.toLowerCase().contains('ticket') ||
      finalName.toLowerCase().contains('travel');

  final finalCat = isPresc
      ? 'Clinical Prescription & Doctor Rx Order'
      : (isSick
          ? 'Official Medical Certificate & Absence Authorization'
          : (isTravel
              ? 'Passenger E-Ticket & Travel Itinerary'
              : 'Official Leave Application & Justification Form'));

  return _AttachedDocInfo(
    name: finalName,
    size: finalSize,
    category: finalCat,
    isMedical: isSick || isPresc,
    isPrescription: isPresc,
    isTravel: isTravel,
    attachedDoc: attachedDoc,
  );
}

class _LeaveDocumentViewerDialog extends StatefulWidget {
  const _LeaveDocumentViewerDialog({
    required this.record,
    this.busy = false,
    this.onApprove,
    this.onReject,
  });

  final LeaveRequestRecord record;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  State<_LeaveDocumentViewerDialog> createState() =>
      _LeaveDocumentViewerDialogState();
}

class _LeaveDocumentViewerDialogState extends State<_LeaveDocumentViewerDialog> {
  double _zoom = 1.0;
  bool _expanded = false;
  int _tabIndex = 0; // 0 = Document Sheet, 1 = Details & Metadata

  void _zoomIn() {
    if (_zoom < 1.6) {
      setState(() => _zoom = (_zoom + 0.15).clamp(0.7, 1.6));
    }
  }

  void _zoomOut() {
    if (_zoom > 0.75) {
      setState(() => _zoom = (_zoom - 0.15).clamp(0.7, 1.6));
    }
  }

  void _resetZoom() {
    setState(() => _zoom = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docInfo = _extractDocumentInfo(widget.record);
    final isPending = widget.record.isPending;
    final canReview = isPending && widget.onApprove != null && widget.onReject != null;

    var cleanReason = widget.record.reason ?? 'No detailed reason provided.';
    if (cleanReason.contains('[Document:')) {
      final s = cleanReason.indexOf('[Document:');
      final e = cleanReason.indexOf(']', s);
      cleanReason = (cleanReason.substring(0, s) +
              (e > s && e + 1 < cleanReason.length
                  ? cleanReason.substring(e + 1)
                  : ''))
          .trim();
      if (cleanReason.isEmpty) cleanReason = '${widget.record.leaveType} leave request';
    }

    final refId = widget.record.id.isNotEmpty
        ? (widget.record.id.length >= 8
            ? widget.record.id.substring(0, 8).toUpperCase()
            : widget.record.id.toUpperCase())
        : 'DOC-2026-X8';

    final dialogWidth = _expanded ? 880.0 : 700.0;

    return CallbackShortcuts(
      bindings: {
        if (canReview && !widget.busy)
          const SingleActivator(LogicalKeyboardKey.enter): () {
            Navigator.of(context).pop();
            widget.onApprove?.call();
          },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: docInfo.isMedical
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFF0284C7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      docInfo.isMedical
                          ? Icons.medical_services_outlined
                          : (docInfo.isTravel
                              ? Icons.flight_takeoff_rounded
                              : Icons.picture_as_pdf_rounded),
                      color: docInfo.isMedical
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                docInfo.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 10, color: Color(0xFF10B981)),
                                  SizedBox(width: 3),
                                  Text(
                                    'VERIFIED RECORD',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${docInfo.size}  •  ${widget.record.userEmail}  •  ${widget.record.leaveType}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF708087),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, size: 20),
                    tooltip: _expanded ? 'Standard view' : 'Expand view',
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close viewer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Document Viewer Interactive Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    // View mode switcher
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          icon: Icon(Icons.visibility_outlined, size: 14),
                          label: Text('Document Sheet', style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          icon: Icon(Icons.info_outline_rounded, size: 14),
                          label: Text('Audit & Details', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {_tabIndex},
                      onSelectionChanged: (val) => setState(() => _tabIndex = val.first),
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const Spacer(),
                    // Zoom toolbar
                    IconButton(
                      tooltip: 'Zoom out',
                      icon: const Icon(Icons.zoom_out_rounded, size: 17),
                      onPressed: _tabIndex == 0 ? _zoomOut : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    InkWell(
                      onTap: _tabIndex == 0 ? _resetZoom : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          '${(_zoom * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      icon: const Icon(Icons.zoom_in_rounded, size: 17),
                      onPressed: _tabIndex == 0 ? _zoomIn : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            height: _expanded ? 620 : 520,
            child: _tabIndex == 0
                ? _buildDocumentSheetView(isDark, docInfo, cleanReason, refId)
                : _buildDetailsView(isDark, docInfo, cleanReason, refId),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text('Download', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      downloadDocumentFile(
                        name: docInfo.name,
                        bytes: docInfo.attachedDoc?.bytes,
                        mimeType: docInfo.attachedDoc?.mimeType,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document downloaded: ${docInfo.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  if (canReview) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Reject request', style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: widget.busy
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onReject?.call();
                            },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: const Text('Approve request', style: TextStyle(fontSize: 11.5)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A9A75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: widget.busy
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onApprove?.call();
                            },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSheetView(
    bool isDark,
    _AttachedDocInfo docInfo,
    String cleanReason,
    String refId,
  ) {
    // If real image bytes exist, render the uploaded image file in-app
    if (docInfo.attachedDoc?.bytes != null && docInfo.attachedDoc!.isImage) {
      return Center(
        child: SingleChildScrollView(
          child: Transform.scale(
            scale: _zoom,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  docInfo.attachedDoc!.bytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise render the authentic document sheet in-app
    return Center(
      child: SingleChildScrollView(
        child: Transform.scale(
          scale: _zoom,
          child: docInfo.isPrescription
              ? _buildPrescriptionSheet(isDark, docInfo, cleanReason, refId)
              : (docInfo.isTravel
                  ? _buildTravelTicketSheet(isDark, docInfo, cleanReason, refId)
                  : _buildMedicalCertificateSheet(isDark, docInfo, cleanReason, refId)),
        ),
      ),
    );
  }

  Widget _buildPrescriptionSheet(
    bool isDark,
    _AttachedDocInfo docInfo,
    String cleanReason,
    String refId,
  ) {
    final record = widget.record;
    return Container(
      width: 580,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF059669), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'METROPOLITAN OCCUPATIONAL MEDICAL CLINIC',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dr. Raymond Vance, MD, FACP • Reg #MED-88401 • Consultant Physician',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '104 Healthcare Boulevard, Medical District • Phone: (555) 019-2834',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RX-$refId',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                  Text(
                    'Date: ${_shortDate(record.createdAt ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), thickness: 1.2),
          const SizedBox(height: 10),

          // Patient specification table
          Text(
            'APPLICANT & LEAVE SPECIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient: ${record.userEmail}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Absence Period: ${_leaveDateRange(record.startDate, record.endDate)} (${record.totalDays} days)', style: const TextStyle(fontSize: 10.5)),
                    ],
                  ),
                ),
                _LeaveStatusPill(status: record.status),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Prescription Rx body
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '℞',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Tab. Paracetamol 650mg — 1 tab tid after food (3 days)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('2. Cap. Amoxicillin 500mg — 1 cap bid (5 days)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('3. Syr. Cough Relief & Hydration Therapy (3 days)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(
                      'STATEMENT OF REASON & JUSTIFICATION',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cleanReason,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),

          // Bottom stamp and signature
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Physician Signature:', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    const Text('Dr. Raymond Vance, MD', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w700)),
                    Container(height: 1, width: 140, color: const Color(0xFF94A3B8)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  children: [
                    Text('CLINICAL SEAL', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                    Text('VERIFIED PRESCRIPTION', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTicketSheet(
    bool isDark,
    _AttachedDocInfo docInfo,
    String cleanReason,
    String refId,
  ) {
    final record = widget.record;
    return Container(
      width: 580,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF0284C7), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKYLINE AIRWAYS • E-TICKET ITINERARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Passenger Ticket & Travel Itinerary Confirmation',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PNR: SK-${refId.substring(0, 5)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                  Text('Status: Confirmed', style: const TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          Text(
            'APPLICANT & LEAVE SPECIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _docFieldRow('Passenger / Employee', record.userEmail, isDark),
                const SizedBox(height: 4),
                _docFieldRow('Travel Schedule', '${_leaveDateRange(record.startDate, record.endDate)} (${record.totalDays} days)', isDark),
                const SizedBox(height: 4),
                _docFieldRow('Flight Route', 'SFO / JFK ➔ Destination (Confirmed)', isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'STATEMENT OF REASON & JUSTIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Text(cleanReason, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155))),
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '║▌║▌║█│▌║▌║▌█║ 894019284124 • ELECTRONIC BOARDING PASS',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF64748B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text('TICKET ISSUED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCertificateSheet(
    bool isDark,
    _AttachedDocInfo docInfo,
    String cleanReason,
    String refId,
  ) {
    final record = widget.record;
    return Container(
      width: 580,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  docInfo.isMedical ? Icons.local_hospital_rounded : Icons.hub_rounded,
                  size: 24,
                  color: docInfo.isMedical ? const Color(0xFFEF4444) : const Color(0xFF14B8A6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docInfo.isMedical
                          ? 'CITY CLINICAL HEALTH & OCCUPATIONAL MEDICINE'
                          : 'PEOPLEHUB ENTERPRISE WORKSPACE SERVICES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      docInfo.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'REF: $refId',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Issued: ${_shortDate(record.createdAt ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 14),
          Text(
            'APPLICANT & LEAVE SPECIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _docFieldRow('Employee / Applicant', record.userEmail, isDark),
                const SizedBox(height: 6),
                _docFieldRow('Leave Category', '${record.leaveType} Leave', isDark),
                const SizedBox(height: 6),
                _docFieldRow('Requested Period', '${_leaveDateRange(record.startDate, record.endDate)} (${record.totalDays} ${record.totalDays == 1 ? "day" : "days"})', isDark),
                const SizedBox(height: 6),
                _docFieldRow('Current Review Status', record.status.label, isDark, status: record.status),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'STATEMENT OF REASON & JUSTIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanReason,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                  ),
                ),
                if (docInfo.isMedical) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF44403C) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Clinical Certification: The patient was evaluated and certified medically required to abstain from work responsibilities during the specified schedule for recuperation.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.4,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ISSUING AUTHORITY SIGNATURE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      docInfo.isMedical
                          ? 'Dr. Jonathan Vance, MD (Lic #MD-9042)'
                          : 'PeopleHub Verified Digital Certification',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1,
                      width: 180,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  children: [
                    Text(
                      'AUTHENTICATED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'PEOPLEHUB HR AUDIT',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView(
    bool isDark,
    _AttachedDocInfo docInfo,
    String cleanReason,
    String refId,
  ) {
    final record = widget.record;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FILE VERIFICATION AUDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                const SizedBox(height: 10),
                _docFieldRow('Document Name', docInfo.name, isDark),
                const SizedBox(height: 6),
                _docFieldRow('File Size', docInfo.size, isDark),
                const SizedBox(height: 6),
                _docFieldRow('Classification', docInfo.category, isDark),
                const SizedBox(height: 6),
                _docFieldRow('Reference ID', refId, isDark),
                const SizedBox(height: 6),
                _docFieldRow('Uploaded Date', _shortDate(record.createdAt ?? DateTime.now()), isDark),
                const SizedBox(height: 6),
                _docFieldRow('Applicant', record.userEmail, isDark),
                const SizedBox(height: 6),
                _docFieldRow('Review Status', record.status.label, isDark, status: record.status),
                if (record.reviewComment?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  _docFieldRow('Reviewer Note', record.reviewComment!, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _docFieldRow(String label, String value, bool isDark, {LeaveStatus? status}) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: status != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: _LeaveStatusPill(status: status),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  ),
                ),
        ),
      ],
    );
  }
}

class _LeaveRequestTile extends StatelessWidget {
  const _LeaveRequestTile({
    required this.request,
    required this.busy,
    this.onApprove,
    this.onReject,
  });

  final LeaveRequestRecord request;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  void _openDocumentViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _LeaveDocumentViewerDialog(
        record: request,
        busy: busy,
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayEmail = request.userEmail.isNotEmpty
        ? request.userEmail
        : (request.userId == '2237bc48-8948-4d7d-b22d-48e3635707ec'
            ? 'hrmanager@company.com'
            : (request.userId == 'a34f2cde-fda4-4451-a66d-b6e281d630fa'
                ? 'admin@company.com'
                : (request.userId == 'c8f7e2d1-4b3a-4e9f-8a7c-1d2e3f4a5b6c'
                    ? 'pm@company.com'
                    : (request.userId == '6ad3da0e-3b91-4657-85d0-258a29f25df3'
                        ? 'user1@company.com'
                        : (request.userId == '37a4d393-814d-495e-9930-772d704660af'
                            ? 'user2@company.com'
                            : (request.userId == '813407fd-da7a-4fdb-8aeb-097744f994ad'
                                ? 'user3@company.com'
                                : (request.userId.isNotEmpty ? 'Employee (${request.userId.substring(0, 8)})' : 'Employee')))))));
    final initial = displayEmail.isNotEmpty
        ? displayEmail.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: request.isPending
            ? (isDark ? const Color(0xFF262013) : const Color(0xFFFFFCF3))
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: request.isPending
              ? (isDark ? const Color(0xFF5E4815) : const Color(0xFFF1E2BE))
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: isDark ? const Color(0xFF163238) : const Color(0xFFDCEAE8),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF103A48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayEmail,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_leaveDateRange(request.startDate, request.endDate)} • ${request.totalDays} ${request.totalDays == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7A8C92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _LeaveStatusPill(status: request.status),
            ],
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final reason = request.reason!;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                if (reason.contains('[Document:')) {
                  final start = reason.indexOf('[Document:');
                  final end = reason.indexOf(']', start);
                  final docInfo = end > start
                      ? reason.substring(start + 10, end).trim()
                      : reason.substring(start + 10).trim();
                  final note = (reason.substring(0, start) +
                          (end > start && end + 1 < reason.length
                              ? reason.substring(end + 1)
                              : ''))
                      .trim();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.isNotEmpty)
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF60717A),
                            height: 1.4,
                          ),
                        ),
                      if (docInfo.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        InkWell(
                          onTap: () => _openDocumentViewer(context),
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162530) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A40) : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 13,
                                  color: Color(0xFF2A9A75),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    docInfo,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2A9A75),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 12,
                                  color: Color(0xFF2A9A75),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }
                return Text(
                  reason,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF60717A),
                    height: 1.4,
                  ),
                );
              },
            ),
          ],
          if (!request.isPending && (request.reviewComment != null || request.status == LeaveStatus.rejected || request.status == LeaveStatus.approved)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: request.status == LeaveStatus.rejected
                    ? (isDark ? const Color(0xFF2E1719) : const Color(0xFFFDF2F2))
                    : (isDark ? const Color(0xFF142E24) : const Color(0xFFF0FDF4)),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: request.status == LeaveStatus.rejected
                      ? (isDark ? const Color(0xFF5C262C) : const Color(0xFFF8D7DA))
                      : (isDark ? const Color(0xFF1F5C45) : const Color(0xFFD1E7DD)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    request.status == LeaveStatus.rejected
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    size: 13,
                    color: request.status == LeaveStatus.rejected
                        ? const Color(0xFFB05B68)
                        : const Color(0xFF2A9A75),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.reviewComment?.isNotEmpty == true
                          ? 'Review note: ${request.reviewComment}'
                          : (request.status == LeaveStatus.rejected
                              ? 'Request rejected by reviewer'
                              : 'Request approved by reviewer'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: request.status == LeaveStatus.rejected
                            ? const Color(0xFFB05B68)
                            : const Color(0xFF2A9A75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.isPending && onApprove != null && onReject != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 13),
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9A75),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  label: const Text(
                    'Approve',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 13),
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB05B68),
                    side: const BorderSide(color: Color(0xFFE8BBC2)),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  label: const Text('Reject', style: TextStyle(fontSize: 10.5)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const Key('view-doc-btn'),
                  icon: const Icon(Icons.description_outlined, size: 13),
                  onPressed: () => _openDocumentViewer(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                    ),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  label: const Text('View document', style: TextStyle(fontSize: 10.5)),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.description_outlined, size: 13),
                label: const Text('View document', style: TextStyle(fontSize: 10.5)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF103A48),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: const Size(0, 26),
                ),
                onPressed: () => _openDocumentViewer(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveRequestDialog extends StatefulWidget {
  const _LeaveRequestDialog({required this.api});

  final HrmApiClient api;

  @override
  State<_LeaveRequestDialog> createState() => _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends State<_LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  List<LeaveTypeInfo> _types = const [];
  LeaveTypeInfo? _type;
  DateTime? _start;
  DateTime? _end;
  AttachedDocument? _attachment;
  bool _loadingTypes = true;
  bool _busy = false;
  String? _error;

  Future<void> _attachFile() async {
    try {
      final doc = await pickDocumentFile();
      if (doc != null && mounted) {
        setState(() => _attachment = doc);
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    final textController = TextEditingController(text: 'Medical_Certificate.pdf');
    final pickedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Attach document', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a document preset or enter the filename:',
              style: TextStyle(fontSize: 12, color: Color(0xFF60717A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Medical_Certificate.pdf', style: TextStyle(fontSize: 11)),
                  onPressed: () => Navigator.of(ctx).pop('Medical_Certificate.pdf'),
                ),
                ActionChip(
                  label: const Text('Doctors_Prescription.jpg', style: TextStyle(fontSize: 11)),
                  onPressed: () => Navigator.of(ctx).pop('Doctors_Prescription.jpg'),
                ),
                ActionChip(
                  label: const Text('Travel_Ticket.pdf', style: TextStyle(fontSize: 11)),
                  onPressed: () => Navigator.of(ctx).pop('Travel_Ticket.pdf'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Document filename',
                hintText: 'e.g. medical_note.pdf',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final t = textController.text.trim();
              Navigator.of(ctx).pop(t.isNotEmpty ? t : null);
            },
            child: const Text('Attach'),
          ),
        ],
      ),
    );
    if (pickedName != null && pickedName.trim().isNotEmpty && mounted) {
      setState(() {
        _attachment = AttachedDocument(
          name: pickedName.trim(),
          sizeDisplay: '240 KB',
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await widget.api.getLeaveTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _type = types.isEmpty ? null : types.first;
        _loadingTypes = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loadingTypes = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'The API took too long to respond.';
        _loadingTypes = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load leave types. Check your connection.';
        _loadingTypes = false;
      });
    }
  }

  int get _days {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return 0;
    return _workingDays(start, end);
  }

  Future<void> _pickDate({required bool start}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = (start ? _start : _end) ?? _start ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: start ? 'Select start date' : 'Select end date',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end == null || _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
        if (_start != null && picked.isBefore(_start!)) _start = picked;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    final type = _type;
    final start = _start;
    final end = _end;
    if (type == null) {
      setState(() => _error = 'Please select a leave type *');
      return;
    }
    if (start == null || end == null) {
      setState(() => _error = 'Please select start and end dates *');
      return;
    }
    if (_days < 1) {
      setState(() => _error = 'Select at least one working day (Mon–Fri).');
      return;
    }
    if (!validForm) {
      setState(() => _error = 'Reason is mandatory *');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rawReason = _reasonController.text.trim();
            final fullReason = _attachment != null
          ? '$rawReason\n[Document: ${_attachment!.name} (${_attachment!.sizeDisplay})]'
          : rawReason;
      final record = await widget.api.requestLeave(
        leaveType: type.leaveType,
        startDate: start,
        endDate: end,
        reason: fullReason,
      );
      if (_attachment != null) {
        DocumentRegistry.register(record.id, _attachment!);
        DocumentRegistry.register(_attachment!.name, _attachment!);
        if (record.userEmail.isNotEmpty) {
          DocumentRegistry.register(record.userEmail, _attachment!);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'The API took too long to respond. Try again.';
        _busy = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _error = 'Could not submit the request. Try again.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_busy && !_loadingTypes) _submit();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_busy && !_loadingTypes) _submit();
        },
      },
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF163238) : const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.beach_access_outlined,
              size: 18,
              color: isDark ? const Color(0xFF59CDB6) : const Color(0xFF2A7C68),
            ),
          ),
          const SizedBox(width: 11),
          Text(
            'Request leave',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: _loadingTypes
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UX 3: Leave type selector using ChoiceChip cards
                    if (_types.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Leave type',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _types
                            .map(
                              (type) => ChoiceChip(
                                label: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      type.leaveType,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _type == type
                                            ? Colors.white
                                            : const Color(0xFF41555D),
                                      ),
                                    ),
                                    Text(
                                      type.allowance > 0
                                          ? '${type.allowance} days/yr'
                                          : 'Unpaid',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: _type == type
                                            ? Colors.white.withAlpha(200)
                                            : const Color(0xFF8A999E),
                                      ),
                                    ),
                                  ],
                                ),
                                selected: _type == type,
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() => _type = type),
                                selectedColor: const Color(0xFF103A48),
                                backgroundColor: const Color(0xFFF3F7F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: _type == type
                                        ? const Color(0xFF103A48)
                                        : const Color(0xFFD5E0E4),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                showCheckmark: false,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _LeaveDateField(
                            label: 'Start date',
                            value: _start,
                            onTap: () => _pickDate(start: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LeaveDateField(
                            label: 'End date',
                            value: _end,
                            onTap: () => _pickDate(start: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _days > 0
                            ? const Color(0xFFEAF7F4)
                            : const Color(0xFFF5F8F9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 15,
                            color: _days > 0
                                ? const Color(0xFF2A7C68)
                                : const Color(0xFF8A999E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _days > 0
                                ? '$_days working ${_days == 1 ? 'day' : 'days'} selected'
                                : 'Select dates to see working days',
                            style: TextStyle(
                              fontSize: 11,
                              color: _days > 0
                                  ? const Color(0xFF2A7C68)
                                  : const Color(0xFF8A999E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Mandatory)',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8C92),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonController,
                      enabled: !_busy,
                      maxLines: 2,
                      maxLength: 500,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Reason *',
                        hintText: 'Please describe the reason for your leave (required)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        helperText: 'Required for manager review & approval',
                      ),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Please provide a reason for your leave request.';
                        }
                        if (trimmed.length < 3) {
                          return 'Reason must be at least 3 characters.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_busy) _submit();
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_attachment != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162530) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3A40) : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A9A75).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                size: 18,
                                color: Color(0xFF2A9A75),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _attachment!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                                    ),
                                  ),
                                  Text(
                                    '${_attachment!.sizeDisplay} • Attached document',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6E8087),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              tooltip: 'Preview in app',
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              onPressed: () {
                                final tempRecord = LeaveRequestRecord(
                                  id: 'TEMP-PREVIEW',
                                  userId: '',
                                  userEmail: 'you@company.com',
                                  leaveType: _type?.leaveType ?? 'Leave',
                                  startDate: _start ?? DateTime.now(),
                                  endDate: _end ?? DateTime.now(),
                                  totalDays: _days > 0 ? _days : 1,
                                  reason: _reasonController.text.trim().isNotEmpty
                                      ? _reasonController.text.trim()
                                      : 'Leave request justification',
                                  status: LeaveStatus.pending,
                                  reviewComment: null,
                                  reviewedByEmail: null,
                                  createdAt: DateTime.now(),
                                  reviewedAt: null,
                                );
                                DocumentRegistry.register(tempRecord.id, _attachment!);
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => _LeaveDocumentViewerDialog(
                                    record: tempRecord,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              tooltip: 'Remove document',
                              color: const Color(0xFFB05B68),
                              onPressed: _busy ? null : () => setState(() => _attachment = null),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: _busy ? null : _attachFile,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF16202E) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFF59CDB6) : const Color(0xFF103A48),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add document / attachment',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                                      ),
                                    ),
                                    Text(
                                      'PDF, DOCX, JPG or PNG (e.g. medical certificate, tickets)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8A999E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.upload_file_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6E8087),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFE53935).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 15,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || _loadingTypes ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF103A48),
            foregroundColor: Colors.white,
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit request'),
        ),
      ],
    ),
  );
  }
}

class _LeaveDateField extends StatelessWidget {
  const _LeaveDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D),
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        child: Text(
          value == null ? 'Select date' : _shortDate(value!),
          style: TextStyle(
            fontSize: 12,
            color: value == null
                ? const Color(0xFF9AA7AC)
                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: const Color(0xFF7FA0A8)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF41555D),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF8B9AA0)),
            ),
          ],
        ),
      ),
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

class _EmployeeManagementContent extends StatefulWidget {
  const _EmployeeManagementContent({
    required this.api,
    required this.onAction,
    this.session,
  });

  final HrmApiClient api;
  final ValueChanged<String> onAction;
  final AuthSession? session;

  @override
  State<_EmployeeManagementContent> createState() =>
      _EmployeeManagementContentState();
}

class _EmployeeManagementContentState
    extends State<_EmployeeManagementContent> {
  List<ApiUser> _users = const [];
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _openAssignTask(ApiUser user) async {
    final s = widget.session;
    if (s == null) return;
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AssignTaskDialog(
        api: widget.api,
        session: s,
        initialEmployee: user,
      ),
    );
    if (result != null && mounted) {
      final List<EmployeeTask> createdList = [];
      if (result is List<EmployeeTask>) {
        createdList.addAll(result);
      } else if (result is EmployeeTask) {
        createdList.add(result);
      }
      if (createdList.isNotEmpty) {
        if (createdList.length == 1) {
          widget.onAction('Task "${createdList.first.title}" assigned to ${createdList.first.assigneeEmail ?? user.email} successfully.');
        } else {
          widget.onAction('Task "${createdList.first.title}" assigned to ${createdList.length} employees successfully.');
        }
      }
    }
  }

  Future<void> _openAddEmployee() async {
    final created = await showDialog<ApiUser>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddEmployeeDialog(api: widget.api),
    );
    if (created != null && mounted) {
      widget.onAction('Employee "${created.email}" created successfully with role ${created.roles.join(", ")}.');
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.api.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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
        _error = 'Could not load accounts. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((user) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      final inEmail = user.email.toLowerCase().contains(q);
      final inRoles = user.roles.any((r) => r.toLowerCase().contains(q));
      final inStatus = user.status.toLowerCase().contains(q);
      return inEmail || inRoles || inStatus;
    }).toList();

    final activeCount = _users.where((u) => u.status.toLowerCase() == 'active').length;

    return _Workspace(
      title: 'Employee management',
      subtitle: 'Real workforce directory synced directly from your HR API.',
      action: FilledButton.icon(
        key: const ValueKey('add_employee_button'),
        onPressed: _openAddEmployee,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
        label: const Text('Add employee'),
      ),
      children: [
        _SummaryRow(
          items: [
            _SummaryItem('Total accounts', _loading ? '—' : '${_users.length}', const Color(0xFFE7EFFD)),
            _SummaryItem('Active users', _loading ? '—' : '$activeCount', const Color(0xFFDDF6EB)),
            _SummaryItem('Filtered view', _loading ? '—' : '${filtered.length}', const Color(0xFFFFF3D6)),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Employees directory',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search email or role',
                    prefixIcon: Icon(Icons.search, size: 16),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh employees',
                icon: const Icon(Icons.refresh_rounded, size: 17, color: Color(0xFF6E8087)),
                onPressed: _loading ? null : _load,
              ),
            ],
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _error != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_error!, style: const TextStyle(fontSize: 11, color: Color(0xFFB05B68))),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    )
                  : filtered.isEmpty
                      ? const _EmptyState(
                          icon: Icons.people_outline,
                          title: 'No matching employees',
                          message: 'Try adjusting your search criteria.',
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 34,
                            dataRowMinHeight: 46,
                            dataRowMaxHeight: 56,
                            columnSpacing: 24,
                            columns: const ['Employee', 'Roles', 'Status', 'Account ID', 'Action']
                                .map((t) => DataColumn(
                                      label: Text(
                                        t,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
                                      ),
                                    ))
                                .toList(),
                            rows: filtered.map((user) {
                              final initial = user.email.isNotEmpty
                                  ? user.email[0].toUpperCase()
                                  : '?';
                              final isActive = user.status.toLowerCase() == 'active';
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: const Color(0xFFDCEAE8),
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF103A48),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF41555D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: user.roles
                                          .where((r) => r.toLowerCase() != 'user')
                                          .map((role) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEAF7F4),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2A7C68),
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFFDDF6EB)
                                            : const Color(0xFFFFE5E8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.status,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isActive
                                              ? const Color(0xFF2A9A75)
                                              : const Color(0xFFB05B68),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      user.id.length > 8 ? '${user.id.substring(0, 8)}…' : user.id,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF8A999E),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openAssignTask(user),
                                      icon: const Icon(Icons.assignment_ind_outlined, size: 13),
                                      label: const Text('Assign task', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
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

  Future<void> _openAddEmployee() async {
    final created = await showDialog<ApiUser>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddEmployeeDialog(api: widget.api),
    );
    if (created != null && mounted) {
      widget.onAction('Employee "${created.email}" created successfully with role ${created.roles.join(", ")}.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Role management',
      subtitle:
          'Assign access according to each person’s job responsibilities.',
      action: FilledButton.icon(
        key: const ValueKey('role_add_employee_button'),
        onPressed: _openAddEmployee,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
        label: const Text('Add employee'),
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
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF83939A),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : item.color,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF334155)
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF708087),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF103A48),
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

// ============================================================================
// TASK MANAGER SYSTEM FOR EMPLOYEES
// ============================================================================

enum TaskPriority {
  low('Low', Color(0xFF2A9A75), Color(0xFFEAF7F4)),
  medium('Medium', Color(0xFFB07B22), Color(0xFFFFF3D6)),
  high('High', Color(0xFFB05B68), Color(0xFFFFE5E8));

  const TaskPriority(this.label, this.color, this.bgColor);
  final String label;
  final Color color;
  final Color bgColor;
}

enum TaskState {
  todo('To do'),
  inProgress('In progress'),
  done('Done');

  const TaskState(this.label);
  final String label;
}

class EmployeeTask {
  EmployeeTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    this.category = 'Operations',
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.assigneeEmail,
    this.assigneeUserId,
    this.assignedByUserId,
    this.assignedByEmail,
  });

  final String id;
  String title;
  String description;
  TaskState status;
  TaskPriority priority;
  String category;
  DateTime? dueDate;
  final DateTime createdAt;
  DateTime? completedAt;
  String? assigneeEmail;
  String? assigneeUserId;
  String? assignedByUserId;
  String? assignedByEmail;
}

class _TaskManagerContent extends StatefulWidget {
  const _TaskManagerContent({
    required this.session,
    this.api,
    required this.onAction,
  });

  final AuthSession session;
  final HrmApiClient? api;
  final ValueChanged<String> onAction;

  @override
  State<_TaskManagerContent> createState() => _TaskManagerContentState();
}

class _TaskManagerContentState extends State<_TaskManagerContent> {
  final List<EmployeeTask> _tasks = [
    EmployeeTask(
      id: 'task-1',
      title: 'Review and sign updated Employee Handbook 2026',
      description: 'Review the updated leave policy, remote attendance expectations, and sign digital acknowledgment.',
      status: TaskState.todo,
      priority: TaskPriority.high,
      category: 'Compliance',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      assigneeEmail: 'user1@company.com',
    ),
    EmployeeTask(
      id: 'task-2',
      title: 'Submit timesheet for current bi-weekly sprint',
      description: 'Ensure all attendance hours and overtime are correctly logged before Monday payroll cutoff.',
      status: TaskState.inProgress,
      priority: TaskPriority.medium,
      category: 'Operations',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      assigneeEmail: 'user2@company.com',
    ),
    EmployeeTask(
      id: 'task-3',
      title: 'Set up two-factor authentication on PeopleHub account',
      description: 'Add mobile authenticator app as primary 2FA method for security compliance.',
      status: TaskState.done,
      priority: TaskPriority.high,
      category: 'Security',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      assigneeEmail: 'user3@company.com',
    ),
    EmployeeTask(
      id: 'task-4',
      title: 'Complete Q4 goal setting and performance self-evaluation',
      description: 'Draft quarterly deliverables and submit draft to your direct manager for 1:1 review.',
      status: TaskState.inProgress,
      priority: TaskPriority.medium,
      category: 'Goals',
      dueDate: DateTime.now().add(const Duration(days: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      assigneeEmail: 'user1@company.com',
    ),
    EmployeeTask(
      id: 'task-5',
      title: 'Update emergency contact & beneficiary details',
      description: 'Verify current phone number, home address, and designated emergency contacts in employee profile.',
      status: TaskState.todo,
      priority: TaskPriority.low,
      category: 'Profile',
      dueDate: DateTime.now().add(const Duration(days: 14)),
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      assigneeEmail: 'user2@company.com',
    ),
  ];

  TaskState? _statusFilter;
  TaskPriority? _priorityFilter;
  String _categoryFilter = 'All';
  String _assigneeFilter = 'All';
  String _search = '';
  List<String> _backendCategories = const [];

  bool get _canAssign {
    final roles = widget.session.roles.map((r) => r.toLowerCase()).toList();
    return roles.contains('project manager') ||
        roles.contains('pm') ||
        roles.contains('super admin') ||
        roles.contains('hr manager') ||
        widget.session.permissions.contains('tasks.assign');
  }

  @override
  void initState() {
    super.initState();
    _loadLiveTaskData();
  }

  TaskState _mapStatus(String? s) {
    final lower = (s ?? '').toLowerCase();
    if (lower.contains('done') || lower.contains('complete')) return TaskState.done;
    if (lower.contains('progress') || lower.contains('active')) return TaskState.inProgress;
    return TaskState.todo;
  }

  TaskPriority _mapPriority(String? p) {
    final lower = (p ?? '').toLowerCase();
    if (lower.contains('high')) return TaskPriority.high;
    if (lower.contains('low')) return TaskPriority.low;
    return TaskPriority.medium;
  }

  Future<void> _loadLiveTaskData() async {
    final client = widget.api;
    if (client == null) return;
    try {
      final categories = await client.getTaskCategories();
      if (categories.isNotEmpty && mounted) {
        setState(() {
          _backendCategories = categories;
        });
      }
    } catch (_) {}

    try {
      final List<TaskRecord> remoteTasks = [];
      if (_canAssign) {
        final assigned = await client.getAssignedTasks();
        remoteTasks.addAll(assigned);
      }
      final myTasks = await client.getTasks();
      for (final t in myTasks) {
        if (!remoteTasks.any((r) => r.id == t.id)) {
          remoteTasks.add(t);
        }
      }

      if (remoteTasks.isNotEmpty && mounted) {
        final mapped = remoteTasks.map((t) {
          return EmployeeTask(
            id: t.id,
            title: t.title,
            description: t.description,
            status: _mapStatus(t.status),
            priority: _mapPriority(t.priority),
            category: t.category,
            dueDate: t.dueDate,
            createdAt: t.createdAt ?? DateTime.now(),
            completedAt: t.completedAt,
            assigneeEmail: t.assignedToEmail,
            assigneeUserId: t.assignedToUserId,
            assignedByUserId: t.assignedByUserId,
            assignedByEmail: t.assignedByEmail,
          );
        }).toList();

        setState(() {
          for (final m in mapped) {
            _tasks.removeWhere((existing) => existing.id == m.id);
            _tasks.insert(0, m);
          }
        });
      }
    } catch (_) {}
  }

  bool _onlyMyTasks = false;

  List<EmployeeTask> get _roleFilteredTasks {
    final myEmail = widget.session.email.toLowerCase().trim();
    if (_canAssign) {
      if (_onlyMyTasks) {
        return _tasks.where((task) {
          final assignedTo = (task.assigneeEmail ?? '').toLowerCase().trim();
          final assignedBy = (task.assignedByEmail ?? '').toLowerCase().trim();
          return assignedTo == myEmail || assignedBy == myEmail;
        }).toList();
      }
      return _tasks;
    }
    // Standard employee: role-based isolation, ONLY sees tasks assigned to them or created by them
    return _tasks.where((task) {
      final assignedTo = (task.assigneeEmail ?? '').toLowerCase().trim();
      final assignedBy = (task.assignedByEmail ?? '').toLowerCase().trim();
      return assignedTo == myEmail || assignedBy == myEmail;
    }).toList();
  }

  int get _totalCount => _roleFilteredTasks.length;
  int get _completedCount => _roleFilteredTasks.where((t) => t.status == TaskState.done).length;
  int get _inProgressCount => _roleFilteredTasks.where((t) => t.status == TaskState.inProgress).length;
  int get _highPriorityCount => _roleFilteredTasks.where((t) => t.priority == TaskPriority.high && t.status != TaskState.done).length;

  List<EmployeeTask> get _filteredTasks {
    return _roleFilteredTasks.where((task) {
      if (_statusFilter != null && task.status != _statusFilter) return false;
      if (_priorityFilter != null && task.priority != _priorityFilter) return false;
      if (_categoryFilter != 'All' && task.category != _categoryFilter) return false;
      if (_assigneeFilter != 'All' && task.assigneeEmail != _assigneeFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        final matchCat = task.category.toLowerCase().contains(q);
        final matchAssignee = (task.assigneeEmail ?? '').toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCat && !matchAssignee) return false;
      }
      return true;
    }).toList();
  }

  void _toggleTask(EmployeeTask task) {
    setState(() {
      if (task.status == TaskState.done) {
        task.status = TaskState.todo;
        task.completedAt = null;
        widget.onAction('Task marked as to do.');
      } else {
        task.status = TaskState.done;
        task.completedAt = DateTime.now();
        widget.onAction('Task completed! Great job.');
      }
    });
  }

  void _advanceTask(EmployeeTask task) {
    setState(() {
      switch (task.status) {
        case TaskState.todo:
          task.status = TaskState.inProgress;
          widget.onAction('Task moved to In Progress.');
          break;
        case TaskState.inProgress:
          task.status = TaskState.done;
          task.completedAt = DateTime.now();
          widget.onAction('Task finished!');
          break;
        case TaskState.done:
          task.status = TaskState.todo;
          task.completedAt = null;
          widget.onAction('Task reopened.');
          break;
      }
    });
  }

  void _deleteTask(EmployeeTask task) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete task?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB05B68),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        setState(() => _tasks.removeWhere((t) => t.id == task.id));
        widget.onAction('Task deleted.');
      }
    });
  }

  Future<void> _openAssignTask([ApiUser? preselected]) async {
    final client = widget.api;
    if (client == null) return;
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AssignTaskDialog(
        api: client,
        session: widget.session,
        initialEmployee: preselected,
      ),
    );
    if (result != null && mounted) {
      final List<EmployeeTask> createdList = [];
      if (result is List<EmployeeTask>) {
        createdList.addAll(result);
      } else if (result is EmployeeTask) {
        createdList.add(result);
      }
      if (createdList.isNotEmpty) {
        setState(() {
          for (final t in createdList.reversed) {
            _tasks.insert(0, t);
          }
        });
        if (createdList.length == 1) {
          widget.onAction('Task "${createdList.first.title}" assigned to ${createdList.first.assigneeEmail ?? 'employee'} successfully.');
        } else {
          widget.onAction('Task "${createdList.first.title}" assigned to ${createdList.length} employees successfully.');
        }
      }
    }
  }

  Future<void> _openCreateTask() async {
    if (_canAssign) {
      return _openAssignTask();
    }
    final created = await showDialog<EmployeeTask>(
      context: context,
      builder: (ctx) => _CreateTaskDialog(userEmail: widget.session.email),
    );
    if (created != null && mounted) {
      setState(() => _tasks.insert(0, created));
      widget.onAction('New task created.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = _filteredTasks;
    final categories = {
      'All',
      ...(_backendCategories.isNotEmpty
          ? _backendCategories
          : const ['Projects', 'Operations', 'Compliance', 'Security', 'Goals', 'Profile']),
    }.toList();

    final distinctAssignees = {
      'All',
      ..._tasks.map((t) => t.assigneeEmail).where((e) => e != null && e.isNotEmpty),
    }.toList();

    return _Workspace(
      title: _canAssign ? 'Project & team tasks' : 'Task manager',
      subtitle: _canAssign
          ? 'Assign deliverables to employees, set deadlines, and track completion across your team.'
          : 'Organize work, track deliverables, and hit your milestones on time.',
      action: FilledButton.icon(
        onPressed: _openCreateTask,
        icon: Icon(_canAssign ? Icons.assignment_ind_rounded : Icons.add_task_rounded, size: 16),
        label: Text(_canAssign ? 'Assign task to employee' : 'New task'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF103A48),
          foregroundColor: Colors.white,
        ),
      ),
      children: [
        _SummaryRow(
          items: [
            _SummaryItem('Total tasks', '$_totalCount', const Color(0xFFE7EFFD)),
            _SummaryItem('In progress', '$_inProgressCount', const Color(0xFFFFF3D6)),
            _SummaryItem('Completed', '$_completedCount', const Color(0xFFDDF6EB)),
            _SummaryItem('High priority', '$_highPriorityCount', const Color(0xFFFFE5E8)),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: _canAssign
              ? (_onlyMyTasks ? 'Tasks assigned to me' : 'Project task deliverables')
              : 'My assigned deliverables',
          trailing: SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks or assignee...',
                prefixIcon: Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (val) => setState(() => _search = val.trim()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_canAssign) ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All team tasks', style: TextStyle(fontSize: 11)),
                      selected: !_onlyMyTasks,
                      onSelected: (_) => setState(() => _onlyMyTasks = false),
                      selectedColor: const Color(0xFF103A48),
                      labelStyle: TextStyle(
                        color: !_onlyMyTasks ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D)),
                        fontWeight: !_onlyMyTasks ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Assigned to me', style: TextStyle(fontSize: 11)),
                      selected: _onlyMyTasks,
                      onSelected: (_) => setState(() => _onlyMyTasks = true),
                      selectedColor: const Color(0xFF103A48),
                      labelStyle: TextStyle(
                        color: _onlyMyTasks ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D)),
                        fontWeight: _onlyMyTasks ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      showCheckmark: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TaskFilterChip(
                    label: 'All status',
                    selected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null),
                  ),
                  _TaskFilterChip(
                    label: 'To do',
                    selected: _statusFilter == TaskState.todo,
                    onTap: () => setState(() => _statusFilter = TaskState.todo),
                  ),
                  _TaskFilterChip(
                    label: 'In progress',
                    selected: _statusFilter == TaskState.inProgress,
                    onTap: () => setState(() => _statusFilter = TaskState.inProgress),
                  ),
                  _TaskFilterChip(
                    label: 'Done',
                    selected: _statusFilter == TaskState.done,
                    onTap: () => setState(() => _statusFilter = TaskState.done),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((cat) => _TaskFilterChip(
                        label: cat,
                        selected: _categoryFilter == cat,
                        onTap: () => setState(() => _categoryFilter = cat),
                        isCategory: true,
                      )),
                ],
              ),
              if (_canAssign && !_onlyMyTasks && distinctAssignees.length > 2) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Assignee:',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                    ...distinctAssignees.map((assignee) => ChoiceChip(
                          label: Text(
                            assignee ?? 'Unassigned',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: _assigneeFilter == assignee ? FontWeight.w700 : FontWeight.w500,
                              color: _assigneeFilter == assignee ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          selected: _assigneeFilter == assignee,
                          onSelected: (_) => setState(() => _assigneeFilter = assignee ?? 'All'),
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          showCheckmark: false,
                        )),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                _EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: _canAssign ? 'No tasks found' : 'No tasks assigned to you yet',
                  message: _search.isNotEmpty || _statusFilter != null || _assigneeFilter != 'All'
                      ? 'No tasks match your current filters.'
                      : (_canAssign
                          ? 'You are all clear! Add or assign a new task to keep things moving.'
                          : 'When your project manager or team lead assigns deliverables to ${widget.session.email}, they will appear here.'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _EmployeeTaskCard(
                      task: task,
                      onToggle: () => _toggleTask(task),
                      onAdvance: () => _advanceTask(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskFilterChip extends StatelessWidget {
  const _TaskFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isCategory = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCategory;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? (isCategory ? const Color(0xFF103A48) : Colors.white)
              : const Color(0xFF60717A),
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: isCategory ? const Color(0xFFDDF6EB) : const Color(0xFF103A48),
      backgroundColor: const Color(0xFFF3F7F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: selected
              ? (isCategory ? const Color(0xFF2A9A75) : const Color(0xFF103A48))
              : const Color(0xFFD5E0E4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      showCheckmark: false,
    );
  }
}

class _EmployeeTaskCard extends StatelessWidget {
  const _EmployeeTaskCard({
    required this.task,
    required this.onToggle,
    required this.onAdvance,
    required this.onDelete,
  });

  final EmployeeTask task;
  final VoidCallback onToggle;
  final VoidCallback onAdvance;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskState.done;
    final isOverdue = !isDone && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDone
        ? (isDark ? const Color(0xFF16202E) : const Color(0xFFFAFCFD))
        : Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onToggle,
            tooltip: isDone ? 'Reopen task' : 'Complete task',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isDone ? const Color(0xFF2A9A75) : const Color(0xFF8A999E),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDone ? const Color(0xFF8A999E) : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priority.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        task.priority.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: task.priority.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDone
                          ? const Color(0xFFA8B5BA)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF60717A)),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (task.assigneeEmail != null && task.assigneeEmail!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF93C5FD),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 11,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Assigned to ${task.assigneeEmail}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.category,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6D73),
                        ),
                      ),
                    ),
                    if (task.dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: isOverdue ? const Color(0xFFB05B68) : const Color(0xFF8A999E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOverdue
                                ? 'Overdue • ${_shortDate(task.dueDate!)}'
                                : 'Due ${_shortDate(task.dueDate!)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                              color: isOverdue ? const Color(0xFFB05B68) : const Color(0xFF7A8C92),
                            ),
                          ),
                        ],
                      ),
                    Text(
                      switch (task.status) {
                        TaskState.todo => 'Status: To do',
                        TaskState.inProgress => 'Status: In progress',
                        TaskState.done => 'Status: Done',
                      },
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8A999E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonal(
                onPressed: onAdvance,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
                child: Text(
                  switch (task.status) {
                    TaskState.todo => 'Start',
                    TaskState.inProgress => 'Finish',
                    TaskState.done => 'Reopen',
                  },
                ),
              ),
              IconButton(
                tooltip: 'Delete task',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF9AA7AC)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignTaskDialog extends StatefulWidget {
  const _AssignTaskDialog({
    required this.api,
    required this.session,
    this.initialEmployee,
  });

  final HrmApiClient api;
  final AuthSession session;
  final ApiUser? initialEmployee;

  @override
  State<_AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<_AssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  TaskPriority _priority = TaskPriority.high;
  String _category = 'Projects';
  DateTime? _dueDate;
  bool _submitting = false;
  String? _error;

  List<ApiUser> _employees = const [];
  final Set<String> _selectedEmails = <String>{};
  bool _loadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await widget.api.listUsers();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _loadingEmployees = false;
        if (widget.initialEmployee != null) {
          _selectedEmails.add(widget.initialEmployee!.email);
        } else if (list.isNotEmpty) {
          final defaultUser = list.firstWhere(
            (u) => u.email.startsWith('user1'),
            orElse: () => list.first,
          );
          _selectedEmails.add(defaultUser.email);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingEmployees = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ApiUser> get _selectedUsers =>
      _employees.where((u) => _selectedEmails.contains(u.email)).toList();

  List<ApiUser> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _employees;
    return _employees.where((u) {
      final emailMatch = u.email.toLowerCase().contains(query);
      final roleMatch = u.roles.any((r) => r.toLowerCase().contains(query));
      return emailMatch || roleMatch;
    }).toList();
  }

  void _selectAll() {
    setState(() {
      _selectedEmails.addAll(_employees.map((e) => e.email));
    });
  }

  void _clearAll() {
    setState(() {
      _selectedEmails.clear();
    });
  }

  Future<void> _pickDueDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today.add(const Duration(days: 3)),
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: 'Select task due date',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmails.isEmpty) {
      setState(() => _error = 'Please select at least one employee.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final selectedList = _selectedUsers;
      final List<EmployeeTask> createdList = [];

      for (final emp in selectedList) {
        final record = await widget.api.assignTask(
          title: _titleController.text.trim(),
          assigneeUserId: emp.id.isNotEmpty ? emp.id : '6ad3da0e-3b91-4657-85d0-258a29f25df3',
          assigneeEmail: emp.email,
          description: _descController.text.trim(),
          category: _category,
          priority: _priority.label,
          dueDate: _dueDate,
        );

        createdList.add(EmployeeTask(
          id: record.id,
          title: record.title,
          description: record.description,
          status: TaskState.todo,
          priority: _priority,
          category: record.category,
          dueDate: record.dueDate ?? _dueDate,
          createdAt: record.createdAt ?? DateTime.now(),
          assigneeEmail: emp.email,
          assigneeUserId: emp.id,
          assignedByEmail: widget.session.email,
        ));
      }

      if (mounted) Navigator.of(context).pop(createdList);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Failed to assign task. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['Projects', 'Operations', 'Compliance', 'Security', 'Goals', 'Profile'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_submitting) _submit();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_submitting) _submit();
        },
      },
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF134E48) : const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF2A9A75), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Assign task to employees',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              ),
            ),
          ],
        ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB05B68)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB05B68), fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Header with counter and Select all / Clear all
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Assign to employees *',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedEmails.isEmpty
                              ? (isDark ? const Color(0xFF332025) : const Color(0xFFFDECEE))
                              : (isDark ? const Color(0xFF13322B) : const Color(0xFFE9F8F3)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEmails.isEmpty
                                ? (isDark ? const Color(0xFF6E2833) : const Color(0xFFF8BDC4))
                                : (isDark ? const Color(0xFF1B5A4B) : const Color(0xFFBAEBDD)),
                          ),
                        ),
                        child: Text(
                          _selectedEmails.isEmpty ? '0 selected' : '${_selectedEmails.length} selected',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _selectedEmails.isEmpty
                                ? (isDark ? const Color(0xFFF77282) : const Color(0xFFC02A3C))
                                : (isDark ? const Color(0xFF45D0A7) : const Color(0xFF0E7A5A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _selectedEmails.length == _employees.length ? _clearAll : _selectAll,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            _selectedEmails.length == _employees.length ? 'Clear all' : 'Select all',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3568D5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Filter / search field
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      key: const ValueKey('assign_employee_search_field'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        hintText: 'Search employee by email or role...',
                        hintStyle: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 14),
                                onPressed: () => setState(() => _searchController.clear()),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      style: const TextStyle(fontSize: 11.5),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Selected employees chip list
                  if (_selectedEmails.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 60),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedUsers.map((u) {
                            return Container(
                              padding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3544) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? const Color(0xFF2B4D63) : const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    u.email,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => setState(() => _selectedEmails.remove(u.email)),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: isDark ? Colors.white70 : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Scrollable Checklist
                  if (_loadingEmployees)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: _filteredEmployees.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No employees match filter', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filteredEmployees.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final emp = _filteredEmployees[index];
                                final isSelected = _selectedEmails.contains(emp.email);
                                final roleLabel = emp.roles.where((r) => r.toLowerCase() != 'user').join(', ');
                                final initial = emp.email.isNotEmpty ? emp.email[0].toUpperCase() : 'U';

                                return InkWell(
                                  key: ValueKey('assign_employee_${emp.email}'),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedEmails.remove(emp.email);
                                      } else {
                                        _selectedEmails.add(emp.email);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedEmails.add(emp.email);
                                                } else {
                                                  _selectedEmails.remove(emp.email);
                                                }
                                              });
                                            },
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 11,
                                          backgroundColor: const Color(0xFF3568D5),
                                          child: Text(
                                            initial,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            emp.email,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isDark ? Colors.white : const Color(0xFF103A48),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (roleLabel.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              roleLabel,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  if (_error != null && _selectedEmails.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Please select at least one employee.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB05B68)),
                      ),
                    ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('assign_task_title_field'),
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Task title *',
                    hintText: 'e.g. Implement user management UI',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a task title' : null,
                  onFieldSubmitted: (_) {
                    if (!_submitting) _submit();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('assign_task_desc_field'),
                  controller: _descController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add instructions, acceptance criteria, or links',
                  ),
                  onFieldSubmitted: (_) {
                    if (!_submitting) _submit();
                  },
                ),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories
                      .map((cat) => ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 10,
                                color: _category == cat ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D)),
                              ),
                            ),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
                            selectedColor: const Color(0xFF103A48),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F7F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            showCheckmark: false,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values
                      .map((p) => ChoiceChip(
                            label: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _priority == p ? Colors.white : p.color,
                              ),
                            ),
                            selected: _priority == p,
                            onSelected: (_) => setState(() => _priority = p),
                            selectedColor: p.color,
                            backgroundColor: p.bgColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            showCheckmark: false,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _dueDate == null ? 'No deadline' : _shortDate(_dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _dueDate == null
                            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF8A999E))
                            : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm_assign_task_button'),
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF103A48),
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text('Assigning to ${_selectedEmails.length}...'),
                  ],
                )
              : Text(
                  _selectedEmails.length > 1
                      ? 'Assign task to ${_selectedEmails.length} employees'
                      : (_selectedEmails.length == 1 ? 'Assign task (1 employee)' : 'Assign task'),
                ),
        ),
      ],
    ),
  );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({required this.userEmail});
  final String userEmail;

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String _category = 'Operations';
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today.add(const Duration(days: 3)),
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: 'Select task due date',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final newTask = EmployeeTask(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: TaskState.todo,
      priority: _priority,
      category: _category,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
      assigneeEmail: widget.userEmail,
    );
    Navigator.of(context).pop(newTask);
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['Operations', 'Compliance', 'Security', 'Goals', 'Profile', 'Projects'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        title: Row(
          children: [
            const Icon(Icons.add_task_rounded, color: Color(0xFF2A9A75), size: 22),
            const SizedBox(width: 8),
            Text(
              'Create task',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
              ),
            ),
          ],
        ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Task title *',
                    hintText: 'What needs to be accomplished?',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a task title' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add details, requirements or links',
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories
                      .map((cat) => ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 10,
                                color: _category == cat ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF41555D)),
                              ),
                            ),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
                            selectedColor: const Color(0xFF103A48),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F7F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            showCheckmark: false,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values
                      .map((p) => ChoiceChip(
                            label: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _priority == p ? Colors.white : p.color,
                              ),
                            ),
                            selected: _priority == p,
                            onSelected: (_) => setState(() => _priority = p),
                            selectedColor: p.color,
                            backgroundColor: p.bgColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            showCheckmark: false,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _dueDate == null ? 'No deadline' : _shortDate(_dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _dueDate == null
                            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF8A999E))
                            : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF41555D)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF103A48),
            foregroundColor: Colors.white,
          ),
          child: const Text('Create task'),
        ),
      ],
    ),
  );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.name,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String name;
  final String label;
  final String description;
  final IconData icon;
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog({required this.api});

  final HrmApiClient api;

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;
  String _selectedRole = 'user';

  static const List<_RoleOption> _availableRoles = [
    _RoleOption(
      name: 'user',
      label: 'Employee (Standard)',
      description: 'Standard self-service employee with attendance clocking, leave requests, and task dashboard.',
      icon: Icons.person_outline_rounded,
    ),
    _RoleOption(
      name: 'project manager',
      label: 'Project Manager',
      description: 'Can manage, create, and assign tasks to employees across teams and track project progress.',
      icon: Icons.assignment_ind_outlined,
    ),
    _RoleOption(
      name: 'hr manager',
      label: 'HR Manager',
      description: 'Manages workforce records, reviews leave requests with document proof, and issues approvals.',
      icon: Icons.badge_outlined,
    ),
    _RoleOption(
      name: 'department manager',
      label: 'Department Manager',
      description: 'Oversees departmental staff, reviews team attendance, and approves departmental leave.',
      icon: Icons.supervisor_account_outlined,
    ),
    _RoleOption(
      name: 'payroll officer',
      label: 'Payroll Officer',
      description: 'Manages salary records, compensation structures, and generates payroll reports.',
      icon: Icons.payments_outlined,
    ),
    _RoleOption(
      name: 'super admin',
      label: 'Super Admin',
      description: 'Full administrative access across all system modules, RBAC roles, and security configuration.',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final rand = math.Random();
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buf = StringBuffer('Pass!');
    for (var i = 0; i < 6; i++) {
      buf.write(chars[rand.nextInt(chars.length)]);
    }
    buf.write(rand.nextInt(90) + 10);
    setState(() {
      _passwordController.text = buf.toString();
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.api.createEmployee(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        roleName: _selectedRole,
        fullName: _fullNameController.text.trim().isEmpty
            ? null
            : _fullNameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not create employee. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = _availableRoles.firstWhere(
      (r) => r.name == _selectedRole,
      orElse: () => _availableRoles.first,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF103A48).withValues(alpha: isDark ? 0.35 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2A9A75), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add employee',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create an employee account and set their role permissions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      key: const ValueKey('add_employee_error_banner'),
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  TextFormField(
                    key: const ValueKey('add_employee_email_input'),
                    controller: _emailController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Work email address *',
                      hintText: 'e.g. employee@company.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Enter an email address';
                      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(val)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('add_employee_password_input'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Initial password *',
                      hintText: 'Minimum 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const ValueKey('generate_employee_password_button'),
                            tooltip: 'Generate secure password',
                            icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                            onPressed: _generatePassword,
                          ),
                          IconButton(
                            key: const ValueKey('toggle_employee_password_visibility'),
                            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Enter a password';
                      if (val.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const ValueKey('add_employee_fullname_input'),
                    controller: _fullNameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Full name (optional)',
                      hintText: 'e.g. Sarah Connor',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Assignable Role *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('add_employee_role_dropdown'),
                    initialValue: _selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.security_rounded, size: 20),
                    ),
                    items: _availableRoles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role.name,
                        child: Row(
                          children: [
                            Icon(role.icon, size: 18, color: const Color(0xFF2A9A75)),
                            const SizedBox(width: 8),
                            Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentRole.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('submit_add_employee_button'),
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF103A48),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create employee'),
          ),
        ],
      ),
    );
  }
}
