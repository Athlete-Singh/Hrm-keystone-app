import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_objects.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import 'widgets/geofence_map_card.dart';
import 'widgets/punch_sheets.dart';

class PunchTab extends StatefulWidget {
  const PunchTab({super.key, required this.appState});

  final AppState appState;

  @override
  State<PunchTab> createState() => _PunchTabState();
}

class _PunchTabState extends State<PunchTab> {
  final GlobalKey _punchButtonKey = GlobalKey();
  late int _lastFocusTick;

  @override
  void initState() {
    super.initState();
    _lastFocusTick = widget.appState.punchFocusTick;
    widget.appState.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToPunchButton());
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (widget.appState.punchFocusTick != _lastFocusTick) {
      _lastFocusTick = widget.appState.punchFocusTick;
      _scrollToPunchButton();
    }
  }

  void _scrollToPunchButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _punchButtonKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  Future<void> _handlePunch(bool isCheckOut) async {
    try {
      await widget.appState.performPunch(isCheckOut: isCheckOut);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCheckOut ? 'Clocked out and saved.' : 'Clocked in successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Field mode')) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Outside office geofence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: Text(msg, style: const TextStyle(fontSize: 13.5, color: KeystoneColors.muted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  widget.appState.setPunchMethod(PunchMethod.field);
                  Navigator.pop(ctx);
                },
                child: const Text('Switch to Field mode'),
              ),
            ],
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _stepMonth(int delta) {
    final cur = DateTime(
      widget.appState.selectedAttendanceYear,
      widget.appState.selectedAttendanceMonth + 1,
      1,
    );
    final next = DateTime(cur.year, cur.month + delta, 1);
    widget.appState.loadAttendanceForMonth(next.year, next.month - 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final today = state.attendanceMonth?.myTodayStatus;
    final checkedIn = today?.checkedIn ?? false;
    final checkedOut = today?.checkedOut ?? false;
    final selfieBytes = state.todaySelfieBytes;

    return RefreshIndicator(
      color: KeystoneColors.pine,
      onRefresh: state.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          // 01 Live Clock & Ways to Punch Hero Card (borderless!)
          KeystoneCard(
            padding: EdgeInsets.zero,
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Soft mint-to-sky gradient header strip with isolated live clock (no list rebuilding!)
                _LiveClockHeader(
                  checkedIn: checkedIn,
                  checkedOut: checkedOut,
                  checkInTime: today?.checkInTime,
                  checkOutTime: today?.checkOutTime,
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ways to punch',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                      ),
                      const SizedBox(height: 10),
                      PunchMethodVisualCards(
                        selected: state.selectedMethod,
                        onSelect: state.setPunchMethod,
                      ),
                      const SizedBox(height: 14),

                      // Selfie + Biometric separate soft tonal cards (no Box border, no Divider!)
                      _CheckRowCard(
                        icon: Icons.camera_alt_rounded,
                        iconBg: KeystoneColors.skyTint,
                        iconFg: KeystoneColors.sky,
                        title: 'Selfie verification',
                        status: selfieBytes != null
                            ? (checkedOut
                                ? 'Face matched · Saved for today'
                                : (checkedIn
                                    ? 'Face matched · In at ${today?.checkInTime ?? "--:--"}'
                                    : 'Face matched'))
                            : 'Optional unless Selfie mode',
                        verified: selfieBytes != null,
                        previewBytes: selfieBytes,
                        actionLabel: selfieBytes != null ? 'Retake' : 'Take selfie',
                        onAction: () => state.captureSelfie(allowFallback: true),
                      ),
                      const SizedBox(height: 8),
                      _CheckRowCard(
                        icon: Icons.fingerprint_rounded,
                        iconBg: KeystoneColors.violetTint,
                        iconFg: KeystoneColors.violet,
                        title: 'Biometric scan',
                        status: state.biometricCheck?.verified == true
                            ? state.biometricCheck!.label
                            : 'Face ID or fingerprint check',
                        verified: state.biometricCheck?.verified == true,
                        actionLabel: state.biometricCheck?.verified == true ? 'Verified' : 'Verify',
                        onAction: () => state.runBiometricVerification(allowFallback: true),
                      ),

                      const SizedBox(height: 14),
                      KeyedSubtree(
                        key: _punchButtonKey,
                        child: KeystoneGradientButton(
                          onPressed: (state.isPunching || checkedOut) ? null : () => _handlePunch(checkedIn),
                          busy: state.isPunching,
                          icon: checkedIn ? Icons.logout_rounded : Icons.login_rounded,
                          colors: checkedIn && !checkedOut
                              ? const [Color(0xFF1F2937), Color(0xFF0F172A)]
                              : const [KeystoneColors.pineDeep, KeystoneColors.pine, Color(0xFF15803D)],
                          label: checkedOut
                              ? 'Attendance completed for today'
                              : checkedIn
                                  ? 'Clock out now'
                                  : 'Clock in now',
                        ),
                      ),
                      if (checkedOut) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: state.isPunching
                              ? null
                              : () async {
                                  await state.clockInAgain();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ready to clock in again for new shift.'),
                                      ),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: KeystoneColors.pine.withValues(alpha: 0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: KeystoneColors.pineDeep),
                          label: const Text(
                            'Clock in again / New shift',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: KeystoneColors.pineDeep,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // 04 Location & 05 Geofencing
          const KeystoneSectionHeader(title: 'Office geofence & GPS', accentColor: KeystoneColors.sky),
          const SizedBox(height: 10),
          GeofenceMapCard(
            settings: state.settings,
            currentFix: state.currentFix,
            distanceMeters: state.liveDistanceToOfficeMeters,
            insideGeofence: state.isInsideGeofence,
            fieldVisits: state.fieldVisits,
            isRefreshing: state.isRefreshingLocation,
            onRefreshGps: () => state.refreshLocation(),
          ),

          const SizedBox(height: 20),
          // 06 Live field staff visits
          KeystoneSectionHeader(
            title: 'Field visits (${state.fieldVisits.length} today)',
            accentColor: KeystoneColors.ochre,
            trailing: TextButton.icon(
              onPressed: () => showStartFieldVisitSheet(context, state),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: KeystoneColors.pineTint,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 15, color: KeystoneColors.pineDeep),
              label: const Text(
                'Log visit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KeystoneColors.pineDeep),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (state.fieldVisits.isEmpty)
            KeystoneEmptyState(
              icon: Icons.route_rounded,
              accentColor: KeystoneColors.ochre,
              tintColor: KeystoneColors.ochreTint,
              title: 'No field visits logged today',
              message: 'On the road? Check in at client sites with GPS coordinates and notes.',
              action: OutlinedButton.icon(
                onPressed: () => showStartFieldVisitSheet(context, state),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Start first visit'),
              ),
            )
          else
            for (var i = 0; i < state.fieldVisits.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _FieldVisitCard(
                visit: state.fieldVisits[i],
                onComplete: state.fieldVisits[i].isCompleted
                    ? null
                    : () => showCompleteFieldVisitSheet(
                          context,
                          state,
                          visitId: state.fieldVisits[i].id,
                          clientName: state.fieldVisits[i].clientName,
                        ),
              ),
            ],

          const SizedBox(height: 22),
          // Monthly Attendance Records + Month Stepper + Request Correction
          KeystoneSectionHeader(
            title: 'Attendance log',
            accentColor: KeystoneColors.indigo,
            trailing: TextButton(
              onPressed: () => showCorrectionRequestSheet(context, state),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Request correction',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: KeystoneColors.pine),
              ),
            ),
          ),
          const SizedBox(height: 10),
          KeystoneCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            borderRadius: 14,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _stepMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(
                      DateTime(state.selectedAttendanceYear, state.selectedAttendanceMonth + 1, 1),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _stepMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MonthlyAttendanceList(
            records: state.attendanceMonth?.records ?? const [],
            onTapRecord: (date) => showCorrectionRequestSheet(context, state, initialDate: date),
          ),
        ],
      ),
    );
  }
}

class _CheckRowCard extends StatelessWidget {
  const _CheckRowCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.status,
    required this.verified,
    required this.actionLabel,
    required this.onAction,
    this.previewBytes,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String status;
  final bool verified;
  final String actionLabel;
  final VoidCallback onAction;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: verified ? KeystoneColors.pineTint.withValues(alpha: 0.72) : KeystoneColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          if (previewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                previewBytes!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _iconCircle(),
              ),
            )
          else
            _iconCircle(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: verified ? KeystoneColors.pineDeep : KeystoneColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: verified ? KeystoneColors.pineDeep : KeystoneColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _iconCircle() {
    return KeystoneIconBadge(
      icon: verified ? Icons.check_circle_rounded : icon,
      background: verified ? Colors.white : iconBg,
      color: verified ? KeystoneColors.emerald : iconFg,
      size: 36,
      iconSize: 18,
      radius: 11,
    );
  }
}

class _FieldVisitCard extends StatelessWidget {
  const _FieldVisitCard({required this.visit, this.onComplete});

  final FieldVisit visit;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(visit.checkedInAt);
    final timeStr = parsed != null ? DateFormat('h:mm a').format(parsed.toLocal()) : '';

    return KeystoneCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KeystoneIconBadge(
                icon: visit.isCompleted ? Icons.check_circle_rounded : Icons.near_me_rounded,
                background: visit.isCompleted ? KeystoneColors.wash : KeystoneColors.ochreTint,
                color: visit.isCompleted ? KeystoneColors.muted : KeystoneColors.ochre,
                size: 36,
                iconSize: 17,
                radius: 11,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.clientName,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                    ),
                    Text(
                      visit.purpose,
                      style: const TextStyle(fontSize: 12.5, color: KeystoneColors.muted),
                    ),
                  ],
                ),
              ),
              KeystoneBadge(
                label: visit.isCompleted ? 'Completed' : 'Live',
                tone: visit.isCompleted ? BadgeTone.neutral : BadgeTone.emerald,
                dotColor: visit.isCompleted ? null : KeystoneColors.emerald,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${visit.address ?? "${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}"} · $timeStr',
            style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
          ),
          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              visit.notes!,
              style: const TextStyle(fontSize: 12, color: KeystoneColors.muted, fontStyle: FontStyle.italic),
            ),
          ],
          if (!visit.isCompleted && onComplete != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Complete visit'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyAttendanceList extends StatelessWidget {
  const _MonthlyAttendanceList({
    required this.records,
    required this.onTapRecord,
  });

  final List<AttendanceRecord> records;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final items = records.where((r) => r.status != 'WEEKEND').toList();
    if (items.isEmpty) {
      return const KeystoneEmptyState(
        icon: Icons.calendar_view_day_rounded,
        accentColor: KeystoneColors.indigo,
        tintColor: KeystoneColors.indigoTint,
        title: 'No attendance logs for this month',
        message: 'Your punches and leave days for this month appear here.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          KeystoneCard(
            borderRadius: 15,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => onTapRecord(items[i].date),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 34,
                  decoration: BoxDecoration(
                    color: switch (items[i].status) {
                      'PRESENT' => KeystoneColors.emerald,
                      'LATE' || 'HALF_DAY' => KeystoneColors.ochre,
                      'ABSENT' => KeystoneColors.clay,
                      _ => KeystoneColors.subtle,
                    },
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].date,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].checkInMeta?.address ??
                            items[i].checkInMeta?.method ??
                            'Tap to request correction',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: KeystoneColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  items[i].clockIn != null ? '${items[i].clockIn} – ${items[i].clockOut ?? "…"}' : '—',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: KeystoneColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                KeystoneBadge(
                  label: items[i].status,
                  tone: switch (items[i].status) {
                    'PRESENT' => BadgeTone.emerald,
                    'LATE' || 'HALF_DAY' => BadgeTone.ochre,
                    'ABSENT' => BadgeTone.clay,
                    _ => BadgeTone.neutral,
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveClockHeader extends StatefulWidget {
  const _LiveClockHeader({
    required this.checkedIn,
    required this.checkedOut,
    this.checkInTime,
    this.checkOutTime,
  });

  final bool checkedIn;
  final bool checkedOut;
  final String? checkInTime;
  final String? checkOutTime;

  @override
  State<_LiveClockHeader> createState() => _LiveClockHeaderState();
}

class _LiveClockHeaderState extends State<_LiveClockHeader> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _elapsedDurationLabel(String? checkInTime) {
    if (checkInTime == null || !checkInTime.contains(':')) return '0h 00m';
    final parts = checkInTime.split(':');
    final h = int.tryParse(parts[0]) ?? 9;
    final m = int.tryParse(parts[1]) ?? 0;
    final start = DateTime(_now.year, _now.month, _now.day, h, m);
    final diff = _now.difference(start);
    if (diff.isNegative) return '0h 00m';
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm').format(_now);
    final amPm = DateFormat('a').format(_now);
    final dayLabel = DateFormat('EEEE, d MMMM').format(_now).toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5F6EC), Color(0xFFECF7F9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: KeystoneColors.pineDeep,
                ),
              ),
              const Spacer(),
              KeystoneBadge(
                label: widget.checkedOut
                    ? 'Done for today'
                    : widget.checkedIn
                        ? 'Shift · ${_elapsedDurationLabel(widget.checkInTime)}'
                        : 'Ready to punch',
                tone: widget.checkedOut
                    ? BadgeTone.neutral
                    : widget.checkedIn
                        ? BadgeTone.emerald
                        : BadgeTone.ochre,
                dotColor: widget.checkedIn && !widget.checkedOut ? KeystoneColors.emerald : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.4,
                  color: KeystoneColors.pineDeep,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                amPm,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: KeystoneColors.pine,
                ),
              ),
              const Spacer(),
              if (widget.checkedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'In ${widget.checkInTime ?? "--:--"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: KeystoneColors.pineDeep,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (widget.checkedOut)
                        Text(
                          'Out ${widget.checkOutTime ?? "--:--"}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: KeystoneColors.muted,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
