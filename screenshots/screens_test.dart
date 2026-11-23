// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrm_employee/data/repositories/hrm_repository.dart';
import 'package:hrm_employee/data/services/api_client.dart';
import 'package:hrm_employee/data/services/device_capabilities_service.dart';
import 'package:hrm_employee/domain/models/employee_models.dart';
import 'package:hrm_employee/main.dart';
import 'package:hrm_employee/ui/viewmodels/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScreenshotDeviceService implements DeviceCapabilitiesService {
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
      addressLabel: 'Office HQ · Andheri East',
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
      'Andheri East, Mumbai';

  @override
  Future<BiometricResult> verifyBiometric({
    required String reason,
    bool allowFallback = true,
  }) async {
    return const BiometricResult(verified: true, label: 'Fingerprint verified');
  }
}

class _ScreenshotRepository extends HrmRepository {
  _ScreenshotRepository({required super.apiClient});

  bool onlineBannerHidden = false;

  @override
  bool get isOfflineMode => onlineBannerHidden ? false : super.isOfflineMode;
}

Future<void> _loadFonts() async {
  const sdkFonts = '/Users/athletesingh/development/flutter/bin/cache/artifacts/material_fonts';
  const interDir = '/Users/athletesingh/Projects/bricks_app/bhatta-erp/mobile/assets/fonts';

  Future<ByteData> loadBytes(String path) async {
    final bytes = File(path).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }

  Future<void> registerInterAs(String family) async {
    final loader = FontLoader(family);
    for (final w in [400, 500, 600, 700, 800]) {
      loader.addFont(loadBytes('$interDir/Inter-$w.ttf'));
    }
    await loader.load();
  }

  // Register full-glyph Inter font across every fallback alias Flutter/Theme uses
  await registerInterAs('Inter');
  await registerInterAs('-apple-system');
  await registerInterAs('BlinkMacSystemFont');
  await registerInterAs('sans-serif');
  await registerInterAs('FlutterTest');
  await registerInterAs('Ahem');

  final roboto = FontLoader('Roboto');
  for (final file in [
    'Roboto-Thin.ttf',
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]) {
    roboto.addFont(loadBytes('$sdkFonts/$file'));
  }
  await roboto.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(loadBytes('$sdkFonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture Keystone Employee screens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    debugDisableShadows = false;
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.reset();
    });

    final apiClient = ApiClient();
    await apiClient.init();
    final repo = _ScreenshotRepository(apiClient: apiClient);
    final state = AppState(
      repository: repo,
      deviceService: _ScreenshotDeviceService(),
    );
    await state.initialize();

    await tester.pumpWidget(KeystoneEmployeeApp(appState: state));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/login.png'),
    );

    await state.enterOfflineDemo();
    repo.onlineBannerHidden = true;
    await state.refreshLocation();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/home.png'),
    );

    await tester.tap(find.text('Leave'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/leave.png'),
    );

    await tester.tap(find.text('Pay'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/payslips.png'),
    );

    await tester.tap(find.text('More'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/more.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  });
}
