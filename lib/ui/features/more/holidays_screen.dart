import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key, required this.appState});

  final AppState appState;

  static const Map<String, String> _knownNames = {
    '01-01': "New Year's Day",
    '01-26': 'Republic Day',
    '05-01': 'Maharashtra / Labour Day',
    '08-15': 'Independence Day',
    '10-02': 'Gandhi Jayanti',
    '11-24': 'Company Foundation Day',
    '12-25': 'Christmas Day',
  };

  @override
  Widget build(BuildContext context) {
    final rawDates = appState.leaveData.holidays;
    final items = rawDates
        .map((d) {
          final parsed = DateTime.tryParse(d);
          final mmdd = d.length >= 10 ? d.substring(5, 10) : '';
          final name = _knownNames[mmdd] ?? 'Company Holiday';
          return (
            parsed: parsed,
            item: HolidayItem(date: d, name: name),
          );
        })
        .toList()
      ..sort((a, b) => a.item.date.compareTo(b.item.date));

    const palettes = [
      (KeystoneColors.pineTint, KeystoneColors.pineDeep),
      (KeystoneColors.ochreTint, KeystoneColors.ochre),
      (KeystoneColors.indigoTint, KeystoneColors.indigo),
      (KeystoneColors.clayTint, KeystoneColors.clay),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Holiday calendar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: KeystoneCornerActions(
              appState: appState,
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
              if (items.isEmpty)
                const KeystoneEmptyState(
                  icon: Icons.celebration_rounded,
                  accentColor: KeystoneColors.clay,
                  tintColor: KeystoneColors.clayTint,
                  title: 'No upcoming holidays configured',
                  message: 'Public holidays added by HR appear automatically on your attendance calendar.',
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 9),
                  KeystoneCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: palettes[i % palettes.length].$1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                items[i].parsed != null
                                    ? DateFormat('MMM').format(items[i].parsed!).toUpperCase()
                                    : 'HOL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: palettes[i % palettes.length].$2,
                                ),
                              ),
                              Text(
                                items[i].parsed != null
                                    ? DateFormat('dd').format(items[i].parsed!)
                                    : '--',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: palettes[i % palettes.length].$2,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].item.name,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                items[i].parsed != null
                                    ? DateFormat('EEEE, d MMMM yyyy').format(items[i].parsed!)
                                    : items[i].item.date,
                                style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const KeystoneBadge(label: 'Paid off', tone: BadgeTone.emerald),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
