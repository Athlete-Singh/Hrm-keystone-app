import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/keystone_theme.dart';
import '../../../viewmodels/app_state.dart';

Future<void> showStartFieldVisitSheet(BuildContext context, AppState appState) async {
  final clientCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  bool includeSelfie = false;
  bool submitting = false;
  String? errorText;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final fix = appState.currentFix;
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
                          'Log field visit',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fix == null
                        ? 'GPS coordinates will be captured on check-in.'
                        : 'Location: ${fix.addressLabel} (${fix.latitude.toStringAsFixed(4)}, ${fix.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 12.5, color: KeystoneColors.muted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: clientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Client or site name *',
                      hintText: 'e.g. Surya Logistics Hub',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Visit purpose *',
                      hintText: 'e.g. Hardware installation / client review',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Gate contact or arrival details',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: KeystoneColors.pine,
                    title: const Text('Attach verification selfie', style: TextStyle(fontSize: 13.5)),
                    subtitle: const Text('Captures front photo at client site', style: TextStyle(fontSize: 12)),
                    value: includeSelfie,
                    onChanged: (v) => setModalState(() => includeSelfie = v),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 6),
                    Text(errorText!, style: const TextStyle(color: KeystoneColors.clay, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (clientCtrl.text.trim().isEmpty || purposeCtrl.text.trim().isEmpty) {
                              setModalState(() => errorText = 'Enter both client/site name and purpose.');
                              return;
                            }
                            setModalState(() {
                              submitting = true;
                              errorText = null;
                            });
                            try {
                              await appState.startFieldVisit(
                                clientName: clientCtrl.text.trim(),
                                purpose: purposeCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                                includeSelfie: includeSelfie,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModalState(() {
                                submitting = false;
                                errorText = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Start field check-in'),
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

Future<void> showCompleteFieldVisitSheet(
  BuildContext context,
  AppState appState, {
  required String visitId,
  required String clientName,
}) async {
  final notesCtrl = TextEditingController();
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
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
              Text(
                'Complete visit · $clientName',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Visit outcome / notes (optional)',
                  hintText: 'e.g. Verified kiosk power and ran sample check-in.',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        setModalState(() => submitting = true);
                        try {
                          await appState.completeFieldVisit(
                            visitId: visitId,
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          setModalState(() => submitting = false);
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Mark visit completed'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showCorrectionRequestSheet(
  BuildContext context,
  AppState appState, {
  String? initialDate,
}) async {
  final dateCtrl = TextEditingController(
    text: initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))),
  );
  final inCtrl = TextEditingController(text: '09:15');
  final outCtrl = TextEditingController(text: '18:10');
  final reasonCtrl = TextEditingController();
  bool submitting = false;
  String? errorText;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
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
                          'Request attendance correction',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inCtrl,
                          decoration: const InputDecoration(labelText: 'Proposed clock in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: outCtrl,
                          decoration: const InputDecoration(labelText: 'Proposed clock out'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reason *',
                      hintText: 'e.g. Client site meeting ran late without Wi-Fi',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: KeystoneColors.clay, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (reasonCtrl.text.trim().isEmpty) {
                              setModalState(() => errorText = 'Please provide a brief reason.');
                              return;
                            }
                            setModalState(() {
                              submitting = true;
                              errorText = null;
                            });
                            try {
                              await appState.requestAttendanceCorrection(
                                date: dateCtrl.text.trim(),
                                reason: reasonCtrl.text.trim(),
                                proposedCheckIn: inCtrl.text.trim(),
                                proposedCheckOut: outCtrl.text.trim(),
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Correction request sent to your manager.')),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                submitting = false;
                                errorText = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit correction'),
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

