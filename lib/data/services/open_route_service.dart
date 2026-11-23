import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OpenRouteResult {
  const OpenRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final mins = (durationSeconds / 60).round();
    if (mins < 1) return '<1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${hrs}h' : '${hrs}h ${rem}m';
  }
}

/// Real road routing via OSRM Open Router and reverse-geocoding via OpenStreetMap Nominatim.
class OpenRouteService {
  OpenRouteService({http.Client? client}) : _client = client ?? http.Client();

  static const String _osrmBase = String.fromEnvironment(
    'KEYSTONE_OSRM_URL',
    defaultValue: 'https://router.project-osrm.org',
  );
  static const String _userAgent = 'KeystoneEmployee/1.0 (com.keystone.user)';

  final http.Client _client;
  final Map<String, OpenRouteResult> _routeCache = {};
  final Map<String, String> _geocodeCache = {};

  Future<OpenRouteResult?> fetchRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    final coordsKey = waypoints
        .map((p) => '${p.longitude.toStringAsFixed(4)},${p.latitude.toStringAsFixed(4)}')
        .join(';');
    if (_routeCache.containsKey(coordsKey)) {
      return _routeCache[coordsKey];
    }

    final coordParam = waypoints
        .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
        .join(';');

    final uri = Uri.parse(
      '$_osrmBase/route/v1/driving/$coordParam?overview=full&geometries=geojson',
    );

    try {
      final res = await _client.get(
        uri,
        headers: const {'User-Agent': _userAgent, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final primary = routes.first as Map<String, dynamic>;
      final geometry = primary['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List<dynamic>?;
      if (rawCoords == null || rawCoords.isEmpty) return null;

      final points = <LatLng>[];
      for (final item in rawCoords) {
        if (item is List && item.length >= 2) {
          final lng = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
      if (points.isEmpty) return null;

      final result = OpenRouteResult(
        points: points,
        distanceMeters: (primary['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (primary['duration'] as num?)?.toDouble() ?? 0,
      );
      _routeCache[coordsKey] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final key = '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
    if (_geocodeCache.containsKey(key)) {
      return _geocodeCache[key];
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
      'zoom': '16',
    });

    try {
      final res = await _client.get(
        uri,
        headers: const {'User-Agent': _userAgent, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      if (addr == null) return null;

      final area = (addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['road'] ??
              addr['city_district'] ??
              addr['town'] ??
              addr['village'])
          ?.toString();
      final city = (addr['city'] ?? addr['state_district'] ?? addr['state'])?.toString();

      final parts = [
        if (area != null && area.isNotEmpty) area,
        if (city != null && city.isNotEmpty && city != area) city,
      ];
      if (parts.isEmpty) return null;

      final label = parts.join(', ');
      _geocodeCache[key] = label;
      return label;
    } catch (_) {
      return null;
    }
  }
}

