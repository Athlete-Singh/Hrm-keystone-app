import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/services/open_route_service.dart';
import '../../../../domain/models/employee_models.dart';
import '../../../core/theme/keystone_theme.dart';
import '../../../core/widgets/keystone_ui.dart';

/// Interactive OpenStreetMap + OSRM Open Router map card showing real street tiles,
/// the true office geofence perimeter, live GPS position, field-visit pins, and road routing.
class GeofenceMapCard extends StatefulWidget {
  const GeofenceMapCard({
    super.key,
    required this.settings,
    required this.currentFix,
    required this.distanceMeters,
    required this.insideGeofence,
    required this.fieldVisits,
    required this.onRefreshGps,
    required this.isRefreshing,
    this.routeService,
  });

  final AttendanceSettings settings;
  final GeoLocationFix? currentFix;
  final int? distanceMeters;
  final bool insideGeofence;
  final List<FieldVisit> fieldVisits;
  final VoidCallback onRefreshGps;
  final bool isRefreshing;
  final OpenRouteService? routeService;

  @override
  State<GeofenceMapCard> createState() => _GeofenceMapCardState();
}

class _GeofenceMapCardState extends State<GeofenceMapCard> {
  final MapController _mapController = MapController();
  late final OpenRouteService _routeService;

  OpenRouteResult? _routeResult;
  String? _resolvedPlace;
  String _lastRouteKey = '';
  String _lastGeocodeKey = '';
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _routeService = widget.routeService ?? OpenRouteService();
    _syncRoutingAndGeocode();
  }

  @override
  void didUpdateWidget(covariant GeofenceMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coordsChanged = oldWidget.currentFix?.latitude != widget.currentFix?.latitude ||
        oldWidget.currentFix?.longitude != widget.currentFix?.longitude ||
        oldWidget.settings.officeLatitude != widget.settings.officeLatitude ||
        oldWidget.settings.officeLongitude != widget.settings.officeLongitude ||
        oldWidget.fieldVisits.length != widget.fieldVisits.length;

    if (coordsChanged) {
      _syncRoutingAndGeocode();
      if (_mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitCamera();
        });
      }
    }
  }

  LatLng get _officePoint {
    final sLat = widget.settings.officeLatitude;
    final sLng = widget.settings.officeLongitude;
    if (sLat != null && sLng != null) {
      return LatLng(sLat, sLng);
    }
    if (widget.currentFix != null) {
      return LatLng(widget.currentFix!.latitude, widget.currentFix!.longitude);
    }
    return const LatLng(19.1136, 72.8697);
  }

  LatLng? get _userPoint {
    final fix = widget.currentFix;
    if (fix == null) return null;
    return LatLng(fix.latitude, fix.longitude);
  }

  List<FieldVisit> get _mappableVisits {
    return widget.fieldVisits
        .where((v) => v.latitude.abs() > 0.001 || v.longitude.abs() > 0.001)
        .take(5)
        .toList();
  }

  List<LatLng> _buildRouteWaypoints() {
    final user = _userPoint;
    if (user == null) return const [];

    final visits = _mappableVisits;
    if (visits.isNotEmpty) {
      return [
        user,
        ...visits.map((v) => LatLng(v.latitude, v.longitude)),
      ];
    }

    if (widget.settings.officeLatitude != null && widget.settings.officeLongitude != null) {
      final office = _officePoint;
      final dist = calculateDistanceMeters(
        user.latitude,
        user.longitude,
        office.latitude,
        office.longitude,
      );
      if (dist >= 20) {
        return [user, office];
      }
    }
    return const [];
  }

  Future<void> _syncRoutingAndGeocode() async {
    final fix = widget.currentFix;
    if (fix != null) {
      final geoKey = '${fix.latitude.toStringAsFixed(3)},${fix.longitude.toStringAsFixed(3)}';
      if (geoKey != _lastGeocodeKey) {
        _lastGeocodeKey = geoKey;
        final place = await _routeService.reverseGeocode(
          latitude: fix.latitude,
          longitude: fix.longitude,
        );
        if (mounted && place != null && _lastGeocodeKey == geoKey) {
          setState(() => _resolvedPlace = place);
        }
      }
    }

    final waypoints = _buildRouteWaypoints();
    final routeKey = waypoints
        .map((p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}')
        .join('|');

    if (routeKey == _lastRouteKey) return;
    _lastRouteKey = routeKey;

    if (waypoints.length < 2) {
      if (mounted && _routeResult != null) {
        setState(() => _routeResult = null);
      }
      return;
    }

    final result = await _routeService.fetchRoute(waypoints);
    if (!mounted || _lastRouteKey != routeKey) return;
    setState(() => _routeResult = result);
    if (_mapReady && result != null && result.points.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitCamera();
      });
    }
  }

  void _fitCamera() {
    final points = <LatLng>[
      if (widget.settings.officeLatitude != null && widget.settings.officeLongitude != null)
        _officePoint,
      ?_userPoint,
      ..._mappableVisits.map((v) => LatLng(v.latitude, v.longitude)),
      if (_routeResult != null) ..._routeResult!.points,
    ];

    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    final spanLat = (bounds.north - bounds.south).abs();
    final spanLng = (bounds.east - bounds.west).abs();

    if (spanLat < 0.0015 && spanLng < 0.0015) {
      _mapController.move(bounds.center, 16.4);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(44, 52, 44, 52),
        maxZoom: 17.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.settings.geofenceRadiusMeters;
    final hasFix = widget.currentFix != null;
    final hasOffice = widget.settings.officeLatitude != null && widget.settings.officeLongitude != null;
    final userPoint = _userPoint;
    final visits = _mappableVisits;
    final waypoints = _buildRouteWaypoints();
    final routePoints = (_routeResult != null && _routeResult!.points.isNotEmpty)
        ? _routeResult!.points
        : waypoints;

    final statusLabel = !hasFix
        ? 'Locating GPS…'
        : widget.distanceMeters == null
            ? (_resolvedPlace ?? widget.currentFix!.addressLabel)
            : widget.insideGeofence
                ? 'Inside office · ${widget.distanceMeters} m'
                : 'Outside radius · ${widget.distanceMeters} m (limit $radius m)';

    final addressSummary = widget.currentFix == null
        ? 'Fetching coordinates…'
        : _resolvedPlace != null
            ? '$_resolvedPlace · ±${widget.currentFix!.accuracy.round()} m'
            : '${widget.currentFix!.addressLabel} · ±${widget.currentFix!.accuracy.round()} m';

    final isRunningTests = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    return KeystoneCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 224,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userPoint ?? _officePoint,
                      initialZoom: 16.0,
                      minZoom: 3,
                      maxZoom: 19,
                      backgroundColor: const Color(0xFFE7F3EC),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () {
                        _mapReady = true;
                        _fitCamera();
                      },
                    ),
                    children: [
                      if (!isRunningTests)
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.keystone.user',
                          maxNativeZoom: 19,
                          evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                          errorTileCallback: (_, _, _) {},
                        ),
                      if (hasOffice)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _officePoint,
                              radius: radius.toDouble(),
                              useRadiusInMeter: true,
                              color: KeystoneColors.emerald.withValues(alpha: 0.14),
                              borderColor: KeystoneColors.pine.withValues(alpha: 0.72),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: _routeResult != null ? 4.5 : 3.0,
                              color: _routeResult != null
                                  ? KeystoneColors.pine
                                  : KeystoneColors.pine.withValues(alpha: 0.72),
                              borderColor: Colors.white.withValues(alpha: 0.9),
                              borderStrokeWidth: _routeResult != null ? 1.5 : 0.0,
                              pattern: _routeResult != null
                                  ? const StrokePattern.solid()
                                  : StrokePattern.dashed(segments: const [8, 6]),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (hasOffice)
                            Marker(
                              point: _officePoint,
                              width: 52,
                              height: 30,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: KeystoneColors.pineDeep,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: KeystoneColors.pineDeep.withValues(alpha: 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'HQ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          for (var i = 0; i < visits.length; i++)
                            Marker(
                              point: LatLng(visits[i].latitude, visits[i].longitude),
                              width: 30,
                              height: 30,
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: visits[i].isCompleted ? KeystoneColors.indigo : KeystoneColors.ochre,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (userPoint != null)
                            Marker(
                              point: userPoint,
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: (widget.insideGeofence
                                            ? KeystoneColors.emerald
                                            : KeystoneColors.clay)
                                        .withValues(alpha: 0.26),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: widget.insideGeofence
                                          ? KeystoneColors.emerald
                                          : KeystoneColors.clay,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Top-left HQ & OpenRouter distance/ETA pills
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 92,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MapOverlayPill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.settings.geofenceEnabled
                                    ? Icons.radar_rounded
                                    : Icons.my_location_rounded,
                                size: 13,
                                color: KeystoneColors.emerald,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  widget.settings.officeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: KeystoneColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_routeResult != null)
                          _MapOverlayPill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.route_rounded, size: 13, color: KeystoneColors.pine),
                                const SizedBox(width: 4),
                                Text(
                                  '${_routeResult!.formattedDistance} · ${_routeResult!.formattedDuration}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: KeystoneColors.pineDeep,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Top-right Fit & GPS refresh buttons
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapActionButton(
                          tooltip: 'Center route',
                          onTap: _fitCamera,
                          child: const Icon(Icons.center_focus_strong_rounded,
                              size: 16, color: KeystoneColors.pineDeep),
                        ),
                        const SizedBox(width: 6),
                        _MapActionButton(
                          tooltip: 'Refresh GPS',
                          onTap: widget.isRefreshing ? null : widget.onRefreshGps,
                          child: widget.isRefreshing
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: KeystoneColors.pine,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16, color: KeystoneColors.pineDeep),
                        ),
                      ],
                    ),
                  ),

                  // Bottom status pill & OpenStreetMap/OSRM attribution
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: _MapOverlayPill(
                            radius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.insideGeofence
                                        ? KeystoneColors.emerald
                                        : KeystoneColors.clay,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    statusLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: KeystoneColors.ink,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _routeResult != null ? '© OSM · OpenRouter' : '© OpenStreetMap',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: KeystoneColors.muted,
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
          Container(
            color: KeystoneColors.surfaceSoft,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
            child: Row(
              children: [
                const KeystoneIconBadge(
                  icon: Icons.location_on_rounded,
                  background: KeystoneColors.skyTint,
                  color: KeystoneColors.sky,
                  size: 30,
                  iconSize: 16,
                  radius: 9,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    addressSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: KeystoneColors.ink),
                  ),
                ),
                if (widget.currentFix != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${widget.currentFix!.latitude.toStringAsFixed(4)}, ${widget.currentFix!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: KeystoneColors.muted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapOverlayPill extends StatelessWidget {
  const _MapOverlayPill({
    required this.child,
    this.radius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: KeystoneColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: KeystoneColors.pineDeep.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: KeystoneColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: KeystoneColors.pineDeep.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
