import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_objects.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class LeaveTab extends StatelessWidget {
  const LeaveTab({super.key, required this.appState});

  final AppState appState;

  String _typeLabel(String type) {
    return switch (type) {
      'ANNUAL' => 'Annual',
      'SICK' => 'Sick',
      'PERSONAL' => 'Personal',
      'UNPAID' => 'Unpaid',
      _ => type,
    };
  }

  Future<void> _showApplySheet(BuildContext context) async {
    String leaveType = 'ANNUAL';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    bool isHalfDay = false;
    String halfDayPeriod = 'FIRST_HALF';
    final reasonCtrl = TextEditingController();
    bool submitting = false;
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickDate(bool isStart) async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: isStart ? startDate : endDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setModalState(() {
                  if (isStart) {
                    startDate = picked;
                    if (endDate.isBefore(picked) || isHalfDay) {
                      endDate = picked;
                    }
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Apply for leave',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Leave type', style: TextStyle(fontSize: 12, color: KeystoneColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final t in ['ANNUAL', 'SICK', 'PERSONAL', 'UNPAID'])
                          ChoiceChip(
                            label: Text(_typeLabel(t)),
                            selected: leaveType == t,
                            onSelected: (_) => setModalState(() => leaveType = t),
                            selectedColor: KeystoneColors.pineTint,
                            backgroundColor: KeystoneColors.wash,
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: KeystoneColors.pine,
                      title: const Text('Half-day request', style: TextStyle(fontSize: 13.5)),
                      value: isHalfDay,
                      onChanged: (v) {
                        setModalState(() {
                          isHalfDay = v;
                          if (v) endDate = startDate;
                        });
                      },
                    ),
                    if (isHalfDay) ...[
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'FIRST_HALF', label: Text('Morning half')),
                          ButtonSegment(value: 'SECOND_HALF', label: Text('Afternoon half')),
                        ],
                        selected: {halfDayPeriod},
                        onSelectionChanged: (s) => setModalState(() => halfDayPeriod = s.first),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickDate(true),
                            icon: const Icon(Icons.calendar_today_outlined, size: 15),
                            label: Text(DateFormat('d MMM yyyy').format(startDate)),
                          ),
                        ),
                        if (!isHalfDay) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('to', style: TextStyle(color: KeystoneColors.muted)),
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate(false),
                              icon: const Icon(Icons.calendar_today_outlined, size: 15),
                              label: Text(DateFormat('d MMM yyyy').format(endDate)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason *',
                        hintText: 'Share a short note for your manager',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: const TextStyle(color: KeystoneColors.clay, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 14),
                    KeystoneGradientButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (reasonCtrl.text.trim().isEmpty) {
                                setModalState(() => errorText = 'Please enter a reason.');
                                return;
                              }
                              setModalState(() {
                                submitting = true;
                                errorText = null;
                              });
                              try {
                                final fmt = DateFormat('yyyy-MM-dd');
                                await appState.applyLeave(
                                  type: leaveType,
                                  startDate: fmt.format(startDate),
                                  endDate: fmt.format(isHalfDay ? startDate : endDate),
                                  reason: reasonCtrl.text.trim(),
                                  isHalfDay: isHalfDay,
                                  halfDayPeriod: isHalfDay ? halfDayPeriod : null,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Leave request submitted.')),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  submitting = false;
                                  errorText = e.toString().replaceFirst('Exception: ', '');
                                });
                              }
                            },
                      busy: submitting,
                      label: 'Submit leave request',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = appState.leaveData;
    final balances = data.balances.where((b) => b.type != 'UNPAID').toList();

    return RefreshIndicator(
      color: KeystoneColors.pine,
      onRefresh: appState.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave & time off',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                    ),
                    Text(
                      'Live quotas and time-off requests',
                      style: TextStyle(fontSize: 12.5, color: KeystoneColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              KeystoneGradientButton(
                onPressed: () => _showApplySheet(context),
                icon: Icons.add_rounded,
                label: 'Apply',
              ),
            ],
          ),
          const SizedBox(height: 18),

          const KeystoneSectionHeader(title: 'Leave balances', accentColor: KeystoneColors.ochre),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < balances.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _BalanceCard(balance: balances[i], label: _typeLabel(balances[i].type))),
              ],
            ],
          ),

          const SizedBox(height: 22),
          const KeystoneSectionHeader(title: 'My requests', accentColor: KeystoneColors.pine),
          const SizedBox(height: 10),

          if (data.requests.isEmpty)
            const KeystoneEmptyState(
              icon: Icons.event_note_rounded,
              accentColor: KeystoneColors.ochre,
              tintColor: KeystoneColors.ochreTint,
              title: 'No leave requests yet',
              message: 'Tap Apply above whenever you need planned or sick leave.',
            )
          else
            for (var i = 0; i < data.requests.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RequestCard(
                request: data.requests[i],
                typeLabel: _typeLabel(data.requests[i].type),
                onCancel: data.requests[i].status == 'PENDING'
                    ? () => appState.cancelLeave(data.requests[i].id)
                    : null,
              ),
            ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.label});

  final LeaveBalance balance;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (accent, tint, bg) = switch (balance.type) {
      'ANNUAL' => (KeystoneColors.emerald, KeystoneColors.pineTint, const Color(0xFFECFDF5)),
      'SICK' => (KeystoneColors.ochre, KeystoneColors.ochreTint, KeystoneColors.amberMist),
      _ => (KeystoneColors.indigo, KeystoneColors.indigoTint, const Color(0xFFEEF2FF)),
    };

    final progress = balance.total > 0 ? (balance.remaining / balance.total) : 0.0;

    return KeystoneCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      backgroundColor: bg,
      borderRadius: 16,
      child: Column(
        children: [
          KeystoneRingGauge(
            progress: progress,
            centerText: balance.remaining.toStringAsFixed(balance.remaining % 1 == 0 ? 0 : 1),
            color: accent,
            trackColor: tint,
            size: 50,
            strokeWidth: 5,
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${balance.total.toStringAsFixed(0)} days',
            style: const TextStyle(
              fontSize: 11,
              color: KeystoneColors.muted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.typeLabel,
    this.onCancel,
  });

  final LeaveRequest request;
  final String typeLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final tone = switch (request.status) {
      'APPROVED' => BadgeTone.emerald,
      'REJECTED' => BadgeTone.clay,
      _ => BadgeTone.ochre,
    };

    final (iconBg, iconFg) = switch (request.type) {
      'ANNUAL' => (KeystoneColors.pineTint, KeystoneColors.pine),
      'SICK' => (KeystoneColors.ochreTint, KeystoneColors.ochre),
      _ => (KeystoneColors.indigoTint, KeystoneColors.indigo),
    };

    final dateRange = request.startDate == request.endDate
        ? request.startDate
        : '${request.startDate} → ${request.endDate}';

    return KeystoneCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KeystoneIconBadge(
                icon: Icons.event_note_rounded,
                background: iconBg,
                color: iconFg,
                size: 36,
                iconSize: 17,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$typeLabel · ${request.isHalfDay ? "0.5 day" : "${request.days.toStringAsFixed(0)} day(s)"}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      dateRange,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KeystoneColors.muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              KeystoneBadge(label: request.status, tone: tone),
            ],
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: KeystoneColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(request.reason, style: const TextStyle(fontSize: 13, color: KeystoneColors.ink)),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: KeystoneColors.clayTint,
                  foregroundColor: KeystoneColors.clay,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Withdraw request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
