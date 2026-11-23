import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/hrm_repository.dart';
import '../../data/services/device_capabilities_service.dart';
import '../../data/services/push_notification_service.dart';
import '../../domain/models/employee_models.dart';

class AppState extends ChangeNotifier {
  AppState({
    required HrmRepository repository,
    required DeviceCapabilitiesService deviceService,
  })  : _repo = repository,
        _device = deviceService;

  final HrmRepository _repo;
  final DeviceCapabilitiesService _device;

  static const String _bioPrefKey = 'keystone_require_biometric_punch';
  static const String _selfiePrefKey = 'keystone_require_selfie_punch';

  EmployeeUser? user;
  EmployeeProfile? profile;
  AttendanceSettings settings = const AttendanceSettings(
    geofenceEnabled: false,
    officeName: 'Alderway HQ',
    officeLatitude: 19.1136,
    officeLongitude: 72.8697,
    geofenceRadiusMeters: 250,
  );
  AttendanceMonth? attendanceMonth;
  List<FieldVisit> fieldVisits = const [];
  LeaveData leaveData = const LeaveData(balances: [], requests: [], holidays: []);
  Payslip? payslip;
  List<CompanyDocument> documents = const [];
  List<AppNotification> notifications = const [];
  TimesheetWeek timesheet = TimesheetWeek(
    weekStartDate: _currentMondayIso(),
    status: 'DRAFT',
    rows: const [],
  );
  List<HelpdeskTicket> tickets = const [];
  List<DashboardStat> dashboardStats = const [];

  bool isInitializing = true;
  bool isBusy = false;
  bool isPunching = false;
  bool isRefreshingLocation = false;
  String? errorMessage;

  // Live hardware verification state for the next punch
  PunchMethod selectedMethod = PunchMethod.mobile;
  GeoLocationFix? currentFix;
  SelfieCaptureResult? pendingSelfie;
  String? todaySelfieDataUrl;
  Uint8List? todaySelfieBytes;
  BiometricResult? biometricCheck;

  int punchFocusTick = 0;
  void requestPunchButtonFocus() {
    punchFocusTick++;
    notifyListeners();
  }

  Timer? _notificationPollTimer;
  int notificationPage = 1;
  bool hasMoreNotifications = true;
  bool isLoadingMoreNotifications = false;
  final Set<String> dismissedBannerIds = {};
  String? pendingDeepLinkNotificationId;

  void handleDeepLink(String? notificationId) {
    if (notificationId != null && notificationId.isNotEmpty) {
      pendingDeepLinkNotificationId = notificationId;
      notifyListeners();
    }
  }

  void clearPendingDeepLink() {
    pendingDeepLinkNotificationId = null;
    notifyListeners();
  }

  void dismissBanner(String notificationId) {
    dismissedBannerIds.add(notificationId);
    notifyListeners();
  }

  void _setupPushNotifications() {
    PushNotificationService.instance.onNotificationTapped = (id, type, data) {
      if (id != null && id.isNotEmpty) {
        handleDeepLink(id);
      }
    };
    PushNotificationService.instance.onForegroundNotificationReceived = () {
      refreshNotifications();
    };
    PushNotificationService.instance.initialize(
      onTokenReady: (token) async {
        await _repo.registerDeviceToken(token);
      },
    );
  }

  void startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _setupPushNotifications();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (user != null) {
        refreshNotifications();
      }
    });
  }

  void stopNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
  }

  Future<void> refreshNotifications([String? tab]) async {
    if (user == null) return;
    try {
      notificationPage = 1;
      hasMoreNotifications = true;
      final list = await _repo.fetchNotifications(tab: tab, page: 1, limit: 20);
      notifications = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMoreNotifications([String? tab]) async {
    if (isLoadingMoreNotifications || !hasMoreNotifications || user == null) return;
    isLoadingMoreNotifications = true;
    notifyListeners();
    try {
      final nextPage = notificationPage + 1;
      final more = await _repo.fetchNotifications(tab: tab, page: nextPage, limit: 20);
      if (more.isEmpty) {
        hasMoreNotifications = false;
      } else {
        notificationPage = nextPage;
        final existingIds = notifications.map((n) => n.id).toSet();
        final newItems = more.where((n) => !existingIds.contains(n.id)).toList();
        if (newItems.isEmpty) {
          hasMoreNotifications = false;
        } else {
          notifications = [...notifications, ...newItems];
        }
      }
    } catch (_) {}
    isLoadingMoreNotifications = false;
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].read) {
      final updated = notifications[idx].copyWith(read: true);
      final nextList = List<AppNotification>.from(notifications);
      nextList[idx] = updated;
      notifications = nextList;
      notifyListeners();
    }
    await _repo.markNotificationRead(id);
  }

  Future<void> markAllNotificationsRead() async {
    notifications = notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    await _repo.markAllNotificationsRead();
  }

  Future<void> acknowledgeNotification(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final updated = notifications[idx].copyWith(
        read: true,
        acknowledgedAt: DateTime.now().toIso8601String(),
      );
      final nextList = List<AppNotification>.from(notifications);
      nextList[idx] = updated;
      notifications = nextList;
      notifyListeners();
    }
    await _repo.acknowledgeNotification(id);
  }

  Uint8List? _safeDecodeDataUrl(String? dataUrl) {
    if (dataUrl == null || !dataUrl.contains(',')) return null;
    try {
      return base64Decode(dataUrl.split(',').last);
    } catch (_) {
      return null;
    }
  }

  void _syncTodaySelfie(String? selfieUrl) {
    if (selfieUrl != null && selfieUrl.isNotEmpty) {
      if (todaySelfieDataUrl != selfieUrl || todaySelfieBytes == null) {
        todaySelfieDataUrl = selfieUrl;
        todaySelfieBytes = _safeDecodeDataUrl(selfieUrl);
      }
    }
  }

  // User safety preferences
  bool requireBiometricBeforePunch = false;
  bool requireSelfieOnMobilePunch = false;

  String selectedPayslipMonth = _currentYearMonth();
  int selectedAttendanceYear = DateTime.now().year;
  int selectedAttendanceMonth = DateTime.now().month - 1; // 0-indexed for hrm-backend

  bool get isAuthenticated => user != null;
  bool get isOfflineDemo => _repo.isOfflineMode;
  String get backendUrl => _repo.backendUrl;

  int get unreadNotificationsCount => notifications.where((n) => !n.read).length;

  int? get liveDistanceToOfficeMeters {
    final fix = currentFix;
    if (fix == null || settings.officeLatitude == null || settings.officeLongitude == null) {
      return null;
    }
    return calculateDistanceMeters(
      fix.latitude,
      fix.longitude,
      settings.officeLatitude!,
      settings.officeLongitude!,
    );
  }

  bool get isInsideGeofence {
    final dist = liveDistanceToOfficeMeters;
    if (dist == null) return true;
    return dist <= settings.geofenceRadiusMeters;
  }

  static String _currentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _currentMondayIso() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      requireBiometricBeforePunch = prefs.getBool(_bioPrefKey) ?? false;
      requireSelfieOnMobilePunch = prefs.getBool(_selfiePrefKey) ?? false;

      final restored = await _repo.restoreSession();
      final savedSelfie = await _repo.getLocalTodaySelfie();
      _syncTodaySelfie(savedSelfie);
      if (restored != null) {
        user = restored;
        await refreshAll();
        startNotificationPolling();
      }
    } catch (_) {
      stopNotificationPolling();
      await _repo.logout();
      user = null;
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repo.login(email: email, password: password);
      await refreshAll();
      startNotificationPolling();
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<void> enterOfflineDemo() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      user = _repo.enterOfflinePreview();
      await refreshAll();
      startNotificationPolling();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    stopNotificationPolling();
    await PushNotificationService.instance.deleteToken();
    await _repo.logout();
    user = null;
    profile = null;
    attendanceMonth = null;
    fieldVisits = const [];
    notifications = const [];
    pendingSelfie = null;
    biometricCheck = null;
    notifyListeners();
  }

  Future<void> updateBackendUrl(String url) async {
    await _repo.setBackendUrl(url);
    notifyListeners();
  }

  Future<void> setBiometricRequired(bool value) async {
    requireBiometricBeforePunch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioPrefKey, value);
    notifyListeners();
  }

  Future<void> setSelfieRequired(bool value) async {
    requireSelfieOnMobilePunch = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_selfiePrefKey, value);
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (user == null) return;
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.fetchMyProfile(),
        _repo.fetchAttendanceSettings(),
        _repo.fetchAttendanceMonth(selectedAttendanceYear, selectedAttendanceMonth),
        _repo.fetchFieldVisits(),
        _repo.fetchLeaveData(),
        _repo.fetchMyPayslip(selectedPayslipMonth),
        _repo.fetchDocuments(),
        _repo.fetchNotifications(),
        _repo.fetchTimesheet(timesheet.weekStartDate),
        _repo.fetchTickets(),
        _repo.fetchDashboardStats(),
      ]);

      profile = results[0] as EmployeeProfile?;
      settings = results[1] as AttendanceSettings;
      attendanceMonth = results[2] as AttendanceMonth;
      fieldVisits = results[3] as List<FieldVisit>;
      leaveData = results[4] as LeaveData;
      payslip = results[5] as Payslip?;
      documents = results[6] as List<CompanyDocument>;
      notifications = results[7] as List<AppNotification>;
      timesheet = results[8] as TimesheetWeek;
      tickets = results[9] as List<HelpdeskTicket>;
      dashboardStats = results[10] as List<DashboardStat>;

      await refreshLocation(quiet: true);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      profile = await _repo.fetchMyProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshLocation({bool quiet = false}) async {
    if (!quiet) {
      isRefreshingLocation = true;
      notifyListeners();
    }
    try {
      currentFix = await _device.captureLocation(
        officeLat: settings.officeLatitude,
        officeLng: settings.officeLongitude,
        officeName: settings.officeName,
      );
    } finally {
      isRefreshingLocation = false;
      notifyListeners();
    }
  }

  void setPunchMethod(PunchMethod method) {
    selectedMethod = method;
    notifyListeners();
  }

  Future<bool> captureSelfie({bool allowFallback = true}) async {
    final result = await _device.captureSelfie(allowFallback: allowFallback);
    if (result == null) return false;
    pendingSelfie = result;
    _syncTodaySelfie(result.dataUrl);
    if (selectedMethod == PunchMethod.mobile) {
      selectedMethod = PunchMethod.selfie;
    }
    notifyListeners();
    return true;
  }

  void clearSelfie() {
    pendingSelfie = null;
    notifyListeners();
  }

  Future<bool> runBiometricVerification({bool allowFallback = true}) async {
    final result = await _device.verifyBiometric(
      reason: 'Confirm your identity to record attendance',
      allowFallback: allowFallback,
    );
    biometricCheck = result;
    notifyListeners();
    return result.verified;
  }

  Future<void> loadAttendanceForMonth(int year, int monthZeroIndexed) async {
    selectedAttendanceYear = year;
    selectedAttendanceMonth = monthZeroIndexed;
    attendanceMonth = await _repo.fetchAttendanceMonth(year, monthZeroIndexed);
    final selfie = attendanceMonth?.myTodayStatus?.checkInMeta?.selfieUrl ??
        attendanceMonth?.myTodayStatus?.checkOutMeta?.selfieUrl;
    _syncTodaySelfie(selfie);
    notifyListeners();
  }

  Future<void> clockInAgain() async {
    isBusy = true;
    notifyListeners();
    try {
      await _repo.resetTodayAttendance();
      attendanceMonth = await _repo.fetchAttendanceMonth(
        selectedAttendanceYear,
        selectedAttendanceMonth,
      );
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadPayslipForMonth(String yearMonth) async {
    selectedPayslipMonth = yearMonth;
    payslip = await _repo.fetchMyPayslip(yearMonth);
    notifyListeners();
  }

  String getPayslipPdfUrl([String? yearMonth]) {
    final ym = yearMonth ?? selectedPayslipMonth;
    return _repo.getPayslipPdfUrl(ym);
  }

  Future<bool> openPayslipPdf([String? yearMonth]) async {
    final ym = yearMonth ?? selectedPayslipMonth;
    final urlStr = _repo.getPayslipPdfUrl(ym);
    final uri = Uri.parse(urlStr);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> performPunch({required bool isCheckOut}) async {
    if (isPunching) return;
    isPunching = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Capture fresh GPS fix before punching
      final fix = await _device.captureLocation(
        officeLat: settings.officeLatitude,
        officeLng: settings.officeLongitude,
        officeName: settings.officeName,
      );
      currentFix = fix;

      // Enforce optional or method-triggered selfie
      if ((selectedMethod == PunchMethod.selfie || requireSelfieOnMobilePunch) &&
          pendingSelfie == null &&
          todaySelfieDataUrl == null) {
        final ok = await captureSelfie(allowFallback: true);
        if (!ok) {
          throw Exception('Selfie verification is required before punching.');
        }
      }

      // Enforce optional or method-triggered biometric scan
      if ((selectedMethod == PunchMethod.biometric || requireBiometricBeforePunch) &&
          !(biometricCheck?.verified ?? false)) {
        final ok = await runBiometricVerification(allowFallback: true);
        if (!ok) {
          throw Exception('Biometric verification was cancelled.');
        }
      }

      final selfiePayload = pendingSelfie?.dataUrl ?? todaySelfieDataUrl;

      if (isCheckOut) {
        await _repo.checkOut(
          method: selectedMethod,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          address: fix.addressLabel,
          selfieDataUrl: selfiePayload,
          biometricVerified: biometricCheck?.verified ?? false,
        );
      } else {
        await _repo.checkIn(
          method: selectedMethod,
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          address: fix.addressLabel,
          selfieDataUrl: selfiePayload,
          biometricVerified: biometricCheck?.verified ?? false,
        );
      }

      pendingSelfie = null;
      attendanceMonth = await _repo.fetchAttendanceMonth(
        selectedAttendanceYear,
        selectedAttendanceMonth,
      );
      final selfieAfter = attendanceMonth?.myTodayStatus?.checkInMeta?.selfieUrl ??
          attendanceMonth?.myTodayStatus?.checkOutMeta?.selfieUrl;
      _syncTodaySelfie(selfieAfter ?? selfiePayload);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isPunching = false;
      notifyListeners();
    }
  }

  Future<void> requestAttendanceCorrection({
    required String date,
    required String reason,
    String? proposedCheckIn,
    String? proposedCheckOut,
  }) async {
    await _repo.requestAttendanceCorrection(
      date: date,
      reason: reason,
      proposedCheckIn: proposedCheckIn,
      proposedCheckOut: proposedCheckOut,
    );
  }

  Future<void> startFieldVisit({
    required String clientName,
    required String purpose,
    String? notes,
    bool includeSelfie = false,
  }) async {
    final fix = currentFix ??
        await _device.captureLocation(
          officeLat: settings.officeLatitude,
          officeLng: settings.officeLongitude,
          officeName: settings.officeName,
        );
    currentFix = fix;

    String? selfieUrl = pendingSelfie?.dataUrl;
    if (includeSelfie && selfieUrl == null) {
      final shot = await _device.captureSelfie(allowFallback: true);
      selfieUrl = shot?.dataUrl;
    }

    final visit = await _repo.startFieldVisit(
      clientName: clientName,
      purpose: purpose,
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracy: fix.accuracy,
      address: fix.addressLabel,
      notes: notes,
      selfieDataUrl: selfieUrl,
      biometricVerified: biometricCheck?.verified ?? false,
    );
    fieldVisits = [visit, ...fieldVisits];
    notifyListeners();
  }

  Future<void> completeFieldVisit({required String visitId, String? notes}) async {
    final updated = await _repo.completeFieldVisit(visitId: visitId, notes: notes);
    fieldVisits = fieldVisits.map((v) => v.id == visitId ? updated : v).toList();
    notifyListeners();
  }

  Future<void> applyLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    bool isHalfDay = false,
    String? halfDayPeriod,
  }) async {
    await _repo.applyLeave(
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      isHalfDay: isHalfDay,
      halfDayPeriod: halfDayPeriod,
    );
    leaveData = await _repo.fetchLeaveData();
    notifyListeners();
  }

  Future<void> cancelLeave(String id) async {
    await _repo.cancelLeave(id);
    leaveData = await _repo.fetchLeaveData();
    notifyListeners();
  }

  Future<void> saveTimesheetRows(List<TimesheetRowItem> rows) async {
    timesheet = await _repo.saveTimesheet(
      weekStartDate: timesheet.weekStartDate,
      rows: rows,
    );
    notifyListeners();
  }

  Future<void> submitTimesheet() async {
    if (timesheet.id == null || timesheet.id!.isEmpty) {
      await saveTimesheetRows(timesheet.rows);
    }
    if (timesheet.id != null && timesheet.id!.isNotEmpty) {
      timesheet = await _repo.submitTimesheet(timesheet.id!, timesheet.weekStartDate);
      notifyListeners();
    }
  }

  Future<void> createTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
  }) async {
    final created = await _repo.createTicket(
      subject: subject,
      description: description,
      category: category,
      priority: priority,
    );
    tickets = [created, ...tickets];
    notifyListeners();
  }

  Future<void> addTicketComment({required String ticketId, required String comment}) async {
    await _repo.addTicketComment(ticketId: ticketId, comment: comment);
    tickets = await _repo.fetchTickets();
    notifyListeners();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> updateMyProfile({required String contactNumber, required String homeAddress}) async {
    final updated = await _repo.updateMyProfile(
      contactNumber: contactNumber,
      homeAddress: homeAddress,
    );
    if (updated != null) {
      profile = updated;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopNotificationPolling();
    super.dispose();
  }
}

