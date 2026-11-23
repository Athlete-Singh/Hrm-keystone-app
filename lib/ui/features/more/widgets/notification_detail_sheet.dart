import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/models/employee_models.dart';
import '../../../core/theme/keystone_theme.dart';
import '../../../core/widgets/keystone_ui.dart';
import '../../../viewmodels/app_state.dart';

void showNotificationDetailSheet(
  BuildContext context,
  AppNotification notif,
  AppState appState,
) {
  // Mark as read immediately when viewed
  if (!notif.read) {
    appState.markNotificationRead(notif.id);
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NotificationDetailSheet(notif: notif, appState: appState),
  );
}

class _NotificationDetailSheet extends StatefulWidget {
  const _NotificationDetailSheet({
    required this.notif,
    required this.appState,
  });

  final AppNotification notif;
  final AppState appState;

  @override
  State<_NotificationDetailSheet> createState() => _NotificationDetailSheetState();
}

class _NotificationDetailSheetState extends State<_NotificationDetailSheet> {
  bool _acknowledging = false;

  Future<void> _handleAcknowledge() async {
    setState(() => _acknowledging = true);
    try {
      await widget.appState.acknowledgeNotification(widget.notif.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement acknowledged successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record acknowledgment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open attachment URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening attachment: $e')),
        );
      }
    }
  }

  (Color tint, Color fg, IconData icon, String label) _getTypeInfo() {
    final type = (widget.notif.type ?? widget.notif.kind).toUpperCase();
    return switch (type) {
      'HOLIDAY' => (KeystoneColors.ochreTint, KeystoneColors.ochre, Icons.celebration_rounded, 'Holiday 🪔'),
      'URGENT' => (KeystoneColors.clayTint, KeystoneColors.clay, Icons.warning_amber_rounded, 'Urgent Alert 🚨'),
      'POLICY' => (KeystoneColors.indigoTint, KeystoneColors.indigo, Icons.article_outlined, 'Policy Update 📄'),
      'EVENT' => (const Color(0xFFEDE9FE), const Color(0xFF7C3AED), Icons.event_rounded, 'Event 🎉'),
      'REMINDER' => (KeystoneColors.skyTint, KeystoneColors.sky, Icons.alarm_rounded, 'Reminder ⏰'),
      'CELEBRATION' => (const Color(0xFFFCE7F3), const Color(0xFFDB2777), Icons.cake_rounded, 'Celebration 🎂'),
      'SYSTEM' => (KeystoneColors.pineTint, KeystoneColors.pine, Icons.info_outline_rounded, 'System Notice ⏱️'),
      _ => (KeystoneColors.pineTint, KeystoneColors.pine, Icons.campaign_rounded, 'Announcement 📢'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        // Look up updated notification in state for acknowledged status
        final currentNotif = widget.appState.notifications.firstWhere(
          (n) => n.id == widget.notif.id,
          orElse: () => widget.notif,
        );

        final (tint, fg, icon, label) = _getTypeInfo();
        final isHoliday = currentNotif.type == 'HOLIDAY' || currentNotif.holidayFrom != null;
        final isUrgent = currentNotif.priority == 'CRITICAL' || currentNotif.type == 'URGENT';

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: KeystoneColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: KeystoneColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with Type Badge, Pinned pill & Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14, color: fg),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentNotif.pinned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KeystoneColors.pineTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.push_pin_rounded, size: 12, color: KeystoneColors.pineDeep),
                            SizedBox(width: 4),
                            Text(
                              'PINNED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: KeystoneColors.pineDeep),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KeystoneColors.clayTint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: KeystoneColors.clay),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: KeystoneColors.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Scrollable Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Title
                    Text(
                      currentNotif.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: KeystoneColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      currentNotif.createdAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KeystoneColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Holiday Special Schedule Banner
                    if (isHoliday) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('🪔', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Text(
                                  'Holiday Office Schedule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_busy_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Closed: ${currentNotif.holidayFrom ?? 'TBD'} to ${currentNotif.holidayTo ?? 'TBD'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: KeystoneColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentNotif.reopenDate != null && currentNotif.reopenDate!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, size: 16, color: KeystoneColors.emerald),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Office Reopens: ${currentNotif.reopenDate}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: KeystoneColors.pineDeep,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Full Body Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KeystoneColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        currentNotif.body,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: KeystoneColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Attachment Viewer / Link
                    if (currentNotif.attachmentUrl != null && currentNotif.attachmentUrl!.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _openAttachment(currentNotif.attachmentUrl!),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KeystoneColors.skyTint.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: KeystoneColors.sky.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.attachment_rounded, color: KeystoneColors.sky, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View Attachment / Document',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: KeystoneColors.ink,
                                      ),
                                    ),
                                    Text(
                                      'Tap to download or preview',
                                      style: TextStyle(fontSize: 11.5, color: KeystoneColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, size: 18, color: KeystoneColors.sky),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Acknowledgment Action or Badge
                    if (currentNotif.requiresAck) ...[
                      if (currentNotif.isAcknowledged) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: KeystoneColors.emerald.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: KeystoneColors.emerald, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You acknowledged this announcement',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: KeystoneColors.pineDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        KeystoneGradientButton(
                          onPressed: _acknowledging ? null : _handleAcknowledge,
                          label: _acknowledging ? 'Confirming...' : 'Acknowledge & Confirm',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

