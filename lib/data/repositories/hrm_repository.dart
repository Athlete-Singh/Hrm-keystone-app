import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/employee_models.dart';
import '../services/api_client.dart';
import 'demo_data.dart';

class HrmRepository {
  HrmRepository({
    required ApiClient apiClient,
    DemoStore? demoStore,
  })  : _api = apiClient,
        _demo = demoStore ?? DemoStore();

  final ApiClient _api;
  final DemoStore _demo;

  bool isOfflineMode = false;

  String get backendUrl => _api.baseUrl;
  bool get hasStoredSession => _api.hasSession;

  Future<void> setBackendUrl(String url) => _api.setBaseUrl(url);

  Future<EmployeeUser> login({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // Check if demo credentials are provided
    final isDemoAccount = (cleanEmail == 'employee@demo.com' || cleanEmail.contains('demo')) &&
        (cleanPassword == 'demo1234' || cleanPassword.toLowerCase().contains('demo'));

    if (isDemoAccount) {
      try {
        isOfflineMode = false;
        final data = await _api.post(
          '/auth/login',
          body: {'email': cleanEmail, 'password': cleanPassword},
          captureAuthToken: true,
        ) as Map<String, dynamic>;

        final user = EmployeeUser.fromJson(data);
        final orgId = user.memberships.isNotEmpty ? user.memberships.first.organizationId : null;
        await _api.setAuthSession(token: _api.token, workspaceId: orgId);
        return user;
      } catch (_) {
        // Backend server unreachable, timed out, or connection refused ->
        // Activate full offline demo mode seamlessly!
        isOfflineMode = true;
        await _api.setAuthSession(token: 'demo-token-offline', workspaceId: 'org-alderway');
        return _demo.user;
      }
    }

    try {
      isOfflineMode = false;
      final data = await _api.post(
        '/auth/login',
        body: {'email': cleanEmail, 'password': cleanPassword},
        captureAuthToken: true,
      ) as Map<String, dynamic>;

      final user = EmployeeUser.fromJson(data);
      final orgId = user.memberships.isNotEmpty ? user.memberships.first.organizationId : null;
      await _api.setAuthSession(token: _api.token, workspaceId: orgId);
      return user;
    } catch (e) {
      if (cleanEmail.contains('demo') && cleanPassword.toLowerCase().contains('demo')) {
        isOfflineMode = true;
        await _api.setAuthSession(token: 'demo-token-offline', workspaceId: 'org-alderway');
        return _demo.user;
      }
      rethrow;
    }
  }

  @visibleForTesting
  EmployeeUser enterOfflinePreview() {
    isOfflineMode = true;
    return _demo.user;
  }

  Future<EmployeeUser?> restoreSession() async {
    if (!_api.hasSession) return null;
    if (_api.token == 'demo-token-offline') {
      isOfflineMode = true;
      return _demo.user;
    }
    try {
      final data = await _api.get('/auth/me') as Map<String, dynamic>;
      final user = EmployeeUser.fromJson(data);
      if ((_api.workspaceId == null || _api.workspaceId!.isEmpty) && user.memberships.isNotEmpty) {
        await _api.setWorkspaceId(user.memberships.first.organizationId);
      }
      return user;
    } catch (_) {
      if (_api.token == 'demo-token-offline') {
        isOfflineMode = true;
        return _demo.user;
      }
      return null;
    }
  }

  Future<void> logout() async {
    if (!isOfflineMode && _api.hasSession) {
      try {
        await _api.post('/auth/logout');
      } catch (_) {
        // Always clear local session regardless of network errors.
      }
    }
    isOfflineMode = false;
    await _api.setAuthSession(token: null, workspaceId: null);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (isOfflineMode) return;
    await _api.post(
      '/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<EmployeeProfile?> fetchMyProfile() async {
    if (isOfflineMode) return _demo.profile;
    final data = await _api.get('/employees/me');
    if (data is Map<String, dynamic>) {
      return EmployeeProfile.fromJson(data);
    }
    return null;
  }

  Future<EmployeeProfile?> updateMyProfile({
    required String contactNumber,
    required String homeAddress,
  }) async {
    if (isOfflineMode) {
      _demo.profile = EmployeeProfile(
        id: _demo.profile.id,
        organizationId: _demo.profile.organizationId,
        name: _demo.profile.name,
        avatarInitials: _demo.profile.avatarInitials,
        email: _demo.profile.email,
        phone: contactNumber,
        department: _demo.profile.department,
        designation: _demo.profile.designation,
        status: _demo.profile.status,
        employmentType: _demo.profile.employmentType,
        location: _demo.profile.location,
        homeAddress: homeAddress,
        joinedAt: _demo.profile.joinedAt,
        employeeId: _demo.profile.employeeId,
        managerName: _demo.profile.managerName,
      );
      return _demo.profile;
    }

    final data = await _api.patch(
      '/employees/me',
      body: {
        'contactNumber': contactNumber,
        'homeAddress': homeAddress,
      },
    );
    if (data is Map<String, dynamic>) {
      return EmployeeProfile.fromJson(data);
    }
    return null;
  }

  Future<List<DashboardStat>> fetchDashboardStats() async {
    if (isOfflineMode) {
      return [
        const DashboardStat(id: 'att', label: 'Attendance this month', value: '94%', delta: '+2%'),
        const DashboardStat(id: 'leave', label: 'Annual leave left', value: '21 d'),
      ];
    }
    final data = await _api.get('/dashboard') as Map<String, dynamic>;
    return ((data['stats'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DashboardStat.fromJson)
        .toList();
  }

  static const String _todayAttendanceKeyPrefix = 'keystone_attendance_today_';
  static const String _todaySelfieKeyPrefix = 'keystone_selfie_today_';

  Future<void> saveLocalTodayStatus(MyTodayStatus status, {String? selfieDataUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _isoToday();
      await prefs.setString('$_todayAttendanceKeyPrefix$today', jsonEncode(status.toJson()));
      final selfieToSave = selfieDataUrl ?? status.checkInMeta?.selfieUrl ?? status.checkOutMeta?.selfieUrl;
      if (selfieToSave != null && selfieToSave.isNotEmpty) {
        await prefs.setString('$_todaySelfieKeyPrefix$today', selfieToSave);
      }
    } catch (_) {}
  }

  Future<MyTodayStatus?> getLocalTodayStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _isoToday();
      final raw = prefs.getString('$_todayAttendanceKeyPrefix$today');
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      var status = MyTodayStatus.fromJson(map);
      final savedSelfie = prefs.getString('$_todaySelfieKeyPrefix$today');
      if (savedSelfie != null && savedSelfie.isNotEmpty) {
        if (status.checkInMeta?.selfieUrl == null || status.checkInMeta!.selfieUrl!.isEmpty) {
          status = status.copyWith(
            checkInMeta: (status.checkInMeta ?? const PunchMeta()).copyWith(selfieUrl: savedSelfie),
          );
        }
      }
      return status;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getLocalTodaySelfie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _isoToday();
      return prefs.getString('$_todaySelfieKeyPrefix$today');
    } catch (_) {
      return null;
    }
  }

  Future<void> resetTodayAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _isoToday();
      await prefs.remove('$_todayAttendanceKeyPrefix$today');
    } catch (_) {}
    _demo.todayStatus = const MyTodayStatus(checkedIn: false, checkedOut: false);
  }

  Future<AttendanceMonth> fetchAttendanceMonth(int year, int monthZeroIndexed) async {
    if (isOfflineMode) {
      final localStatus = await getLocalTodayStatus();
      if (localStatus != null) {
        _demo.todayStatus = localStatus;
      }
      return AttendanceMonth(
        year: year,
        month: monthZeroIndexed,
        todayDate: _isoToday(),
        records: _demo.records,
        myTodayStatus: _demo.todayStatus,
      );
    }
    try {
      final data = await _api.get(
        '/attendance/month',
        query: {
          'year': year.toString(),
          'month': monthZeroIndexed.toString(),
        },
      ) as Map<String, dynamic>;
      var res = AttendanceMonth.fromJson(data);
      final localSelfie = await getLocalTodaySelfie();
      if (res.myTodayStatus != null) {
        if ((res.myTodayStatus!.checkInMeta?.selfieUrl == null ||
                res.myTodayStatus!.checkInMeta!.selfieUrl!.isEmpty) &&
            localSelfie != null &&
            localSelfie.isNotEmpty) {
          res = AttendanceMonth(
            year: res.year,
            month: res.month,
            todayDate: res.todayDate,
            records: res.records,
            myTodayStatus: res.myTodayStatus!.copyWith(
              checkInMeta: (res.myTodayStatus!.checkInMeta ?? const PunchMeta())
                  .copyWith(selfieUrl: localSelfie),
            ),
          );
        }
        await saveLocalTodayStatus(res.myTodayStatus!, selfieDataUrl: localSelfie);
      } else {
        final cached = await getLocalTodayStatus();
        if (cached != null) {
          res = AttendanceMonth(
            year: res.year,
            month: res.month,
            todayDate: res.todayDate,
            records: res.records,
            myTodayStatus: cached,
          );
        }
      }
      return res;
    } catch (_) {
      final cached = await getLocalTodayStatus();
      return AttendanceMonth(
        year: year,
        month: monthZeroIndexed,
        todayDate: _isoToday(),
        records: _demo.records,
        myTodayStatus: cached ?? _demo.todayStatus,
      );
    }
  }

  Future<AttendanceSettings> fetchAttendanceSettings() async {
    if (isOfflineMode) return _demo.settings;
    final data = await _api.get('/attendance/settings') as Map<String, dynamic>;
    return AttendanceSettings.fromJson(data);
  }

  Future<void> checkIn({
    required PunchMethod method,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    String? selfieDataUrl,
    bool biometricVerified = false,
  }) async {
    final now = DateTime.now();
    final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dist = (latitude != null &&
            longitude != null &&
            _demo.settings.officeLatitude != null &&
            _demo.settings.officeLongitude != null)
        ? calculateDistanceMeters(
            latitude,
            longitude,
            _demo.settings.officeLatitude!,
            _demo.settings.officeLongitude!,
          )
        : 42;

    final effectiveSelfie = selfieDataUrl ?? (await getLocalTodaySelfie());

    final statusToSave = MyTodayStatus(
      checkedIn: true,
      checkedOut: false,
      checkInTime: hhmm,
      checkInMeta: PunchMeta(
        method: method.apiValue,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: address ?? 'Andheri East, Mumbai',
        selfieUrl: effectiveSelfie,
        biometricVerified: biometricVerified,
        geofenceStatus: dist <= _demo.settings.geofenceRadiusMeters ? 'INSIDE' : 'OUTSIDE',
        distanceMeters: dist,
      ),
    );

    if (isOfflineMode) {
      _demo.todayStatus = statusToSave;
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
      return;
    }

    try {
      await _api.post(
        '/attendance/check-in',
        body: {
          'method': method.apiValue,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'accuracy': ?accuracy,
          if (address != null && address.isNotEmpty) 'address': address,
          if (effectiveSelfie != null && effectiveSelfie.isNotEmpty) 'selfieDataUrl': effectiveSelfie,
          'biometricVerified': biometricVerified,
        },
      );
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
    } catch (e) {
      // If network fails, save locally so attendance is never lost
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
      rethrow;
    }
  }

  Future<void> checkOut({
    required PunchMethod method,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    String? selfieDataUrl,
    bool biometricVerified = false,
  }) async {
    final now = DateTime.now();
    final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final localPrior = (await getLocalTodayStatus()) ?? _demo.todayStatus;
    final effectiveSelfie = selfieDataUrl ?? localPrior.checkInMeta?.selfieUrl ?? (await getLocalTodaySelfie());

    final statusToSave = MyTodayStatus(
      checkedIn: true,
      checkedOut: true,
      checkInTime: localPrior.checkInTime ?? '09:05',
      checkOutTime: hhmm,
      checkInMeta: localPrior.checkInMeta ?? PunchMeta(
        selfieUrl: effectiveSelfie,
        method: method.apiValue,
      ),
      checkOutMeta: PunchMeta(
        method: method.apiValue,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: address ?? 'Andheri East, Mumbai',
        selfieUrl: effectiveSelfie,
        biometricVerified: biometricVerified,
        geofenceStatus: 'INSIDE',
        distanceMeters: 42,
      ),
    );

    if (isOfflineMode) {
      _demo.todayStatus = statusToSave;
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
      return;
    }

    try {
      await _api.post(
        '/attendance/check-out',
        body: {
          'method': method.apiValue,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'accuracy': ?accuracy,
          if (address != null && address.isNotEmpty) 'address': address,
          if (effectiveSelfie != null && effectiveSelfie.isNotEmpty) 'selfieDataUrl': effectiveSelfie,
          'biometricVerified': biometricVerified,
        },
      );
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
    } catch (e) {
      await saveLocalTodayStatus(statusToSave, selfieDataUrl: effectiveSelfie);
      rethrow;
    }
  }

  Future<void> requestAttendanceCorrection({
    required String date,
    required String reason,
    String? proposedCheckIn,
    String? proposedCheckOut,
  }) async {
    if (isOfflineMode) return;
    await _api.post(
      '/attendance/correction',
      body: {
        'date': date,
        'reason': reason,
        if (proposedCheckIn != null && proposedCheckIn.isNotEmpty) 'proposedCheckIn': proposedCheckIn,
        if (proposedCheckOut != null && proposedCheckOut.isNotEmpty) 'proposedCheckOut': proposedCheckOut,
      },
    );
  }

  Future<List<FieldVisit>> fetchFieldVisits({String? date}) async {
    if (isOfflineMode) return List.unmodifiable(_demo.visits);
    final raw = await _api.get(
      '/attendance/visits',
      query: {if (date != null && date.isNotEmpty) 'date': date},
    );
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(FieldVisit.fromJson).toList();
    }
    return const [];
  }

  Future<FieldVisit> startFieldVisit({
    required String clientName,
    required String purpose,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? address,
    String? notes,
    String? selfieDataUrl,
    bool biometricVerified = false,
  }) async {
    if (isOfflineMode) {
      final now = DateTime.now();
      final visit = FieldVisit(
        id: 'fv-${now.millisecondsSinceEpoch}',
        date: _isoToday(),
        clientName: clientName,
        purpose: purpose,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: address,
        notes: notes,
        selfieUrl: selfieDataUrl,
        biometricVerified: biometricVerified,
        status: 'ACTIVE',
        checkedInAt: now.toIso8601String(),
      );
      _demo.visits.insert(0, visit);
      return visit;
    }

    final data = await _api.post(
      '/attendance/visits',
      body: {
        'clientName': clientName,
        'purpose': purpose,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': ?accuracy,
        if (address != null && address.isNotEmpty) 'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (selfieDataUrl != null && selfieDataUrl.isNotEmpty) 'selfieDataUrl': selfieDataUrl,
        'biometricVerified': biometricVerified,
      },
    ) as Map<String, dynamic>;
    return FieldVisit.fromJson(data);
  }

  Future<FieldVisit> completeFieldVisit({required String visitId, String? notes}) async {
    if (isOfflineMode) {
      final idx = _demo.visits.indexWhere((v) => v.id == visitId);
      if (idx != -1) {
        final v = _demo.visits[idx];
        final completed = FieldVisit(
          id: v.id,
          date: v.date,
          clientName: v.clientName,
          purpose: v.purpose,
          latitude: v.latitude,
          longitude: v.longitude,
          accuracy: v.accuracy,
          address: v.address,
          notes: notes ?? v.notes,
          selfieUrl: v.selfieUrl,
          biometricVerified: v.biometricVerified,
          status: 'COMPLETED',
          checkedInAt: v.checkedInAt,
          checkedOutAt: DateTime.now().toIso8601String(),
        );
        _demo.visits[idx] = completed;
        return completed;
      }
    }

    final data = await _api.patch(
      '/attendance/visits/$visitId/complete',
      body: {
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    ) as Map<String, dynamic>;
    return FieldVisit.fromJson(data);
  }

  Future<LeaveData> fetchLeaveData() async {
    if (isOfflineMode) return _demo.leaveData;
    final data = await _api.get('/leave') as Map<String, dynamic>;
    return LeaveData.fromJson(data);
  }

  Future<void> applyLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    bool isHalfDay = false,
    String? halfDayPeriod,
  }) async {
    if (isOfflineMode) {
      final newReq = LeaveRequest(
        id: 'lv-${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        startDate: startDate,
        endDate: endDate,
        days: isHalfDay ? 0.5 : 1,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        reason: reason,
        status: 'PENDING',
        requestedAt: DateTime.now().toIso8601String(),
      );
      _demo.leaveData = LeaveData(
        balances: _demo.leaveData.balances,
        requests: [newReq, ..._demo.leaveData.requests],
        holidays: _demo.leaveData.holidays,
      );
      return;
    }

    await _api.post(
      '/leave',
      body: {
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'isHalfDay': isHalfDay,
        if (isHalfDay && halfDayPeriod != null) 'halfDayPeriod': halfDayPeriod,
      },
    );
  }

  Future<void> cancelLeave(String id) async {
    if (isOfflineMode) {
      _demo.leaveData = LeaveData(
        balances: _demo.leaveData.balances,
        requests: _demo.leaveData.requests.where((r) => r.id != id).toList(),
        holidays: _demo.leaveData.holidays,
      );
      return;
    }
    await _api.post('/leave/$id/cancel');
  }

  Future<Payslip?> fetchMyPayslip(String month) async {
    if (isOfflineMode) {
      return Payslip(
        month: month,
        status: 'FINALIZED',
        hasSalaryStructure: true,
        basic: 62000,
        hra: 24800,
        otherAllowance: 13200,
        daysInMonth: 30,
        unpaidDays: 0,
        bonus: 0,
        incentive: 0,
        reimbursement: 1850,
        incomeTax: 8400,
        otherDeduction: 200,
        lopDeduction: 0,
        grossEarnings: 101850,
        totalDeductions: 8600,
        netSalary: 93250,
        finalizedAt: '2026-11-01T10:00:00Z',
      );
    }

    final raw = await _api.get(
      '/payroll/payslips',
      query: {'month': month, 'scope': 'me'},
    );
    if (raw is List && raw.isNotEmpty) {
      return Payslip.fromJson(raw.first as Map<String, dynamic>);
    }
    if (raw is Map<String, dynamic>) {
      final rows = raw['payslips'] as List?;
      if (rows != null && rows.isNotEmpty) {
        return Payslip.fromJson(rows.first as Map<String, dynamic>);
      }
    }
    return null;
  }

  String getPayslipPdfUrl(String month) {
    return _api.buildUri('/payroll/payslips/my/pdf', {'month': month}).toString();
  }

  Future<Uint8List?> fetchPayslipPdf(String month) async {
    if (isOfflineMode) return null;
    try {
      return await _api.getBytes('/payroll/payslips/my/pdf', query: {'month': month});
    } catch (_) {
      return null;
    }
  }

  Future<List<CompanyDocument>> fetchDocuments() async {
    if (isOfflineMode) return _demo.documents;
    try {
      final raw = await _api.get('/documents');
      if (raw is Map<String, dynamic>) {
        final list = (raw['documents'] as List?) ?? const [];
        return list.whereType<Map<String, dynamic>>().map(CompanyDocument.fromJson).toList();
      }
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map(CompanyDocument.fromJson).toList();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) return const [];
      rethrow;
    }
    return const [];
  }

  static const String _notificationsCacheKey = 'keystone_cached_notifications_v1';

  Future<void> _cacheNotifications(List<AppNotification> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsCacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<AppNotification>> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notificationsCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> registerDeviceToken(String token) async {
    if (isOfflineMode || !_api.hasSession) return;
    try {
      await _api.post('/notifications/register-token', body: {'token': token});
    } catch (_) {
      // Best-effort push token sync, do not break caller
    }
  }

  Future<List<AppNotification>> fetchNotifications({String? tab, int page = 1, int limit = 30}) async {
    if (isOfflineMode) {
      if (tab == 'holidays') {
        return _demo.notifications.where((n) => n.type == 'HOLIDAY').toList();
      }
      if (tab == 'announcements') {
        return _demo.notifications.where((n) => n.type == 'ANNOUNCEMENT' || n.type == 'URGENT' || n.type == 'POLICY').toList();
      }
      if (tab == 'unread') {
        return _demo.notifications.where((n) => !n.read).toList();
      }
      return List.unmodifiable(_demo.notifications);
    }
    try {
      final queryParams = <String, String>{
        'page': '$page',
        'limit': '$limit',
      };
      if (tab != null && tab != 'all') {
        queryParams['tab'] = tab;
      }
      final raw = await _api.get(
        '/my/notifications',
        query: queryParams,
      );
      List<AppNotification> results = const [];
      if (raw is Map<String, dynamic>) {
        final list = (raw['notifications'] as List?) ?? const [];
        results = list.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
      } else if (raw is List) {
        results = raw.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
      }

      if (results.isNotEmpty && page == 1 && (tab == null || tab == 'all')) {
        await _cacheNotifications(results);
      }
      return results;
    } catch (_) {
      try {
        final raw = await _api.get('/notifications');
        if (raw is Map<String, dynamic>) {
          final list = (raw['notifications'] as List?) ?? const [];
          final results = list.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
          if (results.isNotEmpty && page == 1) await _cacheNotifications(results);
          return results;
        }
      } catch (_) {}

      // Offline cache fallback
      if (page == 1) {
        final cached = await getCachedNotifications();
        if (cached.isNotEmpty) return cached;
      }
    }
    return const [];
  }

  Future<void> markNotificationRead(String id) async {
    if (isOfflineMode) {
      _demo.notifications = _demo.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList();
      return;
    }
    try {
      await _api.patch('/my/notifications/$id/read');
    } catch (_) {
      await _api.post('/notifications/$id/read');
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (isOfflineMode) {
      _demo.notifications = _demo.notifications.map((n) => n.copyWith(read: true)).toList();
      return;
    }
    try {
      await _api.post('/my/notifications/read-all');
    } catch (_) {
      await _api.post('/notifications/read-all');
    }
  }

  Future<void> acknowledgeNotification(String id) async {
    if (isOfflineMode) {
      _demo.notifications = _demo.notifications
          .map((n) => n.id == id ? n.copyWith(acknowledgedAt: DateTime.now().toIso8601String(), read: true) : n)
          .toList();
      return;
    }
    await _api.post('/my/notifications/$id/acknowledge');
  }

  Future<TimesheetWeek> fetchTimesheet(String weekStartDate) async {
    if (isOfflineMode) return _demo.timesheet;
    final raw = await _api.get(
      '/timesheets',
      query: {'weekStartDate': weekStartDate},
    );
    if (raw is Map<String, dynamic>) {
      return TimesheetWeek.fromJson(raw, weekStartDate);
    }
    return TimesheetWeek(weekStartDate: weekStartDate, status: 'DRAFT', rows: const []);
  }

  Future<TimesheetWeek> saveTimesheet({
    required String weekStartDate,
    required List<TimesheetRowItem> rows,
  }) async {
    if (isOfflineMode) {
      _demo.timesheet = TimesheetWeek(
        id: _demo.timesheet.id ?? 'ts-demo-1',
        weekStartDate: weekStartDate,
        status: _demo.timesheet.status,
        rows: rows,
      );
      return _demo.timesheet;
    }

    final raw = await _api.post(
      '/timesheets',
      body: {
        'weekStartDate': weekStartDate,
        'rows': rows.map((r) => r.toJson()).toList(),
      },
    ) as Map<String, dynamic>;
    return TimesheetWeek.fromJson(raw, weekStartDate);
  }

  Future<TimesheetWeek> submitTimesheet(String id, String weekStartDate) async {
    if (isOfflineMode) {
      _demo.timesheet = TimesheetWeek(
        id: id,
        weekStartDate: weekStartDate,
        status: 'SUBMITTED',
        rows: _demo.timesheet.rows,
      );
      return _demo.timesheet;
    }
    final raw = await _api.patch(
      '/timesheets/$id/status',
      body: {'status': 'SUBMITTED'},
    ) as Map<String, dynamic>;
    return TimesheetWeek.fromJson(raw, weekStartDate);
  }

  Future<List<HelpdeskTicket>> fetchTickets() async {
    if (isOfflineMode) return List.unmodifiable(_demo.tickets);
    final raw = await _api.get('/helpdesk');
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(HelpdeskTicket.fromJson).toList();
    }
    return const [];
  }

  Future<HelpdeskTicket> createTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    if (isOfflineMode) {
      final ticket = HelpdeskTicket(
        id: 'tkt-${DateTime.now().millisecondsSinceEpoch}',
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        status: 'OPEN',
        createdAt: DateTime.now().toIso8601String(),
        comments: const [],
      );
      _demo.tickets.insert(0, ticket);
      return ticket;
    }

    final raw = await _api.post(
      '/helpdesk',
      body: {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
      },
    ) as Map<String, dynamic>;
    return HelpdeskTicket.fromJson(raw);
  }

  Future<void> addTicketComment({required String ticketId, required String comment}) async {
    if (isOfflineMode) {
      final idx = _demo.tickets.indexWhere((t) => t.id == ticketId);
      if (idx != -1) {
        final t = _demo.tickets[idx];
        _demo.tickets[idx] = HelpdeskTicket(
          id: t.id,
          subject: t.subject,
          description: t.description,
          category: t.category,
          priority: t.priority,
          status: t.status,
          createdAt: t.createdAt,
          comments: [
            ...t.comments,
            TicketComment(
              id: 'c-${DateTime.now().millisecondsSinceEpoch}',
              authorName: _demo.user.name,
              comment: comment,
              createdAt: DateTime.now().toIso8601String(),
            ),
          ],
        );
      }
      return;
    }
    await _api.post('/helpdesk/$ticketId/comment', body: {'comment': comment});
  }

  String _isoToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

