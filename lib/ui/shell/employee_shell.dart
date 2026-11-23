import 'package:flutter/material.dart';

import '../core/theme/keystone_theme.dart';
import '../core/widgets/keystone_corner_actions.dart';
import '../core/widgets/keystone_ui.dart';
import '../features/attendance/punch_tab.dart';
import '../features/home/home_tab.dart';
import '../features/leave/leave_tab.dart';
import '../features/more/more_tab.dart';
import '../features/pay_docs/pay_docs_tab.dart';
import '../viewmodels/app_state.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _index = 0;

  void _setIndex(int i) {
    if (i == 1) {
      widget.appState.requestPunchButtonFocus();
    }
    setState(() => _index = i);
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const KeystoneLogo(size: 19),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: KeystoneColors.pineTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EMPLOYEE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: KeystoneColors.pineDeep,
              ),
            ),
          ),
          const Spacer(),
          KeystoneCornerActions(appState: widget.appState),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        return KeystoneBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: false,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopHeader(context),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      children: [
                        HomeTab(
                          appState: widget.appState,
                          onJumpToTab: _setIndex,
                        ),
                        PunchTab(appState: widget.appState),
                        LeaveTab(appState: widget.appState),
                        PayDocsTab(appState: widget.appState),
                        MoreTab(appState: widget.appState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: KeystoneColors.surface.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: KeystoneColors.pineDeep.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: KeystoneColors.pineTint,
                selectedIndex: _index,
                onDestinationSelected: _setIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined, color: KeystoneColors.muted),
                    selectedIcon: Icon(Icons.home_rounded, color: KeystoneColors.pineDeep),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.fingerprint_outlined, color: KeystoneColors.muted),
                    selectedIcon: Icon(Icons.fingerprint_rounded, color: KeystoneColors.pineDeep),
                    label: 'Punch',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.event_note_outlined, color: KeystoneColors.muted),
                    selectedIcon: Icon(Icons.event_note_rounded, color: KeystoneColors.ochre),
                    label: 'Leave',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined, color: KeystoneColors.muted),
                    selectedIcon: Icon(Icons.receipt_long_rounded, color: KeystoneColors.indigo),
                    label: 'Pay',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined, color: KeystoneColors.muted),
                    selectedIcon: Icon(Icons.grid_view_rounded, color: KeystoneColors.pineDeep),
                    label: 'More',
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
