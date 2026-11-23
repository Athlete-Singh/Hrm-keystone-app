import 'package:flutter/material.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class TimesheetsScreen extends StatefulWidget {
  const TimesheetsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<TimesheetsScreen> createState() => _TimesheetsScreenState();
}

class _TimesheetsScreenState extends State<TimesheetsScreen> {
  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  bool _saving = false;

  Future<void> _addRowDialog() async {
    final clientCtrl = TextEditingController(text: 'Internal');
    final projectCtrl = TextEditingController();
    final taskCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '8');
    int dayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    bool billable = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Log task hours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client')),
                const SizedBox(height: 10),
                TextField(
                  controller: projectCtrl,
                  decoration: const InputDecoration(labelText: 'Project *', hintText: 'e.g. Keystone Mobile'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(labelText: 'Task *', hintText: 'e.g. Field check-in workflow'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: dayIndex,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: List.generate(
                          7,
                          (i) => DropdownMenuItem(value: i, child: Text(_dayLabels[i])),
                        ),
                        onChanged: (v) => setModal(() => dayIndex = v ?? 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: hoursCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Hours'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: KeystoneColors.pine,
                  title: const Text('Billable hours', style: TextStyle(fontSize: 13.5)),
                  value: billable,
                  onChanged: (v) => setModal(() => billable = v),
                ),
                const SizedBox(height: 10),
                KeystoneGradientButton(
                  onPressed: () async {
                    if (projectCtrl.text.trim().isEmpty || taskCtrl.text.trim().isEmpty) return;
                    final hrs = double.tryParse(hoursCtrl.text.trim()) ?? 0;
                    final list = List<double>.filled(7, 0);
                    list[dayIndex] = hrs.clamp(0, 24);
                    final nextRows = [
                      ...widget.appState.timesheet.rows,
                      TimesheetRowItem(
                        client: clientCtrl.text.trim().isEmpty ? 'Internal' : clientCtrl.text.trim(),
                        project: projectCtrl.text.trim(),
                        task: taskCtrl.text.trim(),
                        hours: list,
                        isBillable: billable,
                      ),
                    ];
                    Navigator.pop(ctx);
                    setState(() => _saving = true);
                    try {
                      await widget.appState.saveTimesheetRows(nextRows);
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                  label: 'Save task entry',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final ts = widget.appState.timesheet;
        final canEdit = ts.status == 'DRAFT' || ts.status == 'REJECTED';

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('My timesheet'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: KeystoneCornerActions(
                  appState: widget.appState,
                  compact: true,
                ),
              ),
            ],
          ),
          body: KeystoneBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  KeystoneCard(
                    borderRadius: 20,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Week of ${ts.weekStartDate}',
                                style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.78)),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${ts.totalHours.toStringAsFixed(1)} hours logged',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ts.status,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  KeystoneSectionHeader(
                    title: 'Logged tasks',
                    accentColor: KeystoneColors.indigo,
                    trailing: canEdit
                        ? TextButton.icon(
                            onPressed: _saving ? null : _addRowDialog,
                            icon: const Icon(Icons.add_rounded, size: 16, color: KeystoneColors.pine),
                            label: const Text(
                              'Add task',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: KeystoneColors.pine),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (ts.rows.isEmpty)
                    KeystoneEmptyState(
                      icon: Icons.task_alt_rounded,
                      accentColor: KeystoneColors.indigo,
                      tintColor: KeystoneColors.indigoTint,
                      title: 'No tasks logged this week',
                      message: 'Add your project tasks to submit weekly hours.',
                      action: OutlinedButton.icon(
                        onPressed: canEdit ? _addRowDialog : null,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add task'),
                      ),
                    )
                  else
                    for (var i = 0; i < ts.rows.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      KeystoneCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const KeystoneIconBadge(
                              icon: Icons.check_circle_outline_rounded,
                              background: KeystoneColors.indigoTint,
                              color: KeystoneColors.indigo,
                              size: 36,
                              iconSize: 18,
                              radius: 11,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ts.rows[i].task,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ts.rows[i].client} · ${ts.rows[i].project}${ts.rows[i].isBillable ? " · Billable" : ""}',
                                    style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            KeystoneBadge(
                              label: '${ts.rows[i].totalHours.toStringAsFixed(1)} h',
                              tone: BadgeTone.pine,
                            ),
                          ],
                        ),
                      ),
                    ],
                  if (canEdit && ts.rows.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    KeystoneGradientButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              try {
                                await widget.appState.submitTimesheet();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Weekly timesheet submitted.')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      busy: _saving,
                      label: 'Submit week for approval',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
