import 'package:flutter/material.dart';

import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.appState.profile?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.appState.profile?.homeAddress ?? '');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.appState.updateMyProfile(
        contactNumber: _phoneCtrl.text.trim(),
        homeAddress: _addressCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.appState.profile;
    final user = widget.appState.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: KeystoneCornerActions(
              appState: widget.appState,
              compact: true,
              onProfilePressed: () => widget.appState.loadProfile(),
            ),
          ),
        ],
      ),
      body: KeystoneBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              KeystoneCard(
                borderRadius: 20,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF123E2E), Color(0xFF166534)],
                ),
                child: Row(
                  children: [
                    KeystoneAvatar(initials: p?.avatarInitials ?? user?.avatarInitials ?? 'EM', size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p?.name ?? user?.name ?? 'Employee',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p != null ? '${p.designation} · ${p.department}' : (user?.email ?? ''),
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.80)),
                          ),
                          const SizedBox(height: 8),
                          if (p != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.status,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const KeystoneSectionHeader(title: 'Employment details', accentColor: KeystoneColors.emerald),
              const SizedBox(height: 10),
              KeystoneCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _InfoRow('Work email', p?.email ?? user?.email ?? '—', tinted: true),
                    _InfoRow('Employee ID', p?.employeeId.isNotEmpty == true ? p!.employeeId : '—'),
                    _InfoRow('Department', p?.department ?? '—', tinted: true),
                    _InfoRow('Reporting manager', p?.managerName ?? 'Not assigned'),
                    _InfoRow('Work location', p?.location.isNotEmpty == true ? p!.location : '—', tinted: true),
                    _InfoRow(
                      'Joined',
                      p != null && p.joinedAt.length >= 10 ? p.joinedAt.substring(0, 10) : '—',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const KeystoneSectionHeader(title: 'Contact information', accentColor: KeystoneColors.indigo),
              const SizedBox(height: 10),
              KeystoneCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+91 98204 51120',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18, color: KeystoneColors.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Home address',
                        hintText: 'Street, city, postal code',
                        prefixIcon: Icon(Icons.home_outlined, size: 18, color: KeystoneColors.muted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    KeystoneGradientButton(
                      onPressed: _saving ? null : _save,
                      busy: _saving,
                      label: 'Save contact details',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.tinted = false});

  final String label;
  final String value;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tinted ? KeystoneColors.surfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: KeystoneColors.muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: KeystoneColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
