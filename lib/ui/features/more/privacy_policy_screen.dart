import 'package:flutter/material.dart';

import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key, this.appState});

  final AppState? appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        actions: [
          if (appState != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: KeystoneCornerActions(
                appState: appState!,
                compact: true,
              ),
            ),
        ],
      ),
      body: KeystoneBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: const [
            KeystoneCard(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  KeystoneAppBadge(size: 42, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keystone Employee Data Handling',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'How workplace attendance, location, camera, and payroll records are protected.',
                          style: TextStyle(fontSize: 12.5, color: KeystoneColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            _PolicySectionCard(
              icon: Icons.badge_outlined,
              tint: KeystoneColors.pineTint,
              accent: KeystoneColors.pine,
              title: 'Employee profile & HR records',
              body:
                  'Your name, work email, employee ID, department, attendance logs, leave requests, payslips, and company documents belong to your employing workspace on Keystone and are synced over HTTPS.',
            ),
            SizedBox(height: 10),
            _PolicySectionCard(
              icon: Icons.location_on_outlined,
              tint: KeystoneColors.skyTint,
              accent: KeystoneColors.sky,
              title: 'Location & geofence verification',
              body:
                  'Foreground GPS location is read only when you open Attendance/Field Visits, refresh the map, or punch in/out. Coordinates may be sent to OpenStreetMap / OSRM solely to display street maps and road routes. No background location tracking occurs.',
            ),
            SizedBox(height: 10),
            _PolicySectionCard(
              icon: Icons.photo_camera_outlined,
              tint: KeystoneColors.ochreTint,
              accent: KeystoneColors.ochre,
              title: 'Camera & verification selfies',
              body:
                  'Your camera is accessed only when you choose to take an attendance verification selfie or attach a field visit check-in photo.',
            ),
            SizedBox(height: 10),
            _PolicySectionCard(
              icon: Icons.fingerprint_rounded,
              tint: KeystoneColors.violetTint,
              accent: KeystoneColors.violet,
              title: 'On-device biometrics',
              body:
                  'Face ID and fingerprint checks run exclusively through Android BiometricPrompt / iOS LocalAuthentication. Biometric data never leaves your device.',
            ),
            SizedBox(height: 10),
            _PolicySectionCard(
              icon: Icons.delete_outline_rounded,
              tint: KeystoneColors.clayTint,
              accent: KeystoneColors.clay,
              title: 'Data retention & account deletion',
              body:
                  'Keystone does not sell employee data or show third-party ads. To request correction or deletion of your workspace account or personal records, submit a ticket in Helpdesk & HR Queries or contact your organization’s HR administrator.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({
    required this.icon,
    required this.tint,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tint;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return KeystoneCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeystoneIconBadge(
            icon: icon,
            background: tint,
            color: accent,
            size: 38,
            iconSize: 19,
            radius: 11,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KeystoneColors.ink)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12.5, height: 1.45, color: KeystoneColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

