import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const WorknestApp());
}

class WorknestApp extends StatefulWidget {
  const WorknestApp({super.key});

  @override
  State<WorknestApp> createState() => _WorknestAppState();
}

class _WorknestAppState extends State<WorknestApp> {
  bool _authenticated = false;

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
      home: _authenticated
          ? DashboardPage(
              onLogout: () => setState(() => _authenticated = false),
            )
          : LoginPage(
              onAuthenticated: () => setState(() => _authenticated = true),
            ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onAuthenticated();
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
                          onPressed: () {},
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
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
  const DashboardPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  _Role _role = _Role.hrManager;
  bool _isClockedIn = true;
  bool _breakStarted = false;
  Duration _worked = const Duration(hours: 6, minutes: 24, seconds: 18);
  Timer? _timer;

  final _allNavigation = const [
    _NavItem(Icons.grid_view_rounded, 'Overview', _Permission.viewDashboard),
    _NavItem(Icons.people_alt_outlined, 'Team', _Permission.manageTeam),
    _NavItem(
      Icons.event_available_outlined,
      'Attendance',
      _Permission.manageAttendance,
    ),
    _NavItem(Icons.receipt_long_outlined, 'Time off', _Permission.manageLeave),
    _NavItem(Icons.bar_chart_outlined, 'Reports', _Permission.manageReports),
  ];

  List<_NavItem> get _navigation => _allNavigation
      .where((item) => _RolePolicy.can(_role, item.permission))
      .toList();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isClockedIn && !_breakStarted && mounted) {
        setState(() => _worked += const Duration(seconds: 1));
      }
    });
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
                    onRoleChanged: (role) => setState(() {
                      _role = role;
                      _selectedIndex = 0;
                    }),
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
                  onRoleChanged: (role) => setState(() {
                    _role = role;
                    _selectedIndex = 0;
                  }),
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
                          child: _selectedIndex == 0
                              ? _DashboardContent(
                                  compact: compact,
                                  worked: _formatDuration(_worked),
                                  isClockedIn: _isClockedIn,
                                  breakStarted: _breakStarted,
                                  onClockToggle: () {
                                    setState(
                                      () => _isClockedIn = !_isClockedIn,
                                    );
                                    _showMessage(
                                      _isClockedIn
                                          ? 'You are clocked in.'
                                          : 'You are clocked out.',
                                    );
                                  },
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
                                  onAction: _showMessage,
                                )
                              : _selectedIndex == 1
                              ? _TeamContent(onAction: _showMessage)
                              : _selectedIndex == 2
                              ? _AttendanceContent(onAction: _showMessage)
                              : _selectedIndex == 3
                              ? _TimeOffContent(onAction: _showMessage)
                              : _selectedIndex == 4
                              ? _ReportsContent(onAction: _showMessage)
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
    required this.onRoleChanged,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final _Role role;
  final VoidCallback onLogout;
  final ValueChanged<_Role> onRoleChanged;
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
                Text(
                  'PeopleHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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
          PopupMenuButton<_Role>(
            initialValue: role,
            onSelected: onRoleChanged,
            tooltip: 'Switch role',
            color: Colors.white,
            itemBuilder: (context) => _Role.values
                .map(
                  (item) => PopupMenuItem(
                    value: item,
                    child: Text(
                      item.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            child: Padding(
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
          ),
          if (_RolePolicy.can(role, _Permission.manageCompany))
            _SidebarItem(
              item: const _NavItem(
                Icons.settings_outlined,
                'Settings',
                _Permission.manageCompany,
              ),
              onTap: () {},
            ),
          _SidebarItem(
            item: const _NavItem(
              Icons.logout_rounded,
              'Sign out',
              _Permission.selfService,
            ),
            onTap: onLogout,
          ),
          _SidebarItem(
            item: const _NavItem(
              Icons.help_outline_rounded,
              'Help center',
              _Permission.selfService,
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
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFB6C8CD),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
    required this.isClockedIn,
    required this.breakStarted,
    required this.onClockToggle,
    required this.onBreakToggle,
    required this.onAction,
  });

  final bool compact;
  final String worked;
  final bool isClockedIn;
  final bool breakStarted;
  final VoidCallback onClockToggle;
  final VoidCallback onBreakToggle;
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
                    isClockedIn: isClockedIn,
                    breakStarted: breakStarted,
                    onClockToggle: onClockToggle,
                    onBreakToggle: onBreakToggle,
                  ),
                  const SizedBox(height: 18),
                  _AttendanceCard(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _WorkingTimeCard(
                      worked: worked,
                      isClockedIn: isClockedIn,
                      breakStarted: breakStarted,
                      onClockToggle: onClockToggle,
                      onBreakToggle: onBreakToggle,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(flex: 2, child: _AttendanceCard()),
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

class _TeamContent extends StatelessWidget {
  const _TeamContent({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 26),
        const _MetricGrid(
          children: [
            _MetricCard(
              label: 'Present today',
              value: '112',
              note: 'out of 124 employees',
              progress: 0.90,
              color: Color(0xFFDDF6EB),
            ),
            _MetricCard(
              label: 'On leave today',
              value: '8',
              note: '6.5% of your team',
              progress: 0.35,
              color: Colors.white,
            ),
            _MetricCard(
              label: 'Late arrivals',
              value: '4',
              note: 'Needs attention',
              progress: 0.20,
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final calendar = const _AttendanceCalendar();
            final requests = _RequestsToReview(onAction: onAction);
            return compact
                ? Column(
                    children: [calendar, const SizedBox(height: 18), requests],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: calendar),
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

class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar();

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  _CalendarDay _day(int day) {
    final future = day > 18;
    if (future) {
      final leave = switch (day) {
        20 => const ['Ava Thompson', 'Maya Chen'],
        24 => const ['Noah Williams'],
        _ => <String>[],
      };
      return _CalendarDay(day: day, leave: leave);
    }

    final present = switch (day) {
      1 ||
      2 ||
      3 ||
      4 ||
      5 ||
      6 ||
      9 ||
      10 ||
      11 ||
      12 ||
      13 ||
      16 ||
      17 ||
      18 => const ['Maya Chen', 'Noah Williams', 'Liam Patel'],
      _ => const ['Maya Chen', 'Liam Patel'],
    };
    final absent = day == 7 || day == 14
        ? const ['Liam Patel']
        : const <String>[];
    final leave = day == 12 ? const ['Ava Thompson'] : const <String>[];
    return _CalendarDay(
      day: day,
      present: present,
      absent: absent,
      leave: leave,
    );
  }

  void _showDetails(BuildContext context, _CalendarDay data) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('November ${data.day}, 2026'),
        content: SizedBox(
          width: 340,
          child: data.hasStatus
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.present.isNotEmpty)
                      _StatusDetails(
                        label: 'Present',
                        color: const Color(0xFF55B89D),
                        names: data.present,
                      ),
                    if (data.absent.isNotEmpty)
                      _StatusDetails(
                        label: 'Absent',
                        color: const Color(0xFFD97986),
                        names: data.absent,
                      ),
                    if (data.leave.isNotEmpty)
                      _StatusDetails(
                        label: 'Leave',
                        color: const Color(0xFFE7C46A),
                        names: data.leave,
                      ),
                  ],
                )
              : const Text(
                  'No attendance record. Future dates show approved leave only.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(30, (index) => index + 1);
    return _Panel(
      title: 'Attendance calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'November 2026',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF41555D),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: _weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA8AD),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              if (index >= dates.length) return const SizedBox.shrink();
              final data = _day(dates[index]);
              final details = data.tooltip;
              return Tooltip(
                message: details,
                waitDuration: const Duration(milliseconds: 250),
                child: InkWell(
                  onTap: () => _showDetails(context, data),
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: data.day == 18
                            ? const Color(0xFFDDF6EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: data.hasStatus
                              ? const Color(0xFFE1E9EB)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${data.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: data.day == 18
                                  ? const Color(0xFF2A9A75)
                                  : const Color(0xFF667980),
                              fontWeight: data.day == 18
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          if (data.hasStatus)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (data.present.isNotEmpty)
                                  const _StatusDot(color: Color(0xFF55B89D)),
                                if (data.absent.isNotEmpty)
                                  const _StatusDot(color: Color(0xFFD97986)),
                                if (data.leave.isNotEmpty)
                                  const _StatusDot(color: Color(0xFFE7C46A)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            children: [
              _Legend(color: Color(0xFF55B89D), label: 'Present'),
              _Legend(color: Color(0xFFD97986), label: 'Absent'),
              _Legend(color: Color(0xFFE7C46A), label: 'Leave'),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Hover a date for names. Click or tap for full day details.',
            style: TextStyle(fontSize: 9, color: Color(0xFF8A999E)),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay {
  const _CalendarDay({
    required this.day,
    this.present = const [],
    this.absent = const [],
    this.leave = const [],
  });
  final int day;
  final List<String> present;
  final List<String> absent;
  final List<String> leave;
  bool get hasStatus =>
      present.isNotEmpty || absent.isNotEmpty || leave.isNotEmpty;
  String get tooltip {
    final sections = <String>[];
    if (present.isNotEmpty) sections.add('Present: ${present.join(', ')}');
    if (absent.isNotEmpty) sections.add('Absent: ${absent.join(', ')}');
    if (leave.isNotEmpty) sections.add('Leave: ${leave.join(', ')}');
    return sections.isEmpty ? 'No attendance record' : sections.join('\n');
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _StatusDetails extends StatelessWidget {
  const _StatusDetails({
    required this.label,
    required this.color,
    required this.names,
  });
  final String label;
  final Color color;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            names.join(', '),
            style: const TextStyle(fontSize: 12, color: Color(0xFF60717A)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF788A90)),
        ),
      ],
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
    required this.isClockedIn,
    required this.breakStarted,
    required this.onClockToggle,
    required this.onBreakToggle,
  });

  final String worked;
  final bool isClockedIn;
  final bool breakStarted;
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
            isClockedIn
                ? 'Clocked in at 8:00 AM • Remote'
                : 'Your workday is paused',
            style: const TextStyle(color: Color(0xFFA8C1C7), fontSize: 11),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.78,
              minHeight: 4,
              backgroundColor: Color(0xFF315C68),
              color: Color(0xFF6DDBC5),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '6h 24m worked',
                style: TextStyle(color: Color(0xFFA8C1C7), fontSize: 10),
              ),
              Text(
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
                icon: Icons.pause_rounded,
                label: 'Take a break',
                onPressed: onBreakToggle,
                outlined: true,
              ),
              _ActionButton(
                icon: isClockedIn ? Icons.logout_rounded : Icons.login_rounded,
                label: isClockedIn ? 'Clock out' : 'Clock in',
                onPressed: onClockToggle,
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
  final VoidCallback onPressed;
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
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: "Today's attendance",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoLine(label: 'Check-in', value: '8:00 AM'),
          const _InfoLine(label: 'Check-out', value: '--'),
          const _InfoLine(label: 'Break time', value: '30 minutes'),
          const _InfoLine(
            label: 'Status',
            value: 'On time',
            valueColor: Color(0xFF2A9A75),
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Your shift: 9:00 AM – 5:30 PM',
              style: TextStyle(fontSize: 10, color: Color(0xFF667980)),
            ),
          ),
        ],
      ),
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

class _AttendanceContent extends StatelessWidget {
  const _AttendanceContent({required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return _Workspace(
      title: 'Attendance',
      subtitle: 'Monitor today’s attendance and working hours.',
      action: FilledButton.icon(
        onPressed: () => onAction('Attendance record correction opened.'),
        icon: const Icon(Icons.edit_calendar_outlined, size: 16),
        label: const Text('Correct record'),
      ),
      children: [
        const _SummaryRow(
          items: [
            _SummaryItem('Present', '112', Color(0xFFDDF6EB)),
            _SummaryItem('Late', '4', Color(0xFFFFF3D6)),
            _SummaryItem('Absent', '3', Color(0xFFFFE5E8)),
            _SummaryItem('On leave', '8', Color(0xFFE7EFFD)),
          ],
        ),
        const SizedBox(height: 18),
        _Panel(
          title: 'Today’s attendance',
          trailing: OutlinedButton.icon(
            onPressed: () => onAction('Attendance export prepared.'),
            icon: const Icon(Icons.download_outlined, size: 15),
            label: const Text('Export', style: TextStyle(fontSize: 11)),
          ),
          child: const _EmployeeTable(
            rows: [
              ['Maya Chen', 'Engineering', '8:54 AM', 'Present', 'On time'],
              ['Noah Williams', 'Design', '9:18 AM', 'Present', 'Late'],
              ['Ava Thompson', 'Product', 'On leave', 'Leave', 'Approved'],
              ['Liam Patel', 'Sales', '—', 'Absent', 'Needs review'],
            ],
          ),
        ),
      ],
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
  const _NavItem(this.icon, this.label, this.permission);
  final IconData icon;
  final String label;
  final _Permission permission;
}
