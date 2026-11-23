import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hrm_employee/data/repositories/hrm_repository.dart';
import 'package:hrm_employee/data/services/api_client.dart';
import 'package:hrm_employee/data/services/device_capabilities_service.dart';
import 'package:hrm_employee/domain/models/employee_models.dart';
import 'package:hrm_employee/main.dart';
import 'package:hrm_employee/ui/core/widgets/keystone_ui.dart';
import 'package:hrm_employee/ui/features/attendance/punch_tab.dart';
import 'package:hrm_employee/ui/viewmodels/app_state.dart';

class _FakeDeviceService implements DeviceCapabilitiesService {
  @override
  Future<GeoLocationFix> captureLocation({
    double? officeLat,
    double? officeLng,
    String? officeName,
  }) async {
    return const GeoLocationFix(
      latitude: 19.1139,
      longitude: 72.8699,
      accuracy: 9,
      addressLabel: 'Alderway HQ · Andheri East',
    );
  }

  @override
  Future<SelfieCaptureResult?> captureSelfie({bool allowFallback = false}) async {
    return const SelfieCaptureResult(
      dataUrl: 'data:image/jpeg;base64,AAAA',
      bytesLength: 4,
    );
  }

  @override
  String describeLocation({
    required double latitude,
    required double longitude,
    double? officeLat,
    double? officeLng,
    String? officeName,
  }) =>
      'Andheri East';

  @override
  Future<BiometricResult> verifyBiometric({
    required String reason,
    bool allowFallback = true,
  }) async {
    return const BiometricResult(verified: true, label: 'Fingerprint verified');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('calculateDistanceMeters computes Haversine meters accurately', () {
    expect(calculateDistanceMeters(19.1136, 72.8697, 19.1136, 72.8697), 0);
    final meters = calculateDistanceMeters(19.1136, 72.8697, 19.1139, 72.8699);
    expect(meters, greaterThan(20));
    expect(meters, lessThan(65));
  });

  test('parses backend attendance, field visits, leave, and payslip JSON', () {
    final month = AttendanceMonth.fromJson({
      'year': 2026,
      'month': 10,
      'todayDate': '2026-11-12',
      'myTodayStatus': {
        'checkedIn': true,
        'checkedOut': false,
        'checkInTime': '09:05',
        'checkInMeta': {
          'method': 'SELFIE',
          'latitude': 19.1136,
          'longitude': 72.8697,
          'address': 'Andheri East, Mumbai',
          'biometricVerified': true,
          'geofenceStatus': 'INSIDE',
          'distanceMeters': 42,
        },
      },
      'myMonthRecords': [
        {
          'id': 'att-1',
          'date': '2026-11-12',
          'status': 'PRESENT',
          'clockIn': '09:05',
          'hours': 8.5,
        },
        {
          'id': 'att-2',
          'date': '2026-11-11',
          'status': 'LATE',
          'clockIn': '09:42',
          'clockOut': '18:10',
          'hours': 8.5,
        },
      ],
    });

    expect(month.myTodayStatus?.checkedIn, isTrue);
    expect(month.myTodayStatus?.checkInMeta?.distanceMeters, 42);
    expect(month.records.length, 2);
    expect(month.records.first.status, 'PRESENT');

    final visit = FieldVisit.fromJson({
      'id': 'fv-1',
      'date': '2026-11-12',
      'clientName': 'Acme Warehouse',
      'purpose': 'Router check',
      'latitude': 19.115,
      'longitude': 72.865,
      'status': 'ACTIVE',
      'checkedInAt': '2026-11-12T08:00:00.000Z',
    });
    expect(visit.isCompleted, isFalse);
    expect(visit.clientName, 'Acme Warehouse');
  });

  testWidgets('Employee login, punch with geofence/selfie/biometrics, and navigation flow', (tester) async {
    final apiClient = ApiClient();
    await apiClient.init();
    final repo = HrmRepository(apiClient: apiClient);
    final state = AppState(repository: repo, deviceService: _FakeDeviceService());
    await state.initialize();

    await tester.pumpWidget(KeystoneEmployeeApp(appState: state));
    await tester.pumpAndSettle();

    expect(find.byType(KeystoneAppBadge), findsWidgets);
    expect(find.byType(KeystoneLogo), findsOneWidget);
    expect(find.text('Your workday, in one workspace.'), findsOneWidget);
    expect(find.text('Open offline preview'), findsNothing);
    expect(find.textContaining('employee@demo.com'), findsNothing);
    expect(tester.takeException(), isNull);

    await state.enterOfflineDemo();
    await tester.pumpAndSettle();

    expect(find.textContaining('Amit'), findsWidgets);
    expect(find.text('Clock In with App'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Navigate to Punch tab
    await tester.tap(find.text('Punch'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scroll PunchTab cleanly and trigger selfie + biometric verification + clock in
    final punchScrollable = find.descendant(
      of: find.byType(PunchTab),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text('Take selfie'), 120, scrollable: punchScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take selfie'));
    await tester.pumpAndSettle();
    expect(find.text('Face matched'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Verify'), 120, scrollable: punchScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Fingerprint verified'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Clock in now'), 120, scrollable: punchScrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clock in now'));
    await tester.pumpAndSettle();
    expect(find.text('Clock out now'), findsOneWidget);

    // Scroll to verify geofence card and field visit below the fold
    await tester.scrollUntilVisible(
      find.text('Surya Logistics Hub'),
      250,
      scrollable: punchScrollable,
    );
    expect(find.text('Surya Logistics Hub'), findsOneWidget);

    // Navigate across remaining tabs
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Leave & time off'), findsOneWidget);

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Net take-home pay'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Amit Patel'), findsOneWidget);

    await tester.tap(find.text('Amit Patel'));
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('Save contact details'), findsOneWidget);

    // Ensure no overflow or framework exceptions occurred
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
