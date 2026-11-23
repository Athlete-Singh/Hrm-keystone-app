import 'package:flutter/material.dart';

import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import '../../../domain/models/employee_models.dart';
import 'widgets/notification_detail_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedTab = 'all';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appState.refreshNotifications(_selectedTab);
      _checkDeepLink();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.appState.loadMoreNotifications(_selectedTab);
    }
  }

  void _checkDeepLink() {
    final deepLinkId = widget.appState.pendingDeepLinkNotificationId;
    if (deepLinkId != null && deepLinkId.isNotEmpty) {
      final matches = widget.appState.notifications.where((n) => n.id == deepLinkId);
      if (matches.isNotEmpty) {
        widget.appState.clearPendingDeepLink();
        showNotificationDetailSheet(context, matches.first, widget.appState);
      }
    }
  }

  void _onTabChanged(String tabKey) {
    setState(() => _selectedTab = tabKey);
    widget.appState.refreshNotifications(tabKey);
  }

  Map<String, List<AppNotification>> _groupNotifications(List<AppNotification> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<AppNotification>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final n in list) {
      DateTime? dt;
      try {
        dt = DateTime.parse(n.createdAt).toLocal();
      } catch (_) {}

      if (dt != null) {
        final d = DateTime(dt.year, dt.month, dt.day);
        if (d.isAtSameMomentAs(today)) {
          groups['Today']!.add(n);
        } else if (d.isAtSameMomentAs(yesterday)) {
          groups['Yesterday']!.add(n);
        } else {
          groups['Earlier']!.add(n);
        }
      } else {
        groups['Earlier']!.add(n);
      }
    }

    for (final k in groups.keys) {
      groups[k]!.sort((a, b) {
        final aPin = a.pinned || a.priority == 'CRITICAL';
        final bPin = b.pinned || b.priority == 'CRITICAL';
        if (aPin && !bPin) return -1;
        if (!aPin && bPin) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return groups;
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: KeystoneColors.muted,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: KeystoneColors.wash,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: KeystoneColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> all) {
    if (_selectedTab == 'announcements') {
      return all.where((n) => n.type == 'ANNOUNCEMENT' || n.type == 'POLICY' || n.type == 'URGENT').toList();
    }
    if (_selectedTab == 'holidays') {
      return all.where((n) => n.type == 'HOLIDAY').toList();
    }
    if (_selectedTab == 'attendance') {
      return all.where((n) => n.type == 'SYSTEM' || n.kind == 'attendance' || n.kind == 'payroll' || n.kind == 'leave').toList();
    }
    if (_selectedTab == 'unread') {
      return all.where((n) => !n.read).toList();
    }
    return all;
  }

  String _formatTimestamp(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 2) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays == 0 && now.day == dt.day) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return 'Today at $hour:$minute $ampm';
      }
      if (diff.inDays == 1 || (diff.inDays < 2 && now.day != dt.day)) {
        return 'Yesterday';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final allItems = widget.appState.notifications;
        final items = _filterNotifications(allItems);
        final grouped = _groupNotifications(items);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (widget.appState.unreadNotificationsCount > 0)
                TextButton(
                  onPressed: widget.appState.markAllNotificationsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: KeystoneColors.pine, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 4),
                child: KeystoneCornerActions(
                  appState: widget.appState,
                  compact: true,
                  onNotificationPressed: () => widget.appState.refreshNotifications(_selectedTab),
                ),
              ),
            ],
          ),
          body: KeystoneBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  // Filter Chips Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          count: allItems.length,
                          isSelected: _selectedTab == 'all',
                          onTap: () => _onTabChanged('all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '📢 Announcements',
                          isSelected: _selectedTab == 'announcements',
                          onTap: () => _onTabChanged('announcements'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '🪔 Holidays',
                          isSelected: _selectedTab == 'holidays',
                          onTap: () => _onTabChanged('holidays'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '⏱️ Attendance & Pay',
                          isSelected: _selectedTab == 'attendance',
                          onTap: () => _onTabChanged('attendance'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '🔴 Unread',
                          count: widget.appState.unreadNotificationsCount,
                          isSelected: _selectedTab == 'unread',
                          onTap: () => _onTabChanged('unread'),
                        ),
                      ],
                    ),
                  ),

                  // Notifications List
                  Expanded(
                    child: RefreshIndicator(
                      color: KeystoneColors.pine,
                      onRefresh: () => widget.appState.refreshNotifications(_selectedTab),
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        children: [
                          if (items.isEmpty)
                            KeystoneEmptyState(
                              icon: Icons.notifications_none_rounded,
                              accentColor: KeystoneColors.ochre,
                              tintColor: KeystoneColors.ochreTint,
                              title: _selectedTab == 'unread'
                                  ? 'No unread notifications'
                                  : 'You are caught up',
                              message: _selectedTab == 'holidays'
                                  ? 'Upcoming festive holidays and office closures will appear here.'
                                  : 'Announcements, attendance, leave, and payroll alerts appear here.',
                            )
                          else ...[
                            for (final entry in grouped.entries) ...[
                              if (entry.value.isNotEmpty) ...[
                                _buildSectionHeader(entry.key, entry.value.length),
                                for (final item in entry.value) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Dismissible(
                                      key: ValueKey(item.id),
                                      direction: item.read ? DismissDirection.none : DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: KeystoneColors.emerald,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Mark read',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(Icons.done_all_rounded, color: Colors.white, size: 19),
                                          ],
                                        ),
                                      ),
                                      confirmDismiss: (_) async {
                                        await widget.appState.markNotificationRead(item.id);
                                        return false;
                                      },
                                      child: _NotificationCard(
                                        item: item,
                                        formattedTime: _formatTimestamp(item.createdAt),
                                        onRead: () => widget.appState.markNotificationRead(item.id),
                                        onAcknowledge: () => widget.appState.acknowledgeNotification(item.id),
                                        onTap: () => showNotificationDetailSheet(context, item, widget.appState),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                            if (widget.appState.isLoadingMoreNotifications)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: KeystoneColors.pine),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? KeystoneColors.pine : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? KeystoneColors.pine : KeystoneColors.hairline,
            width: 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: KeystoneColors.pine.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : KeystoneColors.ink,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : KeystoneColors.pineTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : KeystoneColors.pine,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.formattedTime,
    required this.onRead,
    required this.onAcknowledge,
    required this.onTap,
  });

  final AppNotification item;
  final String formattedTime;
  final VoidCallback onRead;
  final VoidCallback onAcknowledge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHoliday = item.type == 'HOLIDAY';
    final isUrgent = item.priority == 'URGENT' || item.type == 'URGENT';
    final isAcknowledged = item.isAcknowledged;
    final needsAck = item.requiresAck && !isAcknowledged;

    return KeystoneCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      backgroundColor: isHoliday ? KeystoneColors.paperWarm : KeystoneColors.surface,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              _buildLeadingBadge(),
              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.pinned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: KeystoneColors.pineTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded, size: 10, color: KeystoneColors.pine),
                                SizedBox(width: 2),
                                Text(
                                  'PINNED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: KeystoneColors.pine),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.red),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
                              color: KeystoneColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: KeystoneColors.muted),
                    ),
                  ],
                ),
              ),

              // Unread Dot
              if (!item.read)
                Container(
                  width: 8.5,
                  height: 8.5,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: KeystoneColors.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          // Body Content
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              item.body,
              style: const TextStyle(fontSize: 13, height: 1.35, color: KeystoneColors.muted),
            ),
          ),

          // Holiday Festive Dates Box
          if (isHoliday && (item.holidayFrom != null || item.reopenDate != null)) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: KeystoneColors.ochreTint.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KeystoneColors.ochre.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: KeystoneColors.ochre),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Closed: ${item.holidayFrom ?? 'TBD'} to ${item.holidayTo ?? 'TBD'}'
                        '${item.reopenDate != null ? ' • Reopens: ${item.reopenDate}' : ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5E00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Acknowledgment Button or Chip
          if (item.requiresAck) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: needsAck
                  ? ElevatedButton.icon(
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                      label: const Text(
                        'Acknowledge & Confirm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KeystoneColors.pine,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: KeystoneColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: KeystoneColors.emerald),
                          SizedBox(width: 4),
                          Text(
                            'Acknowledged',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: KeystoneColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeadingBadge() {
    if (item.icon != null && item.icon!.isNotEmpty && item.icon!.length <= 3) {
      // Emoji icon (like 🪔, 🚨, 📢)
      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: item.read ? KeystoneColors.wash : KeystoneColors.pineTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item.icon!,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    IconData iconData = Icons.notifications_active_rounded;
    Color iconColor = KeystoneColors.pine;
    Color iconBg = KeystoneColors.pineTint;

    if (item.type == 'HOLIDAY') {
      iconData = Icons.celebration_rounded;
      iconColor = KeystoneColors.ochre;
      iconBg = KeystoneColors.ochreTint;
    } else if (item.type == 'URGENT') {
      iconData = Icons.warning_amber_rounded;
      iconColor = Colors.red;
      iconBg = Colors.red.withValues(alpha: 0.12);
    } else if (item.type == 'POLICY') {
      iconData = Icons.policy_rounded;
      iconColor = Colors.purple;
      iconBg = Colors.purple.withValues(alpha: 0.12);
    } else if (item.kind == 'attendance') {
      iconData = Icons.timer_rounded;
    } else if (item.kind == 'payroll') {
      iconData = Icons.payments_rounded;
    } else if (item.kind == 'leave') {
      iconData = Icons.event_note_rounded;
    }

    if (item.read) {
      iconColor = KeystoneColors.muted;
      iconBg = KeystoneColors.wash;
      iconData = Icons.notifications_none_rounded;
    }

    return KeystoneIconBadge(
      icon: iconData,
      background: iconBg,
      color: iconColor,
      size: 38,
      iconSize: 19,
      radius: 12,
    );
  }
}
