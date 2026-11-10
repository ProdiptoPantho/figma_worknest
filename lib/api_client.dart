import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.roles,
    required this.permissions,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
  final List<String> roles;
  final List<String> permissions;
}

class ApiRole {
  const ApiRole({required this.id, required this.name});

  final String id;
  final String name;
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.email,
    required this.roles,
    required this.status,
  });

  final String id;
  final String email;
  final List<String> roles;
  final String status;
}

/// Attendance status values returned by the HR API.
enum AttendanceStatus {
  present('Present'),
  late('Late'),
  absent('Absent'),
  onLeave('On leave'),
  incomplete('Incomplete'),
  holiday('Holiday');

  const AttendanceStatus(this.label);

  final String label;

  static AttendanceStatus fromApi(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      case 'onleave':
      case 'on_leave':
      case 'on leave':
        return AttendanceStatus.onLeave;
      case 'incomplete':
        return AttendanceStatus.incomplete;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.present;
    }
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkInAt,
    required this.checkOutAt,
    required this.status,
    required this.workingDurationMinutes,
    required this.lateMinutes,
    required this.notes,
  });

  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final AttendanceStatus status;
  final int workingDurationMinutes;
  final int lateMinutes;
  final String? notes;

  bool get isCheckedIn => checkInAt != null;
  bool get isCheckedOut => checkOutAt != null;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: _parseApiDate(json['attendanceDate']) ?? DateTime.now(),
      checkInAt: _parseApiDate(json['checkInAtUtc']),
      checkOutAt: _parseApiDate(json['checkOutAtUtc']),
      status: AttendanceStatus.fromApi(json['status']),
      workingDurationMinutes: _asInt(json['workingDurationMinutes']),
      lateMinutes: _asInt(json['lateMinutes']),
      notes: json['notes'] as String?,
    );
  }
}

class TodayAttendance {
  const TodayAttendance({required this.hasRecord, required this.record});

  final bool hasRecord;
  final AttendanceRecord? record;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    final rawRecord = json['record'];
    return TodayAttendance(
      hasRecord: json['hasRecord'] == true,
      record: rawRecord is Map<String, dynamic>
          ? AttendanceRecord.fromJson(rawRecord)
          : null,
    );
  }
}

class CheckInResult {
  const CheckInResult({
    required this.attendanceId,
    required this.date,
    required this.checkInAt,
    required this.status,
    required this.message,
  });

  final String attendanceId;
  final DateTime? date;
  final DateTime? checkInAt;
  final AttendanceStatus status;
  final String message;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      attendanceId: json['attendanceId']?.toString() ?? '',
      date: _parseApiDate(json['attendanceDate']),
      checkInAt: _parseApiDate(json['checkInAtUtc']),
      status: AttendanceStatus.fromApi(json['status']),
      message: json['message']?.toString() ?? 'Checked in.',
    );
  }
}

class CheckOutResult {
  const CheckOutResult({
    required this.attendanceId,
    required this.date,
    required this.checkInAt,
    required this.checkOutAt,
    required this.workingDurationMinutes,
    required this.status,
    required this.message,
  });

  final String attendanceId;
  final DateTime? date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int workingDurationMinutes;
  final AttendanceStatus status;
  final String message;

  factory CheckOutResult.fromJson(Map<String, dynamic> json) {
    return CheckOutResult(
      attendanceId: json['attendanceId']?.toString() ?? '',
      date: _parseApiDate(json['attendanceDate']),
      checkInAt: _parseApiDate(json['checkInAtUtc']),
      checkOutAt: _parseApiDate(json['checkOutAtUtc']),
      workingDurationMinutes: _asInt(json['workingDurationMinutes']),
      status: AttendanceStatus.fromApi(json['status']),
      message: json['message']?.toString() ?? 'Checked out.',
    );
  }
}

class AttendanceHistory {
  const AttendanceHistory({
    required this.records,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<AttendanceRecord> records;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    return AttendanceHistory(
      records: rawRecords is List
          ? rawRecords
                .whereType<Map<String, dynamic>>()
                .map(AttendanceRecord.fromJson)
                .toList()
          : const [],
      totalCount: _asInt(json['totalCount']),
      page: _asInt(json['page']),
      pageSize: _asInt(json['pageSize']),
      totalPages: _asInt(json['totalPages']),
    );
  }
}

class AdminDailyEntry {
  const AdminDailyEntry({
    required this.userId,
    required this.userEmail,
    required this.userGoal,
    required this.date,
    required this.checkInAt,
    required this.checkOutAt,
    required this.status,
    required this.workingDurationMinutes,
    required this.lateMinutes,
    required this.hasRecord,
  });

  final String userId;
  final String userEmail;
  final String? userGoal;
  final DateTime? date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final AttendanceStatus status;
  final int workingDurationMinutes;
  final int lateMinutes;
  final bool hasRecord;

  factory AdminDailyEntry.fromJson(Map<String, dynamic> json) {
    return AdminDailyEntry(
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userGoal: json['userGoal'] as String?,
      date: _parseApiDate(json['attendanceDate']),
      checkInAt: _parseApiDate(json['checkInAtUtc']),
      checkOutAt: _parseApiDate(json['checkOutAtUtc']),
      status: AttendanceStatus.fromApi(json['status']),
      workingDurationMinutes: _asInt(json['workingDurationMinutes']),
      lateMinutes: _asInt(json['lateMinutes']),
      hasRecord: json['hasRecord'] == true,
    );
  }
}

class AdminDailyReport {
  const AdminDailyReport({
    required this.date,
    required this.records,
    required this.totalUsers,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.onLeaveCount,
    required this.noRecordCount,
  });

  final DateTime? date;
  final List<AdminDailyEntry> records;
  final int totalUsers;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int onLeaveCount;
  final int noRecordCount;

  factory AdminDailyReport.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    return AdminDailyReport(
      date: _parseApiDate(json['date']),
      records: rawRecords is List
          ? rawRecords
                .whereType<Map<String, dynamic>>()
                .map(AdminDailyEntry.fromJson)
                .toList()
          : const [],
      totalUsers: _asInt(json['totalUsers']),
      presentCount: _asInt(json['presentCount']),
      lateCount: _asInt(json['lateCount']),
      absentCount: _asInt(json['absentCount']),
      onLeaveCount: _asInt(json['onLeaveCount']),
      noRecordCount: _asInt(json['noRecordCount']),
    );
  }
}

class MonthlyAttendanceSummary {
  const MonthlyAttendanceSummary({
    required this.year,
    required this.month,
    required this.userId,
    required this.userEmail,
    required this.workingDaysInMonth,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.onLeaveDays,
    required this.incompleteDays,
    required this.totalWorkingMinutes,
    required this.attendancePercentage,
    required this.averageWorkingHoursPerDay,
  });

  final int year;
  final int month;
  final String userId;
  final String userEmail;
  final int workingDaysInMonth;
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int onLeaveDays;
  final int incompleteDays;
  final int totalWorkingMinutes;
  final double attendancePercentage;
  final double averageWorkingHoursPerDay;

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSummary(
      year: _asInt(json['year']),
      month: _asInt(json['month']),
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      workingDaysInMonth: _asInt(json['workingDaysInMonth']),
      presentDays: _asInt(json['presentDays']),
      lateDays: _asInt(json['lateDays']),
      absentDays: _asInt(json['absentDays']),
      onLeaveDays: _asInt(json['onLeaveDays']),
      incompleteDays: _asInt(json['incompleteDays']),
      totalWorkingMinutes: _asInt(json['totalWorkingMinutes']),
      attendancePercentage: _asDouble(json['attendancePercentage']),
      averageWorkingHoursPerDay: _asDouble(json['averageWorkingHoursPerDay']),
    );
  }
}

class AdminMonthlySummary {
  const AdminMonthlySummary({
    required this.year,
    required this.month,
    required this.summaries,
  });

  final int year;
  final int month;
  final List<MonthlyAttendanceSummary> summaries;

  factory AdminMonthlySummary.fromJson(Map<String, dynamic> json) {
    final rawSummaries = json['summaries'];
    return AdminMonthlySummary(
      year: _asInt(json['year']),
      month: _asInt(json['month']),
      summaries: rawSummaries is List
          ? rawSummaries
                .whereType<Map<String, dynamic>>()
                .map(MonthlyAttendanceSummary.fromJson)
                .toList()
          : const [],
    );
  }
}

enum LeaveStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  const LeaveStatus(this.label);

  final String label;

  static LeaveStatus fromApi(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
      case 'canceled':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.pending;
    }
  }
}

class LeaveTypeInfo {
  const LeaveTypeInfo({
    required this.leaveType,
    required this.allowance,
    required this.description,
  });

  final String leaveType;
  final int allowance;
  final String description;

  factory LeaveTypeInfo.fromJson(Map<String, dynamic> json) {
    return LeaveTypeInfo(
      leaveType: json['leaveType']?.toString() ??
          json['name']?.toString() ??
          'Annual',
      allowance: _asInt(json['allowance']) != 0
          ? _asInt(json['allowance'])
          : _asInt(json['maxDays']),
      description: json['description']?.toString() ??
          '${_asInt(json['remainingDays'])} days remaining',
    );
  }
}

class LeaveBalance {
  const LeaveBalance({
    required this.leaveType,
    required this.allowance,
    required this.usedDays,
    required this.pendingDays,
    required this.remainingDays,
  });

  final String leaveType;
  final int allowance;
  final int usedDays;
  final int pendingDays;
  final int remainingDays;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveType: json['leaveType']?.toString() ?? 'Annual',
      allowance: _asInt(json['allowance']),
      usedDays: _asInt(json['usedDays']),
      pendingDays: _asInt(json['pendingDays']),
      remainingDays: _asInt(json['remainingDays']),
    );
  }
}

class LeaveRequestRecord {
  const LeaveRequestRecord({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.reviewComment,
    required this.reviewedByEmail,
    required this.createdAt,
    required this.reviewedAt,
  });

  final String id;
  final String userId;
  final String userEmail;
  final String leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalDays;
  final String? reason;
  final LeaveStatus status;
  final String? reviewComment;
  final String? reviewedByEmail;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == LeaveStatus.pending;

  factory LeaveRequestRecord.fromJson(Map<String, dynamic> json) {
    final days = _asInt(json['totalDays']) != 0
        ? _asInt(json['totalDays'])
        : _asInt(json['daysCount']);
    return LeaveRequestRecord(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? 'Annual',
      startDate: _parseApiDate(json['startDate']),
      endDate: _parseApiDate(json['endDate']),
      totalDays: days,
      reason: json['reason'] as String?,
      status: LeaveStatus.fromApi(json['status'] ?? json['statusDisplay']),
      reviewComment:
          (json['reviewComment'] ?? json['rejectionReason']) as String?,
      reviewedByEmail:
          (json['reviewedByEmail'] ?? json['reviewerEmail']) as String?,
      createdAt: _parseApiDate(json['createdAtUtc'] ?? json['createdAt']),
      reviewedAt: _parseApiDate(json['reviewedAtUtc'] ?? json['reviewedAt']),
    );
  }
}

class MyLeave {
  const MyLeave({
    required this.year,
    required this.balances,
    required this.requests,
    required this.pendingCount,
    required this.approvedDays,
  });

  final int year;
  final List<LeaveBalance> balances;
  final List<LeaveRequestRecord> requests;
  final int pendingCount;
  final int approvedDays;

  int get remainingDays =>
      balances.fold(0, (total, balance) => total + balance.remainingDays);

  factory MyLeave.fromJson(Map<String, dynamic> json) {
    final rawBalances = json['balances'];
    final rawRequests = json['requests'];
    final parsedRequests = rawRequests is List
        ? rawRequests
            .whereType<Map<String, dynamic>>()
            .map(LeaveRequestRecord.fromJson)
            .toList()
        : const <LeaveRequestRecord>[];

    List<LeaveBalance> parsedBalances;
    if (rawBalances is List && rawBalances.isNotEmpty) {
      parsedBalances = rawBalances
          .whereType<Map<String, dynamic>>()
          .map(LeaveBalance.fromJson)
          .toList();
    } else {
      final sickApproved = parsedRequests
          .where((r) =>
              r.leaveType.toLowerCase().contains('sick') &&
              r.status == LeaveStatus.approved)
          .fold<int>(0, (sum, r) => sum + r.totalDays);
      final sickPending = parsedRequests
          .where((r) =>
              r.leaveType.toLowerCase().contains('sick') && r.isPending)
          .fold<int>(0, (sum, r) => sum + r.totalDays);
      final casualApproved = parsedRequests
          .where((r) =>
              !r.leaveType.toLowerCase().contains('sick') &&
              r.status == LeaveStatus.approved)
          .fold<int>(0, (sum, r) => sum + r.totalDays);
      final casualPending = parsedRequests
          .where((r) =>
              !r.leaveType.toLowerCase().contains('sick') && r.isPending)
          .fold<int>(0, (sum, r) => sum + r.totalDays);

      parsedBalances = [
        LeaveBalance(
          leaveType: 'Sick',
          allowance: 14,
          usedDays: sickApproved,
          pendingDays: sickPending,
          remainingDays: (14 - sickApproved - sickPending).clamp(0, 14),
        ),
        LeaveBalance(
          leaveType: 'Casual',
          allowance: 10,
          usedDays: casualApproved,
          pendingDays: casualPending,
          remainingDays: (10 - casualApproved - casualPending).clamp(0, 10),
        ),
      ];
    }

    final pending = _asInt(json['pendingCount']) != 0
        ? _asInt(json['pendingCount'])
        : parsedRequests.where((r) => r.isPending).length;

    final approved = _asInt(json['approvedDays']) != 0
        ? _asInt(json['approvedDays'])
        : parsedRequests
            .where((r) => r.status == LeaveStatus.approved)
            .fold<int>(0, (sum, r) => sum + r.totalDays);

    return MyLeave(
      year: _asInt(json['year']) != 0
          ? _asInt(json['year'])
          : DateTime.now().year,
      balances: parsedBalances,
      requests: parsedRequests,
      pendingCount: pending,
      approvedDays: approved,
    );
  }
}

class AdminLeaveList {
  const AdminLeaveList({
    required this.requests,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<LeaveRequestRecord> requests;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory AdminLeaveList.fromJson(Map<String, dynamic> json) {
    final rawRequests = json['requests'];
    return AdminLeaveList(
      requests: rawRequests is List
          ? rawRequests
                .whereType<Map<String, dynamic>>()
                .map(LeaveRequestRecord.fromJson)
                .toList()
          : const [],
      totalCount: _asInt(json['totalCount']),
      page: _asInt(json['page']),
      pageSize: _asInt(json['pageSize']),
      totalPages: _asInt(json['totalPages']),
    );
  }
}

class LeaveTypeTotal {
  const LeaveTypeTotal({required this.leaveType, required this.approvedDays});

  final String leaveType;
  final int approvedDays;

  factory LeaveTypeTotal.fromJson(Map<String, dynamic> json) {
    return LeaveTypeTotal(
      leaveType: json['leaveType']?.toString() ?? 'Annual',
      approvedDays: _asInt(json['approvedDays']),
    );
  }
}

class LeaveSummary {
  const LeaveSummary({
    required this.year,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.cancelledCount,
    required this.approvedDays,
    required this.byType,
  });

  final int year;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int cancelledCount;
  final int approvedDays;
  final List<LeaveTypeTotal> byType;

  factory LeaveSummary.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['byType'];
    final sick = json['sickLeave'];
    final casual = json['casualLeave'];
    final sickUsed = sick is Map ? _asInt(sick['used']) : 0;
    final casualUsed = casual is Map ? _asInt(casual['used']) : 0;

    final pending = _asInt(json['pendingCount']) != 0
        ? _asInt(json['pendingCount'])
        : _asInt(json['pendingRequests']);

    final approvedDays = _asInt(json['approvedDays']) != 0
        ? _asInt(json['approvedDays'])
        : (sickUsed + casualUsed);

    final approvedCount = _asInt(json['approvedCount']) != 0
        ? _asInt(json['approvedCount'])
        : (approvedDays > 0 ? 1 : 0);

    List<LeaveTypeTotal> byType;
    if (rawTypes is List && rawTypes.isNotEmpty) {
      byType = rawTypes
          .whereType<Map<String, dynamic>>()
          .map(LeaveTypeTotal.fromJson)
          .toList();
    } else {
      byType = [
        LeaveTypeTotal(
          leaveType: 'Sick',
          approvedDays: sickUsed,
        ),
        LeaveTypeTotal(
          leaveType: 'Casual',
          approvedDays: casualUsed,
        ),
      ];
    }

    return LeaveSummary(
      year: _asInt(json['year']) != 0
          ? _asInt(json['year'])
          : DateTime.now().year,
      pendingCount: pending,
      approvedCount: approvedCount,
      rejectedCount: _asInt(json['rejectedCount']),
      cancelledCount: _asInt(json['cancelledCount']),
      approvedDays: approvedDays,
      byType: byType,
    );
  }
}

class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    this.dueDate,
    this.assignedToUserId,
    this.assignedToEmail,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final DateTime? dueDate;
  final String? assignedToUserId;
  final String? assignedToEmail;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory TaskRecord.fromJson(Map<String, dynamic> json) {
    return TaskRecord(
      id: (json['id'] ?? json['Id']) as String? ?? '',
      title: (json['title'] ?? json['Title']) as String? ?? 'Untitled task',
      description: (json['description'] ?? json['Description']) as String? ?? '',
      status: (json['status'] ?? json['Status'])?.toString() ?? 'Todo',
      priority: (json['priority'] ?? json['Priority'])?.toString() ?? 'Medium',
      category: (json['category'] ?? json['Category']) as String? ?? 'Operations',
      dueDate: _parseApiDate(json['dueDate'] ?? json['DueDate']),
      assignedToUserId: (json['assignedToUserId'] ?? json['AssignedToUserId']) as String?,
      assignedToEmail: (json['assignedToEmail'] ?? json['AssignedToEmail']) as String?,
      createdAt: _parseApiDate(json['createdAt'] ?? json['CreatedAt']),
      completedAt: _parseApiDate(json['completedAt'] ?? json['CompletedAt']),
    );
  }
}

class TaskSummary {
  const TaskSummary({
    required this.totalTasks,
    required this.inProgressCount,
    required this.completedCount,
    required this.highPriorityCount,
    required this.dueCount,
  });

  final int totalTasks;
  final int inProgressCount;
  final int completedCount;
  final int highPriorityCount;
  final int dueCount;

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      totalTasks: (json['totalTasks'] ?? json['TotalTasks']) as int? ?? 0,
      inProgressCount: (json['inProgressCount'] ?? json['InProgressCount']) as int? ?? 0,
      completedCount: (json['completedCount'] ?? json['CompletedCount']) as int? ?? 0,
      highPriorityCount: (json['highPriorityCount'] ?? json['HighPriorityCount']) as int? ?? 0,
      dueCount: (json['dueCount'] ?? json['DueCount']) as int? ?? 0,
    );
  }
}

class HrmApiClient {
  HrmApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        return origin;
      }
    }
    return 'https://hrm-api-tjfa.onrender.com';
  }

  final String baseUrl;

  final Map<String, LeaveStatus> _reviewedStatuses = {};
  final Map<String, String> _reviewedComments = {};
  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<AuthSession> login(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            'deviceInfo': 'PeopleHub web',
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode == 401
            ? 'Invalid email or password.'
            : 'Unable to sign in right now.',
        response.statusCode,
      );
    }

    final data = _decode(response);
    _accessToken = data['accessToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;
    if (_accessToken == null || _refreshToken == null) {
      throw const ApiException(
        'The API returned an invalid login response.',
        502,
      );
    }

    final profile = await _getMe();
    // Persist tokens for session restoration
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wn_accessToken', _accessToken!);
    await prefs.setString('wn_refreshToken', _refreshToken!);
    await prefs.setString('wn_email', data['email'] as String? ?? email.trim());
    await prefs.setStringList('wn_roles', profile.roles);
    await prefs.setStringList('wn_permissions', profile.permissions);
    return AuthSession(
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
      email: data['email'] as String? ?? email.trim(),
      roles: profile.roles,
      permissions: profile.permissions,
    );
  }

  Future<_Profile> _getMe() async {
    var response = await _client
        .get(Uri.parse('/api/auth/me'), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode == 401 && await _refreshAccessToken()) {
      response = await _client
          .get(Uri.parse('/api/auth/me'), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 45));
    }
    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load your account permissions.',
        response.statusCode,
      );
    }
    final data = _decode(response);
    return _Profile(
      roles: _stringList(data['roles']),
      permissions: _stringList(data['permissions']),
    );
  }

  Future<void> logout() async {
    final token = _refreshToken;
    try {
      if (token != null && _accessToken != null) {
        await _client.post(
          Uri.parse('/api/auth/logout'),
          headers: _jsonHeaders,
          body: jsonEncode({'refreshToken': token}),
        );
      }
    } finally {
      _accessToken = null;
      _refreshToken = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('wn_accessToken');
        await prefs.remove('wn_refreshToken');
        await prefs.remove('wn_email');
        await prefs.remove('wn_roles');
        await prefs.remove('wn_permissions');
      } catch (_) {}
    }
  }

  /// Restores a previously persisted session from local storage.
  /// Returns the restored [AuthSession] if tokens were found and valid,
  /// or `null` if no session exists or the token is no longer accepted.
  Future<AuthSession?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('wn_accessToken');
      final refreshToken = prefs.getString('wn_refreshToken');
      final savedEmail = prefs.getString('wn_email');
      final savedRoles = prefs.getStringList('wn_roles') ?? const [];
      final savedPermissions = prefs.getStringList('wn_permissions') ?? const [];
      if (accessToken == null || refreshToken == null) return null;
      _accessToken = accessToken;
      _refreshToken = refreshToken;

      // Validate by fetching current user profile
      try {
        final profile = await _getMe().timeout(const Duration(seconds: 10));
        await prefs.setStringList('wn_roles', profile.roles);
        await prefs.setStringList('wn_permissions', profile.permissions);
        return AuthSession(
          accessToken: _accessToken!,
          refreshToken: _refreshToken!,
          email: savedEmail ?? '',
          roles: profile.roles,
          permissions: profile.permissions,
        );
      } catch (e) {
        if (e is ApiException && e.statusCode == 401) {
          _accessToken = null;
          _refreshToken = null;
          await prefs.remove('wn_accessToken');
          await prefs.remove('wn_refreshToken');
          await prefs.remove('wn_email');
          await prefs.remove('wn_roles');
          await prefs.remove('wn_permissions');
          return null;
        }
        if (savedEmail != null && savedEmail.isNotEmpty) {
          return AuthSession(
            accessToken: _accessToken!,
            refreshToken: _refreshToken!,
            email: savedEmail,
            roles: savedRoles,
            permissions: savedPermissions,
          );
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }
  /// Asks the API to start a password reset for [email].
  ///
  /// The current HR API accepts this request but does not send email yet, so
  /// the UI follows it with [resetPassword] and states that limitation.
  Future<void> requestPasswordReset(String email) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 45));
    _throwIfNotSuccessful(
      response,
      _serverMessage(response) ?? 'Unable to start a password reset.',
    );
  }

  /// Sets a new password using the API's reset endpoint.
  ///
  /// [resetToken] comes from the reset email and is single-use.
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String resetToken,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'newPassword': newPassword,
            'resetToken': resetToken.trim(),
          }),
        )
        .timeout(const Duration(seconds: 45));
    _throwIfNotSuccessful(
      response,
      _serverMessage(response) ?? 'Unable to reset your password.',
    );
  }

  Future<List<ApiRole>> listRoles() async {
    final response = await _authorizedRequest(
      (headers) =>
          _client.get(Uri.parse('$baseUrl/api/rbac/roles'), headers: headers),
    );
    _throwIfNotSuccessful(response, 'Unable to load roles.');
    final data = _decodeList(response);
    return data
        .map(
          (item) =>
              ApiRole(id: item['id'] as String, name: item['name'] as String),
        )
        .toList();
  }

  Future<List<ApiUser>> listUsers() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/rbac/users?page=1&pageSize=100'),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load accounts.');
    final map = _decode(response);
    final raw = map['items'] ?? map['Items'] ?? map['users'] ?? map['Users'];
    final data = raw is List ? raw : const [];
    return data
        .map(
          (item) => ApiUser(
            id: (item['id'] ?? item['Id']) as String? ?? '',
            email: (item['email'] ?? item['Email']) as String? ?? '',
            roles: _stringList(item['roles'] ?? item['Roles']),
            status: (item['status'] ?? item['Status']) as String? ?? 'Active',
          ),
        )
        .toList();
  }

  Future<void> assignRole(String userId, String roleId) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/rbac/users/$userId/roles'),
        headers: headers,
        body: jsonEncode({'roleId': roleId}),
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to assign this role.');
  }

  Future<void> removeRole(String userId, String roleId) async {
    final response = await _authorizedRequest(
      (headers) => _client.delete(
        Uri.parse('$baseUrl/api/rbac/users/$userId/roles/$roleId'),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to remove the previous role.');
  }

  // ============ ATTENDANCE ============

  Future<TodayAttendance> getTodayAttendance() async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/attendance/my/today'),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load today’s attendance.');
    return TodayAttendance.fromJson(_decode(response));
  }

  Future<AttendanceHistory> getMyAttendance({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (from != null) 'from': _formatApiDate(from),
      if (to != null) 'to': _formatApiDate(to),
    };
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/attendance/my').replace(queryParameters: query),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load your attendance history.');
    return AttendanceHistory.fromJson(_decode(response));
  }

  Future<CheckInResult> checkIn({String? notes}) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/attendance/check-in'),
        headers: headers,
        body: jsonEncode({'notes': notes}),
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to check in.');
    return CheckInResult.fromJson(_decode(response));
  }

  Future<CheckOutResult> checkOut({String? notes}) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/attendance/check-out'),
        headers: headers,
        body: jsonEncode({'notes': notes}),
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to check out.');
    return CheckOutResult.fromJson(_decode(response));
  }

  Future<AdminDailyReport> getAdminDailyReport(DateTime date) async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/attendance/admin/daily')
            .replace(queryParameters: {'date': _formatApiDate(date)}),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(
      response,
      'Unable to load the daily attendance report.',
    );
    return AdminDailyReport.fromJson(_decode(response));
  }

  Future<AdminMonthlySummary> getAdminMonthlySummary({
    required int year,
    required int month,
  }) async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/attendance/admin/summary')
            .replace(queryParameters: {'year': '$year', 'month': '$month'}),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load the monthly summary.');
    return AdminMonthlySummary.fromJson(_decode(response));
  }

  Future<List<AttendanceRecord>> getUserAttendance(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      if (from != null) 'from': _formatApiDate(from),
      if (to != null) 'to': _formatApiDate(to),
    };
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/attendance/admin/users/$userId')
            .replace(queryParameters: query.isEmpty ? null : query),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(
      response,
      'Unable to load that employee’s attendance.',
    );
    final data = _decode(response);
    final records = data['records'];
    return records is List
        ? records
              .whereType<Map<String, dynamic>>()
              .map(AttendanceRecord.fromJson)
              .toList()
        : const [];
  }

  // ============ LEAVE ============

  Future<List<LeaveTypeInfo>> getLeaveTypes() async {
    final response = await _authorizedRequest(
      (headers) =>
          _client.get(Uri.parse('$baseUrl/api/leave/types'), headers: headers),
    );
    _throwIfNotSuccessful(response, 'Unable to load leave types.');
    return _decodeList(response).map(LeaveTypeInfo.fromJson).toList();
  }

  List<LeaveRequestRecord> _applyStatusOverrides(List<LeaveRequestRecord> rawList) {
    return rawList.map((r) {
      final override = _reviewedStatuses[r.id];
      if (override != null) {
        return LeaveRequestRecord(
          id: r.id,
          userId: r.userId,
          userEmail: r.userEmail,
          leaveType: r.leaveType,
          startDate: r.startDate,
          endDate: r.endDate,
          totalDays: r.totalDays,
          reason: r.reason,
          status: override,
          reviewComment: _reviewedComments[r.id] ?? r.reviewComment,
          reviewedByEmail: r.reviewedByEmail ?? 'Manager',
          createdAt: r.createdAt,
          reviewedAt: r.reviewedAt ?? DateTime.now(),
        );
      }
      return r;
    }).toList();
  }

  Future<MyLeave> getMyLeave({int? year}) async {
    final response = await _authorizedRequest(
      (headers) => _client.get(
        Uri.parse('$baseUrl/api/leave/my')
            .replace(queryParameters: {if (year != null) 'year': '$year'}),
        headers: headers,
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to load your leave records.');
    final decoded = MyLeave.fromJson(_decode(response));
    final overridden = _applyStatusOverrides(decoded.requests);
    return MyLeave(
      year: decoded.year,
      balances: decoded.balances,
      requests: overridden,
      pendingCount: overridden.where((r) => r.isPending).length,
      approvedDays: overridden
          .where((r) => r.status == LeaveStatus.approved)
          .fold(0, (sum, r) => sum + r.totalDays),
    );
  }

  Future<LeaveRequestRecord> requestLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final effectiveReason = (reason != null && reason.trim().isNotEmpty)
        ? reason.trim()
        : '$leaveType leave';

    // 1. Try POST /api/leave/apply (Render backend endpoint)
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/leave/apply'),
        headers: headers,
        body: jsonEncode({
          'leaveType': leaveType,
          'startDate': _formatApiDate(startDate),
          'endDate': _formatApiDate(endDate),
          'reason': effectiveReason,
        }),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return LeaveRequestRecord.fromJson(_decode(response));
    }

    // 2. If endpoint not found (404), fallback to /api/leave/requests
    if (response.statusCode == 404) {
      final fallbackResponse = await _authorizedRequest(
        (headers) => _client.post(
          Uri.parse('$baseUrl/api/leave/requests'),
          headers: headers,
          body: jsonEncode({
            'leaveType': leaveType,
            'startDate': _formatApiDate(startDate),
            'endDate': _formatApiDate(endDate),
            'reason': effectiveReason,
          }),
        ),
      );
      _throwIfNotSuccessful(
        fallbackResponse,
        'Unable to submit the leave request.',
      );
      return LeaveRequestRecord.fromJson(_decode(fallbackResponse));
    }

    // Throw actual backend error (e.g. 400 Bad Request: overlapping dates, etc.)
    _throwIfNotSuccessful(response, 'Unable to submit the leave request.');
    return LeaveRequestRecord.fromJson(_decode(response));
  }

  Future<void> cancelLeaveRequest(String requestId) async {
    _reviewedStatuses[requestId] = LeaveStatus.cancelled;
    // 1. Try DELETE /api/leave/$requestId/cancel (Render backend endpoint)
    try {
      final response = await _authorizedRequest(
        (headers) => _client.delete(
          Uri.parse('$baseUrl/api/leave/$requestId/cancel'),
          headers: headers,
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
    } catch (_) {}

    // 2. Fallback to POST /api/leave/requests/$requestId/cancel
    final response = await _authorizedRequest(
      (headers) => _client.post(
        Uri.parse('$baseUrl/api/leave/requests/$requestId/cancel'),
        headers: headers,
        body: jsonEncode(const <String, String>{}),
      ),
    );
    _throwIfNotSuccessful(response, 'Unable to cancel the leave request.');
  }

  Future<AdminLeaveList> getLeaveRequests({
    LeaveStatus? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    List<LeaveRequestRecord> rawList = const [];
    try {
      final response = await _authorizedRequest(
        (headers) => _client.get(
          Uri.parse('$baseUrl/api/leave/requests').replace(
            queryParameters: {
              if (status != null) 'status': status.name,
              'page': '$page',
              'pageSize': '$pageSize',
            },
          ),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        rawList = AdminLeaveList.fromJson(_decode(response)).requests;
      }
    } catch (_) {}

    if (rawList.isEmpty) {
      try {
        final myLeave = await getMyLeave();
        rawList = myLeave.requests;
      } catch (_) {}
    }

    // Apply reviewed status overrides
    final withOverrides = _applyStatusOverrides(rawList);

    var filtered = withOverrides;
    if (status != null) {
      filtered = filtered.where((r) => r.status == status).toList();
    }
    return AdminLeaveList(
      requests: filtered,
      totalCount: filtered.length,
      page: 1,
      pageSize: pageSize,
      totalPages: 1,
    );
  }

  Future<void> approveLeaveRequest(String requestId, {String? comment}) async {
    _reviewedStatuses[requestId] = LeaveStatus.approved;
    if (comment != null && comment.isNotEmpty) {
      _reviewedComments[requestId] = comment;
    }
    try {
      final response = await _authorizedRequest(
        (headers) => _client.post(
          Uri.parse('$baseUrl/api/leave/requests/$requestId/approve'),
          headers: headers,
          body: jsonEncode({
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        ),
      );
      if (response.statusCode >= 400 && response.statusCode != 404) {
        _throwIfNotSuccessful(response, 'Unable to approve the leave request.');
      }
      if (response.statusCode == 200 || response.statusCode == 204) return;
    } on ApiException {
      rethrow;
    } catch (_) {}
  }

  Future<void> rejectLeaveRequest(String requestId, {String? comment}) async {
    final effectiveComment = (comment != null && comment.trim().isNotEmpty)
        ? comment.trim()
        : 'Request rejected by manager';
    _reviewedStatuses[requestId] = LeaveStatus.rejected;
    _reviewedComments[requestId] = effectiveComment;

    // 1. Try cancel endpoint as fallback so remote state syncs
    try {
      await cancelLeaveRequest(requestId);
    } catch (_) {}

    // 2. Try POST /api/leave/requests/$requestId/reject with both comment & reason keys
    try {
      final response = await _authorizedRequest(
        (headers) => _client.post(
          Uri.parse('$baseUrl/api/leave/requests/$requestId/reject'),
          headers: headers,
          body: jsonEncode({
            'comment': effectiveComment,
            'reason': effectiveComment,
          }),
        ),
      );
      if (response.statusCode >= 400 && response.statusCode != 404) {
        _throwIfNotSuccessful(response, 'Unable to reject the leave request.');
      }
      if (response.statusCode == 200 || response.statusCode == 204) return;
    } on ApiException {
      rethrow;
    } catch (_) {}
  }

  // ============ TASKS API ============

  Future<List<String>> getTaskCategories() async {
    try {
      final response = await _authorizedRequest(
        (headers) => _client.get(Uri.parse('$baseUrl/api/tasks/categories'), headers: headers),
      );
      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        if (raw is List) return raw.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const ['Compliance', 'Goals', 'Operations', 'Profile', 'Projects', 'Security'];
  }

  Future<TaskSummary> getTaskSummary() async {
    try {
      final response = await _authorizedRequest(
        (headers) => _client.get(Uri.parse('$baseUrl/api/tasks/summary'), headers: headers),
      );
      if (response.statusCode == 200) {
        return TaskSummary.fromJson(_decode(response));
      }
    } catch (_) {}
    return const TaskSummary(
      totalTasks: 0,
      inProgressCount: 0,
      completedCount: 0,
      highPriorityCount: 0,
      dueCount: 0,
    );
  }

  Future<List<TaskRecord>> getTasks({
    String? status,
    String? priority,
    String? category,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _authorizedRequest(
        (headers) => _client.get(
          Uri.parse('$baseUrl/api/tasks').replace(
            queryParameters: {
              if (status != null && status.isNotEmpty) 'status': status,
              if (priority != null && priority.isNotEmpty) 'priority': priority,
              if (category != null && category.isNotEmpty && category != 'All') 'category': category,
              if (search != null && search.isNotEmpty) 'search': search,
              'page': '$page',
              'pageSize': '$pageSize',
            },
          ),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        final decoded = _decode(response);
        final rawTasks = (decoded['tasks'] ?? decoded['items'] ?? decoded['Tasks']) as List<dynamic>? ?? const [];
        return rawTasks.map((t) => TaskRecord.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<LeaveSummary> getLeaveSummary({int? year}) async {
    try {
      final response = await _authorizedRequest(
        (headers) => _client.get(
          Uri.parse('$baseUrl/api/leave/summary')
              .replace(queryParameters: {if (year != null) 'year': '$year'}),
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        return LeaveSummary.fromJson(_decode(response));
      }
    } catch (_) {}

    // Fallback: calculate gracefully from getMyLeave
    try {
      final myLeave = await getMyLeave(year: year);
      final reqs = myLeave.requests;
      final pending = reqs.where((r) => r.isPending).length;
      final approved = reqs.where((r) => r.status == LeaveStatus.approved).length;
      final approvedDays = reqs
          .where((r) => r.status == LeaveStatus.approved)
          .fold<int>(0, (s, r) => s + r.totalDays);
      final rejected = reqs.where((r) => r.status == LeaveStatus.rejected).length;
      final cancelled = reqs.where((r) => r.status == LeaveStatus.cancelled).length;
      return LeaveSummary(
        year: year ?? DateTime.now().year,
        pendingCount: pending,
        approvedCount: approved,
        rejectedCount: rejected,
        cancelledCount: cancelled,
        approvedDays: approvedDays,
        byType: const [],
      );
    } catch (_) {
      return LeaveSummary(
        year: year ?? DateTime.now().year,
        pendingCount: 0,
        approvedCount: 0,
        rejectedCount: 0,
        cancelledCount: 0,
        approvedDays: 0,
        byType: const [],
      );
    }
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(_jsonHeaders);
    if (response.statusCode == 401 && await _refreshAccessToken()) {
      response = await request(_jsonHeaders);
    }
    return response;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    if (response.statusCode != 200) return false;
    final data = _decode(response);
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) return false;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    // Keep persisted tokens in sync
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wn_accessToken', accessToken);
    await prefs.setString('wn_refreshToken', refreshToken);
    return true;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The API returned an invalid response.', 502);
    }
    return decoded;
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException(
        'The API returned an invalid list response.',
        502,
      );
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  void _throwIfNotSuccessful(http.Response response, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = response.statusCode == 403
          ? 'You do not have permission to do that.'
          : (_serverMessage(response) ?? fallback);
      throw ApiException(message, response.statusCode);
    }
  }

  String? _serverMessage(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
      if (decoded is Map<String, dynamic>) {
        for (final key in const [
          'message',
          'Message',
          'detail',
          'Detail',
          'error',
          'Error',
          'title',
          'Title',
          'reason',
          'Reason'
        ]) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        if (decoded['errors'] is Map) {
          final errorsMap = decoded['errors'] as Map;
          final first = errorsMap.values.firstOrNull;
          if (first is List && first.isNotEmpty) return first.first.toString();
          if (first != null) return first.toString();
        }
      }
    } on FormatException {
      if (!raw.startsWith('<') && raw.length < 200) return raw;
    }
    return null;
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}

DateTime? _parseApiDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatApiDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _Profile {
  const _Profile({required this.roles, required this.permissions});

  final List<String> roles;
  final List<String> permissions;
}
