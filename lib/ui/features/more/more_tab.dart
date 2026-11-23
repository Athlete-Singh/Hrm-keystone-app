import 'package:flutter/material.dart';

import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import 'helpdesk_screen.dart';
import 'holidays_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';
import 'timesheets_screen.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key, required this.appState});

  final AppState appState;

  Future<void> _showServerUrlDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: appState.backendUrl);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keystone server URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'http://localhost:3000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await appState.updateBackendUrl(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final nextCtrl = TextEditingController();
    String? err;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Change password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password (min 8 chars)'),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: KeystoneColors.clay, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nextCtrl.text.length < 8) {
                  setDialog(() => err = 'Use at least 8 characters.');
                  return;
                }
                try {
                  await appState.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: nextCtrl.text,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated.')),
                    );
                  }
                } catch (e) {
                  setDialog(() => err = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = appState.user;
    final profile = appState.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
      children: [
        const Text(
          'Workspace',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        const SizedBox(height: 14),

        // Colorful Employee Profile Summary Card
        KeystoneCard(
          borderRadius: 20,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF123E2E), Color(0xFF166534)],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfileScreen(appState: appState)),
          ),
          child: Row(
            children: [
              KeystoneAvatar(initials: user?.avatarInitials ?? 'EM', size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? user?.name ?? 'Employee',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile != null
                          ? '${profile.designation} · ${profile.department}'
                          : (user?.email ?? ''),
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.78)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (profile?.employeeId.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile!.employeeId,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        if (profile?.location.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: KeystoneColors.gold.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile!.location,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFEF08A)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22, color: Colors.white.withValues(alpha: 0.78)),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const KeystoneSectionHeader(title: 'Employee tools', accentColor: KeystoneColors.pine),
        const SizedBox(height: 10),
        _NavCard(
          icon: Icons.schedule_rounded,
          iconBg: KeystoneColors.indigoTint,
          iconFg: KeystoneColors.indigo,
          title: 'My tasks & timesheet',
          subtitle: 'Weekly log (${appState.timesheet.totalHours.toStringAsFixed(1)} h)',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TimesheetsScreen(appState: appState)),
          ),
        ),
        const SizedBox(height: 9),
        _NavCard(
          icon: Icons.celebration_rounded,
          iconBg: KeystoneColors.clayTint,
          iconFg: KeystoneColors.clay,
          title: 'Holiday calendar',
          subtitle: 'Public and company-wide paid holidays',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HolidaysScreen(appState: appState)),
          ),
        ),
        const SizedBox(height: 9),
        _NavCard(
          icon: Icons.notifications_active_rounded,
          iconBg: KeystoneColors.ochreTint,
          iconFg: KeystoneColors.ochre,
          title: 'Notifications',
          subtitle: appState.unreadNotificationsCount > 0
              ? '${appState.unreadNotificationsCount} unread updates'
              : 'All caught up',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NotificationsScreen(appState: appState)),
          ),
        ),
        const SizedBox(height: 9),
        _NavCard(
          icon: Icons.support_agent_rounded,
          iconBg: KeystoneColors.pineTint,
          iconFg: KeystoneColors.pine,
          title: 'Help & support desk',
          subtitle: '${appState.tickets.length} ticket(s)',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HelpdeskScreen(appState: appState)),
          ),
        ),

        const SizedBox(height: 20),
        const KeystoneSectionHeader(title: 'Punch verification preferences', accentColor: KeystoneColors.violet),
        const SizedBox(height: 10),
        KeystoneCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              Material(
                color: KeystoneColors.violetTint.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: KeystoneColors.violet,
                    title: const Text('Require Face ID / Fingerprint on punch', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Confirm biometrics before clock-in/out', style: TextStyle(fontSize: 12)),
                    value: appState.requireBiometricBeforePunch,
                    onChanged: appState.setBiometricRequired,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: KeystoneColors.skyTint.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: KeystoneColors.sky,
                    title: const Text('Always attach selfie on punch', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Prompt front camera on every punch', style: TextStyle(fontSize: 12)),
                    value: appState.requireSelfieOnMobilePunch,
                    onChanged: appState.setSelfieRequired,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const KeystoneSectionHeader(title: 'Account & connection', accentColor: KeystoneColors.sky),
        const SizedBox(height: 10),
        _NavCard(
          icon: Icons.privacy_tip_outlined,
          iconBg: KeystoneColors.pineTint,
          iconFg: KeystoneColors.pine,
          title: 'Privacy & data policy',
          subtitle: 'Permissions, encryption & account deletion',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PrivacyPolicyScreen(appState: appState)),
          ),
        ),
        const SizedBox(height: 9),
        _NavCard(
          icon: Icons.dns_rounded,
          iconBg: KeystoneColors.skyTint,
          iconFg: KeystoneColors.sky,
          title: 'Server endpoint',
          subtitle: appState.isOfflineDemo ? 'Offline preview mode' : appState.backendUrl,
          onTap: () => _showServerUrlDialog(context),
        ),
        if (!appState.isOfflineDemo) ...[
          const SizedBox(height: 9),
          _NavCard(
            icon: Icons.lock_rounded,
            iconBg: KeystoneColors.violetTint,
            iconFg: KeystoneColors.violet,
            title: 'Change password',
            subtitle: 'Update your sign-in credentials',
            onTap: () => _showPasswordDialog(context),
          ),
        ],
        const SizedBox(height: 9),
        KeystoneCard(
          backgroundColor: KeystoneColors.clayTint.withValues(alpha: 0.72),
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          onTap: appState.logout,
          child: const Row(
            children: [
              KeystoneIconBadge(
                icon: Icons.logout_rounded,
                background: Colors.white,
                color: KeystoneColors.clay,
                size: 38,
                iconSize: 18,
                radius: 11,
              ),
              SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: KeystoneColors.clay),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
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
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          KeystoneIconBadge(icon: icon, background: iconBg, color: iconFg, size: 38, iconSize: 18, radius: 11),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
