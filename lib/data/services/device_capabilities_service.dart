import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/models/employee_models.dart';

/// Abstracts hardware capabilities (GPS, Front Camera, Biometrics) so physical phones use
/// real sensors while simulators, desktop builds, and tests degrade gracefully.
abstract class DeviceCapabilitiesService {
  Future<GeoLocationFix> captureLocation({
    double? officeLat,
    double? officeLng,
    String? officeName,
  });

  Future<SelfieCaptureResult?> captureSelfie({bool allowFallback = false});

  Future<BiometricResult> verifyBiometric({
    required String reason,
    bool allowFallback = true,
  });

  String describeLocation({
    required double latitude,
    required double longitude,
    double? officeLat,
    double? officeLng,
    String? officeName,
  });
}

class DefaultDeviceCapabilitiesService implements DeviceCapabilitiesService {
  DefaultDeviceCapabilitiesService({
    ImagePicker? picker,
    LocalAuthentication? localAuth,
  })  : _picker = picker ?? ImagePicker(),
        _localAuth = localAuth ?? LocalAuthentication();

  final ImagePicker _picker;
  final LocalAuthentication _localAuth;

  static const double _fallbackLat = 19.1136;
  static const double _fallbackLng = 72.8697;

  @override
  String describeLocation({
    required double latitude,
    required double longitude,
    double? officeLat,
    double? officeLng,
    String? officeName,
  }) {
    if (officeLat != null && officeLng != null) {
      final meters = calculateDistanceMeters(latitude, longitude, officeLat, officeLng);
      if (meters <= 350) {
        return '${officeName ?? "Office HQ"} · Within geofence';
      }
      if (meters <= 2500) {
        return 'Near ${officeName ?? "Office HQ"} (${(meters / 1000).toStringAsFixed(1)} km)';
      }
    }
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lngDir';
  }

  @override
  Future<GeoLocationFix> captureLocation({
    double? officeLat,
    double? officeLng,
    String? officeName,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _simulatedFix(officeLat, officeLng, officeName);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return _simulatedFix(officeLat, officeLng, officeName);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return GeoLocationFix(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        addressLabel: describeLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          officeLat: officeLat,
          officeLng: officeLng,
          officeName: officeName,
        ),
      );
    } catch (_) {
      return _simulatedFix(officeLat, officeLng, officeName);
    }
  }

  GeoLocationFix _simulatedFix(double? officeLat, double? officeLng, String? officeName) {
    final lat = officeLat != null ? officeLat + 0.00028 : _fallbackLat;
    final lng = officeLng != null ? officeLng + 0.00022 : _fallbackLng;
    return GeoLocationFix(
      latitude: lat,
      longitude: lng,
      accuracy: 14,
      addressLabel: describeLocation(
        latitude: lat,
        longitude: lng,
        officeLat: officeLat,
        officeLng: officeLng,
        officeName: officeName,
      ),
      isSimulated: true,
    );
  }

  @override
  Future<SelfieCaptureResult?> captureSelfie({bool allowFallback = false}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 65,
        maxWidth: 640,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final encoded = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return SelfieCaptureResult(dataUrl: encoded, bytesLength: bytes.length);
    } catch (_) {
      // Simulators and desktop environments often lack camera hardware.
      if (!allowFallback && !kDebugMode) return null;
      const sample = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      return const SelfieCaptureResult(
        dataUrl: sample,
        bytesLength: 68,
        isSimulated: true,
      );
    }
  }

  @override
  Future<BiometricResult> verifyBiometric({
    required String reason,
    bool allowFallback = true,
  }) async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) {
        if (allowFallback) {
          return const BiometricResult(verified: true, label: 'Device verified', isSimulated: true);
        }
        return const BiometricResult(verified: false, label: 'Biometrics unavailable');
      }
      final biometrics = await _localAuth.getAvailableBiometrics();
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      final label = biometrics.contains(BiometricType.face)
          ? 'Face ID verified'
          : biometrics.contains(BiometricType.fingerprint) || biometrics.contains(BiometricType.strong)
              ? 'Fingerprint verified'
              : 'Device pass verified';
      return BiometricResult(verified: ok, label: ok ? label : 'Verification cancelled');
    } catch (_) {
      if (allowFallback) {
        return const BiometricResult(verified: true, label: 'Biometric verified (simulator)', isSimulated: true);
      }
      return const BiometricResult(verified: false, label: 'Biometric error');
    }
  }
}

