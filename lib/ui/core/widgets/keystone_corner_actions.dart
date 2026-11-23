import 'package:flutter/material.dart';

import '../../features/more/notifications_screen.dart';
import '../../features/more/profile_screen.dart';
import '../../viewmodels/app_state.dart';
import '../theme/keystone_theme.dart';
import 'keystone_ui.dart';

/// Top-right corner action group consisting of the notification bell with live unread badge
/// and the employee's profile avatar. Consistent across every screen in the app.
class KeystoneCornerActions extends StatelessWidget {
  const KeystoneCornerActions({
    super.key,
    required this.appState,
    this.compact = false,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  final AppState appState;
  final bool compact;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final user = appState.user;
        final unread = appState.unreadNotificationsCount;
        final size = compact ? 36.0 : 40.0;
        final iconSize = compact ? 19.0 : 22.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: KeystoneColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: KeystoneColors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: 'Notifications',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: size, minHeight: size),
                onPressed: () {
                  if (onNotificationPressed != null) {
                    onNotificationPressed!();
                  } else {
                    appState.refreshNotifications();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NotificationsScreen(appState: appState)),
                    );
                  }
                },
                icon: Badge(
                  isLabelVisible: unread > 0,
                  backgroundColor: KeystoneColors.coral,
                  label: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: TextStyle(
                      fontSize: compact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: KeystoneColors.ink,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (onProfilePressed != null) {
                  onProfilePressed!();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProfileScreen(appState: appState)),
                  );
                }
              },
              child: KeystoneAvatar(
                initials: user?.avatarInitials ?? 'EM',
                size: size,
              ),
            ),
          ],
        );
      },
    );
  }
}

