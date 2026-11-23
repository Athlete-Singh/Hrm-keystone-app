import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_objects.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';
import 'widgets/payslip_invoice_sheet.dart';

class PayDocsTab extends StatefulWidget {
  const PayDocsTab({super.key, required this.appState});

  final AppState appState;

  @override
  State<PayDocsTab> createState() => _PayDocsTabState();
}

class _PayDocsTabState extends State<PayDocsTab> {
  int _segment = 0; // 0 = Payslip, 1 = Documents

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  void _stepMonth(int delta) {
    final parts = widget.appState.selectedPayslipMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final next = DateTime(year, month + delta, 1);
    final ym = '${next.year}-${next.month.toString().padLeft(2, '0')}';
    widget.appState.loadPayslipForMonth(ym);
  }

  String _formatMonthTitle(String ym) {
    final parts = ym.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateFormat('MMMM yyyy').format(DateTime(year, month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;

    return RefreshIndicator(
      color: KeystoneColors.pine,
      onRefresh: state.refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          const Text(
            'Pay & documents',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          const SizedBox(height: 12),
          // Borderless soft pill switcher
          KeystoneCard(
            padding: const EdgeInsets.all(4),
            borderRadius: 14,
            child: Row(
              children: [
                Expanded(
                  child: _SegmentPill(
                    selected: _segment == 0,
                    icon: Icons.receipt_long_rounded,
                    label: 'My payslip',
                    activeBg: KeystoneColors.indigoTint,
                    activeFg: KeystoneColors.indigo,
                    onTap: () => setState(() => _segment = 0),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentPill(
                    selected: _segment == 1,
                    icon: Icons.folder_copy_rounded,
                    label: 'Documents',
                    activeBg: KeystoneColors.pineTint,
                    activeFg: KeystoneColors.pineDeep,
                    onTap: () => setState(() => _segment = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_segment == 0) _buildPayslipSection(state) else _buildDocumentsSection(state),
        ],
      ),
    );
  }

  Widget _buildPayslipSection(AppState state) {
    final payslip = state.payslip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeystoneCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: 14,
          child: Row(
            children: [
              IconButton(
                onPressed: () => _stepMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _formatMonthTitle(state.selectedPayslipMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _stepMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (payslip == null || !payslip.hasSalaryStructure)
          const KeystoneEmptyState(
            icon: Icons.payments_rounded,
            accentColor: KeystoneColors.indigo,
            tintColor: KeystoneColors.indigoTint,
            title: 'No finalized payslip yet',
            message: 'Payroll for this month has not been finalized for your account.',
          )
        else ...[
          // Rich Indigo-to-Pine Net Take-Home Hero Card + Compensation Breakdown Bar
          KeystoneCard(
            borderRadius: 22,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF312E81),
                Color(0xFF166534),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Net take-home pay',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.80)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        payslip.status,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currency.format(payslip.netSalary),
                  style: const TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payslip.daysInMonth - payslip.unpaidDays} paid days · ${payslip.unpaidDays} unpaid / LOP days',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 16),
                SalaryBreakdownBar(
                  basic: payslip.basic,
                  hra: payslip.hra,
                  allowances: payslip.otherAllowance + payslip.bonus + payslip.reimbursement,
                  deductions: payslip.totalDeductions,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KeystoneColors.pine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  onPressed: () => state.openPayslipPdf(payslip.month),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KeystoneColors.pineDeep,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: KeystoneColors.pineTint),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('View Invoice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  onPressed: () => PayslipInvoiceSheet.show(context, payslip: payslip, appState: state),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const KeystoneSectionHeader(title: 'Earnings', accentColor: KeystoneColors.emerald),
          const SizedBox(height: 8),
          KeystoneCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _LedgerRow('Basic pay', _currency.format(payslip.basic), tinted: true),
                _LedgerRow('House rent allowance (HRA)', _currency.format(payslip.hra)),
                _LedgerRow('Other allowances', _currency.format(payslip.otherAllowance), tinted: true),
                if (payslip.bonus > 0) _LedgerRow('Bonus', _currency.format(payslip.bonus)),
                if (payslip.reimbursement > 0)
                  _LedgerRow('Reimbursements', _currency.format(payslip.reimbursement), tinted: true),
                const SizedBox(height: 4),
                _LedgerRow(
                  'Gross earnings',
                  _currency.format(payslip.grossEarnings),
                  bold: true,
                  highlightColor: KeystoneColors.pineTint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const KeystoneSectionHeader(title: 'Deductions', accentColor: KeystoneColors.clay),
          const SizedBox(height: 8),
          KeystoneCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _LedgerRow('Income tax (TDS)', _currency.format(payslip.incomeTax), tinted: true),
                _LedgerRow('Loss of pay (LOP)', _currency.format(payslip.lopDeduction)),
                _LedgerRow('Other deductions', _currency.format(payslip.otherDeduction), tinted: true),
                const SizedBox(height: 4),
                _LedgerRow(
                  'Total deductions',
                  _currency.format(payslip.totalDeductions),
                  bold: true,
                  highlightColor: KeystoneColors.clayTint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          KeystoneCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            border: Border.all(color: KeystoneColors.pineTint, width: 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KeystoneColors.pineTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: KeystoneColors.pine, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Official Salary Invoice & Slip',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KeystoneColors.pineTint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PDF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: KeystoneColors.pine,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Corporate stamped & cryptographically verified PDF',
                            style: TextStyle(fontSize: 12, color: KeystoneColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: KeystoneColors.pine,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: () => state.openPayslipPdf(payslip.month),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KeystoneColors.pineDeep,
                          side: const BorderSide(color: KeystoneColors.pineTint),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: const Text('View Invoice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: () => PayslipInvoiceSheet.show(context, payslip: payslip, appState: state),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsSection(AppState state) {
    final docs = state.documents;
    final currentMonth = state.selectedPayslipMonth;

    // Past 3 months for payslip invoices
    final months = [
      currentMonth,
      '2026-09',
      '2026-08',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KeystoneSectionHeader(
          title: 'Official Salary Invoices (PDF)',
          accentColor: KeystoneColors.pine,
        ),
        const SizedBox(height: 8),
        for (final m in months) ...[
          KeystoneCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 16,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KeystoneColors.clayTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: KeystoneColors.clay, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salary Invoice & Slip — $m',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verified PDF · Includes tax & salary ledger',
                        style: TextStyle(fontSize: 12, color: KeystoneColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View Invoice',
                  icon: const Icon(Icons.receipt_long_rounded, color: KeystoneColors.pineDeep, size: 22),
                  onPressed: () async {
                    if (state.payslip != null && state.payslip!.month == m) {
                      PayslipInvoiceSheet.show(context, payslip: state.payslip!, appState: state);
                    } else {
                      state.openPayslipPdf(m);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Download PDF',
                  icon: const Icon(Icons.download_rounded, color: KeystoneColors.pine, size: 22),
                  onPressed: () => state.openPayslipPdf(m),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        const KeystoneSectionHeader(
          title: 'Company Handbooks & Policies',
          accentColor: KeystoneColors.indigo,
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          const KeystoneEmptyState(
            icon: Icons.folder_copy_rounded,
            accentColor: KeystoneColors.indigo,
            tintColor: KeystoneColors.indigoTint,
            title: 'No policy documents shared yet',
            message: 'Company handbooks, employment contracts, and policies will appear here.',
          )
        else
          for (var i = 0; i < docs.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            KeystoneCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: 16,
              onTap: () => _showDocumentDetails(docs[i]),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: docs[i].fileType.toUpperCase().contains('PDF')
                          ? KeystoneColors.clayTint
                          : KeystoneColors.indigoTint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      docs[i].fileType,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: docs[i].fileType.toUpperCase().contains('PDF')
                            ? KeystoneColors.clay
                            : KeystoneColors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docs[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${docs[i].category} · ${docs[i].sizeKb} KB · Updated ${docs[i].updatedAt}',
                          style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: KeystoneColors.subtle),
                ],
              ),
            ),
          ],
      ],
    );
  }

  void _showDocumentDetails(CompanyDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            KeystoneBadge(label: '${doc.category} · ${doc.fileType}', tone: BadgeTone.pine),
            const SizedBox(height: 10),
            Text(doc.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(doc.description, style: const TextStyle(fontSize: 13.5, color: KeystoneColors.muted)),
            const SizedBox(height: 14),
            Text(
              'Uploaded by ${doc.updatedBy} on ${doc.updatedAt} (${doc.sizeKb} KB)',
              style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
            ),
            const SizedBox(height: 16),
            KeystoneGradientButton(
              onPressed: () => Navigator.pop(ctx),
              label: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.activeBg,
    required this.activeFg,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color activeBg;
  final Color activeFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeBg : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: selected ? activeFg : KeystoneColors.muted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? activeFg : KeystoneColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(
    this.label,
    this.value, {
    this.bold = false,
    this.tinted = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool bold;
  final bool tinted;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final bg = highlightColor ?? (tinted ? KeystoneColors.surfaceSoft : Colors.transparent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? KeystoneColors.ink : KeystoneColors.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: KeystoneColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
