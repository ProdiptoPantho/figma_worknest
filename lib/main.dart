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
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

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
      ),
      home: _session != null
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F9),
      body: Stack(
        children: [
          const _AuthBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
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
                              color: Colors.white,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            const Row(
              children: [
                Icon(Icons.hub_rounded, color: Color(0xFF59CDB6), size: 26),
                SizedBox(width: 9),
                Text(
                  'PeopleHub',
                  style: TextStyle(
                    color: Color(0xFF103A48),
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
                color: const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SECURE SIGN IN',
                style: TextStyle(
                  color: Color(0xFF2A7C68),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Welcome back',
            style: TextStyle(
              color: Color(0xFF103A48),
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to your secure HR workspace.',
            style: TextStyle(color: Color(0xFF83939A), fontSize: 12),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Work email',
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
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
            decoration: InputDecoration(
              labelText: 'Password',
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
              child: const Text('Forgot password?'),
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
                backgroundColor: const Color(0xFF103A48),
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
              color: const Color(0xFFF5F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4ECEE)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: Color(0xFF2A9A75),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Protected by role-based access. Your session is kept in memory and cleared on logout.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A8C92),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent_rounded,
                size: 13,
                color: Color(0xFF9AA9AE),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'No account yet? Ask your HR administrator for an invite.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF9AA9AE)),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: const [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hub_rounded, size: 15, color: Color(0xFF7FA9A2)),
                SizedBox(width: 6),
                Text(
                  'PeopleHub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF44605F),
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(width: 9),
                Text(
                  '© 2026 · All rights reserved',
                  style: TextStyle(fontSize: 9.5, color: Color(0xFF9AA9AE)),
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
                ),
                _FooterTag(
                  icon: Icons.shield_outlined,
                  label: 'Role-based access',
                ),
                _FooterTag(icon: Icons.bolt_rounded, label: 'Built for teams'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterTag extends StatelessWidget {
  const _FooterTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(170),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDFEAEC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF5E8B85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E8388),
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
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDF6F6), Color(0xFFF4F8FA), Color(0xFFE8F1F6)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: _softCircle(340, const Color(0x3359CDB6)),
            ),
            Positioned(
              bottom: -150,
              right: -80,
              child: _softCircle(420, const Color(0x223568D5)),
            ),
            Positioned(
              top: 80,
              right: 120,
              child: _softCircle(120, const Color(0x1F93E8D8)),
            ),
            Positioned(
              left: -60,
              bottom: 110,
              child: _softCircle(210, const Color(0x1F59CDB6)),
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
                    color: const Color(0x1F2A7C68),
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
                    color: const Color(0x1A3568D5),
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
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(205),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE3EDEE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14103A48),
              blurRadius: 18,
              offset: Offset(0, 7),
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
              if (!compact)
                _Sidebar(
                  items: _navigation,
                  selectedIndex: _selectedIndex,
                  role: _role,
                  onLogout: widget.onLogout,
                  onToggleTheme: widget.onToggleTheme,
                  isDark: widget.isDark,
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
                                  onAction: _showMessage,
                                )
                              : _navigation[_selectedIndex].page ==
                                    _NavPage.employees
                              ? _EmployeeManagementContent(
                                  api: widget.api,
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
    required this.items,
    required this.selectedIndex,
    required this.role,
    required this.onLogout,
    required this.onSelected,
    this.onToggleTheme,
    this.isDark = false,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final _Role role;
  final VoidCallback onLogout;
  final ValueChanged<int> onSelected;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      color: isDark ? const Color(0xFF0C1921) : const Color(0xFF103A48),
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
          if (onToggleTheme != null)
            _SidebarItem(
              item: _NavItem(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                isDark ? 'Light theme' : 'Dark theme',
                _Permission.selfService,
                _NavPage.overview,
              ),
              onTap: onToggleTheme!,
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
    final bg = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.15), theme.cardColor)
        : color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF708087),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF103A48),
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
        builder: (ctx) => AlertDialog(
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF103A48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${record.leaveType}  •  $dateRange  •  '
                '${record.totalDays} ${record.totalDays == 1 ? "day" : "days"}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF60717A)),
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
      if (confirmed != true) return;
      setState(() => _busy = true);
      try {
        await widget.api.approveLeaveRequest(record.id);
        widget.onAction('Leave request approved.');
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
      // UX 2 + Bug 5: Comment dialog for rejection
      final commentController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Reject leave?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.userEmail}  •  ${record.leaveType}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF60717A)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection (optional)',
                  hintText: 'Let the employee know why...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                backgroundColor: const Color(0xFFB05B68),
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      final comment = commentController.text.trim();
      commentController.dispose();
      if (confirmed != true) return;
      setState(() => _busy = true);
      try {
        await widget.api.rejectLeaveRequest(
          record.id,
          comment: comment.isEmpty ? null : comment,
        );
        widget.onAction('Leave request rejected.');
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
                    columns: const ['Type', 'Dates', 'Days', 'Status', 'Note']
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
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF7A8C92),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initial = request.userEmail.isEmpty
        ? '?'
        : request.userEmail.substring(0, 1).toUpperCase();
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
                      request.userEmail.isEmpty
                          ? 'Unknown employee'
                          : request.userEmail,
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
            Text(
              request.reason!,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF60717A),
                height: 1.4,
              ),
            ),
          ],
          if (onApprove != null && onReject != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton(
                  onPressed: busy ? null : onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9A75),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB05B68),
                    side: const BorderSide(color: Color(0xFFE8BBC2)),
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 10.5)),
                ),
              ],
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
  bool _loadingTypes = true;
  bool _busy = false;
  String? _error;

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
    if (!_formKey.currentState!.validate()) return;
    final type = _type;
    final start = _start;
    final end = _end;
    if (type == null) {
      setState(() => _error = 'Choose a leave type.');
      return;
    }
    if (start == null || end == null) {
      setState(() => _error = 'Choose the leave dates.');
      return;
    }
    if (_days < 1) {
      setState(() => _error = 'Select at least one working day (Mon–Fri).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rawReason = _reasonController.text.trim();
      final reason =
          rawReason.isNotEmpty ? rawReason : '${type.leaveType} leave';
      await widget.api.requestLeave(
        leaveType: type.leaveType,
        startDate: start,
        endDate: end,
        reason: reason,
      );
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
    return AlertDialog(
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
                      const Text(
                        'Leave type',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF41555D),
                        ),
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
                    TextFormField(
                      controller: _reasonController,
                      enabled: !_busy,
                      maxLines: 2,
                      maxLength: 500,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                        hintText: 'Add context for your reviewer',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                      onFieldSubmitted: (_) {
                        if (!_busy) _submit();
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB05B68),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null ? 'Select date' : _shortDate(value!),
          style: TextStyle(
            fontSize: 12,
            color: value == null
                ? const Color(0xFF9AA7AC)
                : (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF41555D)),
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
  });

  final HrmApiClient api;
  final ValueChanged<String> onAction;

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
        onPressed: () => widget.onAction('Account invitations are managed via HR registration.'),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
        label: const Text('Invite employee'),
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
                            columns: const ['Employee', 'Roles', 'Status', 'Account ID']
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
                          ? Color.alphaBlend(item.color.withValues(alpha: 0.15), Theme.of(context).cardColor)
                          : item.color,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Theme.of(context).dividerColor),
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
}

class _TaskManagerContent extends StatefulWidget {
  const _TaskManagerContent({
    required this.session,
    required this.onAction,
  });

  final AuthSession session;
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
    ),
  ];

  TaskState? _statusFilter;
  TaskPriority? _priorityFilter;
  String _categoryFilter = 'All';
  String _search = '';

  int get _totalCount => _tasks.length;
  int get _completedCount => _tasks.where((t) => t.status == TaskState.done).length;
  int get _inProgressCount => _tasks.where((t) => t.status == TaskState.inProgress).length;
  int get _highPriorityCount => _tasks.where((t) => t.priority == TaskPriority.high && t.status != TaskState.done).length;

  List<EmployeeTask> get _filteredTasks {
    return _tasks.where((task) {
      if (_statusFilter != null && task.status != _statusFilter) return false;
      if (_priorityFilter != null && task.priority != _priorityFilter) return false;
      if (_categoryFilter != 'All' && task.category != _categoryFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        final matchCat = task.category.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchCat) return false;
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

  Future<void> _openCreateTask() async {
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
    final tasks = _filteredTasks;
    final categories = ['All', 'Operations', 'Compliance', 'Security', 'Goals', 'Profile'];

    return _Workspace(
      title: 'Task manager',
      subtitle: 'Organize work, track deliverables, and hit your milestones on time.',
      action: FilledButton.icon(
        onPressed: _openCreateTask,
        icon: const Icon(Icons.add_task_rounded, size: 16),
        label: const Text('New task'),
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
          title: 'My active tasks',
          trailing: SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
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
              const SizedBox(height: 16),
              if (tasks.isEmpty)
                _EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'No tasks found',
                  message: _search.isNotEmpty || _statusFilter != null
                      ? 'No tasks match your current filter.'
                      : 'You are all clear! Add a new task to stay organized.',
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
                          color: isDone ? const Color(0xFF8A999E) : const Color(0xFF103A48),
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
                      color: isDone ? const Color(0xFFA8B5BA) : const Color(0xFF60717A),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.category,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A6D73),
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

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: const Row(
        children: [
          Icon(Icons.add_task_rounded, color: Color(0xFF2A9A75), size: 22),
          SizedBox(width: 8),
          Text(
            'Create task',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF103A48),
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
                ),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF41555D))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories
                      .map((cat) => ChoiceChip(
                            label: Text(cat, style: TextStyle(fontSize: 10, color: _category == cat ? Colors.white : const Color(0xFF41555D))),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
                            selectedColor: const Color(0xFF103A48),
                            backgroundColor: const Color(0xFFF3F7F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            showCheckmark: false,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF41555D))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values
                      .map((p) => ChoiceChip(
                            label: Text(p.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _priority == p ? Colors.white : p.color)),
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
                        color: _dueDate == null ? const Color(0xFF8A999E) : const Color(0xFF41555D),
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
    );
  }
}
