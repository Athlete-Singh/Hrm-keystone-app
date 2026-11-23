import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_objects.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import '../more/holidays_screen.dart';
import '../more/notifications_screen.dart';
import '../more/timesheets_screen.dart';
import '../more/widgets/notification_detail_sheet.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.appState,
    required this.onJumpToTab,
  });

  final AppState appState;
  final ValueChanged<int> onJumpToTab;

  String _greetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = appState.user;
    final profile = appState.profile;
    final today = appState.attendanceMonth?.myTodayStatus;
    final checkedIn = today?.checkedIn ?? false;
    final checkedOut = today?.checkedOut ?? false;
    final dateLabel = DateFormat('EEE, d MMM').format(DateTime.now());

    final annualBalance = appState.leaveData.balances.where((b) => b.type == 'ANNUAL').firstOrNull;
    final sickBalance = appState.leaveData.balances.where((b) => b.type == 'SICK').firstOrNull;
    final pendingLeaveCount = appState.leaveData.requests.where((r) => r.status == 'PENDING').length;
    final activeVisitsCount = appState.fieldVisits.where((v) => !v.isCompleted).length;
    final distanceMeters = appState.liveDistanceToOfficeMeters;
    final insideOffice = appState.isInsideGeofence;

    final annualRatio = (annualBalance != null && annualBalance.total > 0)
        ? (annualBalance.remaining / annualBalance.total)
        : 0.75;

    final pinnedNotif = appState.notifications.where((n) {
      final isMatch = n.pinned || n.priority == 'CRITICAL' || n.type == 'HOLIDAY' || (n.requiresAck && !n.isAcknowledged);
      return isMatch && !appState.dismissedBannerIds.contains(n.id);
    }).firstOrNull;

    return RefreshIndicator(
      color: KeystoneColors.pine,
      onRefresh: appState.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
        children: [
          Text(
            dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KeystoneColors.pine),
          ),
          const SizedBox(height: 2),
          Text(
            '${_greetingPrefix()}, ${user?.firstName ?? "there"}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (profile != null)
            Text(
              '${profile.designation} · ${profile.department}',
              style: const TextStyle(fontSize: 13, color: KeystoneColors.muted),
            ),
          const SizedBox(height: 18),

          // Colorful Pine-to-Teal Hero Attendance Card (borderless, no vertical dividing line)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF123E2E),
                  Color(0xFF166534),
                  Color(0xFF0F766E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: KeystoneColors.pineDeep.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -18,
                  bottom: -36,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KeystoneColors.gold.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: checkedOut
                                          ? Colors.white70
                                          : checkedIn
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFFFDE047),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      checkedOut
                                          ? 'Shift completed'
                                          : checkedIn
                                              ? 'On duty · since ${today?.checkInTime ?? "--:--"}'
                                              : today?.onLeaveType != null
                                                  ? 'On ${today!.onLeaveType!.toLowerCase()} leave'
                                                  : 'Ready to clock in',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (distanceMeters != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: insideOffice
                                    ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
                                    : const Color(0xFFFDA4AF).withValues(alpha: 0.26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                insideOffice ? 'In office · $distanceMeters m' : 'Remote · $distanceMeters m',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroTimeTile(
                              icon: Icons.login_rounded,
                              iconColor: const Color(0xFF6EE7B7),
                              label: 'Clock in',
                              value: today?.checkInTime ?? '--:--',
                              sub: today?.checkInMeta?.address ??
                                  appState.currentFix?.addressLabel ??
                                  'Waiting for GPS',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeroTimeTile(
                              icon: Icons.logout_rounded,
                              iconColor: const Color(0xFFFDE047),
                              label: 'Clock out',
                              value: today?.checkOutTime ?? '--:--',
                              sub: checkedOut
                                  ? (today?.checkOutMeta?.method ?? 'Recorded')
                                  : (checkedIn ? 'Shift active' : '09:30 AM cutoff'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: appState.isPunching ? null : () => onJumpToTab(1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: KeystoneColors.pineDeep,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                          ),
                          icon: Icon(
                            checkedIn && !checkedOut ? Icons.logout_rounded : Icons.fingerprint_rounded,
                            size: 18,
                          ),
                          label: Text(
                            checkedOut
                                ? 'View Attendance & Visits'
                                : checkedIn
                                    ? 'Open Punch & Clock Out'
                                    : 'Clock In with App',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dismissible Pinned / Urgent Announcement Banner above At a Glance
          if (pinnedNotif != null) ...[
            const SizedBox(height: 18),
            _PinnedAnnouncementBanner(notif: pinnedNotif, appState: appState),
          ],

          const SizedBox(height: 20),
          const KeystoneSectionHeader(title: 'At a glance', accentColor: KeystoneColors.emerald),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: KeystoneCard(
                  onTap: () => onJumpToTab(2),
                  padding: const EdgeInsets.all(14),
                  backgroundColor: KeystoneColors.amberMist,
                  child: Row(
                    children: [
                      KeystoneRingGauge(
                        progress: annualRatio,
                        centerText: annualBalance != null ? annualBalance.remaining.toStringAsFixed(0) : '—',
                        color: KeystoneColors.ochre,
                        trackColor: KeystoneColors.ochreTint,
                        size: 46,
                        strokeWidth: 5,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Annual leave',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pendingLeaveCount > 0
                                  ? '$pendingLeaveCount pending'
                                  : sickBalance != null
                                      ? '+${sickBalance.remaining.toStringAsFixed(0)} sick left'
                                      : 'Days left',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KeystoneCard(
                  onTap: () => onJumpToTab(1),
                  padding: const EdgeInsets.all(14),
                  backgroundColor: KeystoneColors.skyTint.withValues(alpha: 0.72),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          activeVisitsCount > 0 ? Icons.near_me_rounded : Icons.route_rounded,
                          color: KeystoneColors.sky,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${appState.fieldVisits.length} visits',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: KeystoneColors.ink,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeVisitsCount > 0 ? '$activeVisitsCount live on road' : 'Log field visit',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF0369A1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const KeystoneSectionHeader(title: 'Quick actions', accentColor: KeystoneColors.indigo),
          const SizedBox(height: 10),

          // Borderless spaced colorful action tiles (zero Divider lines!)
          _QuickActionCard(
            icon: Icons.event_available_rounded,
            iconBg: KeystoneColors.ochreTint,
            iconFg: KeystoneColors.ochre,
            title: 'Apply for leave',
            subtitle: 'Full day, half day, or sick time off',
            onTap: () => onJumpToTab(2),
          ),
          const SizedBox(height: 9),
          _QuickActionCard(
            icon: Icons.receipt_long_rounded,
            iconBg: KeystoneColors.indigoTint,
            iconFg: KeystoneColors.indigo,
            title: 'View latest payslip',
            subtitle: appState.payslip != null
                ? '${appState.payslip!.month} · Net ₹${appState.payslip!.netSalary.toStringAsFixed(0)}'
                : 'Salary breakdown and company docs',
            onTap: () => onJumpToTab(3),
          ),
          const SizedBox(height: 9),
          _QuickActionCard(
            icon: Icons.schedule_rounded,
            iconBg: KeystoneColors.pineTint,
            iconFg: KeystoneColors.pine,
            title: 'Weekly tasks & timesheet',
            subtitle: '${appState.timesheet.totalHours.toStringAsFixed(1)} hrs logged this week',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TimesheetsScreen(appState: appState)),
              );
            },
          ),
          const SizedBox(height: 9),
          _QuickActionCard(
            icon: Icons.celebration_rounded,
            iconBg: KeystoneColors.clayTint,
            iconFg: KeystoneColors.clay,
            title: 'Company holiday calendar',
            subtitle: '${appState.leaveData.holidays.length} upcoming holidays listed',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HolidaysScreen(appState: appState)),
              );
            },
          ),

          if (appState.notifications.isNotEmpty) ...[
            const SizedBox(height: 22),
            KeystoneSectionHeader(
              title: 'Recent updates',
              accentColor: KeystoneColors.coral,
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen(appState: appState)),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: KeystoneColors.pine),
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final n in appState.notifications.take(3)) ...[
              KeystoneCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => showNotificationDetailSheet(context, n, appState),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KeystoneIconBadge(
                      icon: n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                      background: n.read ? KeystoneColors.wash : KeystoneColors.pineTint,
                      color: n.read ? KeystoneColors.muted : KeystoneColors.pine,
                      size: 36,
                      iconSize: 17,
                      radius: 11,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                              color: KeystoneColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5, left: 6),
                        decoration: const BoxDecoration(color: KeystoneColors.emerald, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _HeroTimeTile extends StatelessWidget {
  const _HeroTimeTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.5, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.80)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KeystoneCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          KeystoneIconBadge(icon: icon, background: iconBg, color: iconFg, size: 40, iconSize: 19, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: KeystoneColors.ink)),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: KeystoneColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: KeystoneColors.subtle),
        ],
      ),
    );
  }
}

class _PinnedAnnouncementBanner extends StatelessWidget {
  const _PinnedAnnouncementBanner({
    required this.notif,
    required this.appState,
  });

  final AppNotification notif;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final isHoliday = notif.type == 'HOLIDAY' || notif.holidayFrom != null;
    final isUrgent = notif.priority == 'CRITICAL' || notif.type == 'URGENT' || (notif.requiresAck && !notif.isAcknowledged);

    final bgGradient = isHoliday
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
          )
        : isUrgent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE7F5EE), Color(0xFFF0FDF4)],
              );

    final borderColor = isHoliday
        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
        : isUrgent
            ? KeystoneColors.clay.withValues(alpha: 0.4)
            : KeystoneColors.emerald.withValues(alpha: 0.3);

    final emoji = isHoliday ? '🪔' : isUrgent ? '🚨' : '📢';
    final tagText = isHoliday
        ? 'Holiday Announcement'
        : isUrgent
            ? 'Urgent Notice'
            : 'Pinned Announcement';

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: KeystoneColors.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showNotificationDetailSheet(context, notif, appState),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      tagText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isHoliday
                            ? const Color(0xFFB45309)
                            : isUrgent
                                ? KeystoneColors.clay
                                : KeystoneColors.pineDeep,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: KeystoneColors.muted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Dismiss banner',
                      onPressed: () => appState.dismissBanner(notif.id),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KeystoneColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: KeystoneColors.muted, height: 1.4),
                ),
                if (isHoliday && notif.holidayFrom != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      'Closed: ${notif.holidayFrom} to ${notif.holidayTo ?? ''} · Reopens ${notif.reopenDate ?? ''}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
                if (notif.requiresAck && !notif.isAcknowledged) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KeystoneColors.clay,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Tap to Review & Acknowledge',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
