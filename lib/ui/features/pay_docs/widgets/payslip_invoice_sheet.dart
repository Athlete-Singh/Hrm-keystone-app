import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/employee_models.dart';
import '../../../core/theme/keystone_theme.dart';
import '../../../core/widgets/keystone_ui.dart';
import '../../../viewmodels/app_state.dart';

class PayslipInvoiceSheet extends StatelessWidget {
  const PayslipInvoiceSheet({
    super.key,
    required this.payslip,
    required this.appState,
    this.companyName = 'Keystone Labs',
  });

  final Payslip payslip;
  final AppState appState;
  final String companyName;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static void show(BuildContext context, {required Payslip payslip, required AppState appState}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayslipInvoiceSheet(payslip: payslip, appState: appState),
    );
  }

  String _formatMonthLabel(String ym) {
    final parts = ym.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    return DateFormat('MMMM yyyy').format(DateTime(year, month, 1));
  }

  String _numberToWords(num amount) {
    final n = amount.toInt();
    if (n == 0) return 'Zero Rupees';
    final a = ['', 'One ', 'Two ', 'Three ', 'Four ', 'Five ', 'Six ', 'Seven ', 'Eight ', 'Nine ', 'Ten ', 'Eleven ', 'Twelve ', 'Thirteen ', 'Fourteen ', 'Fifteen ', 'Sixteen ', 'Seventeen ', 'Eighteen ', 'Nineteen '];
    final b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convert(int num) {
      String out = '';
      if (num >= 10000000) {
        out += '${convert(num ~/ 10000000)}Crore ';
        num %= 10000000;
      }
      if (num >= 100000) {
        out += '${convert(num ~/ 100000)}Lakh ';
        num %= 100000;
      }
      if (num >= 1000) {
        out += '${convert(num ~/ 1000)}Thousand ';
        num %= 1000;
      }
      if (num >= 100) {
        out += '${convert(num ~/ 100)}Hundred ';
        num %= 100;
      }
      if (num > 0) {
        if (out.isNotEmpty) out += 'and ';
        if (num < 20) {
          out += a[num];
        } else {
          out += b[num ~/ 10];
          if (num % 10 > 0) out += '-${a[num % 10].trim()}';
          out += ' ';
        }
      }
      return out;
    }

    return '${convert(n).trim()} Rupees Only';
  }

  @override
  Widget build(BuildContext context) {
    final employeeSuffix = (appState.user?.id.isNotEmpty == true ? appState.user!.id : '001')
        .replaceAll('usr-', '')
        .toUpperCase();
    final invoiceNo = 'INV-${payslip.month.replaceAll('-', '')}-$employeeSuffix';
    final monthTitle = _formatMonthLabel(payslip.month);
    final paidDays = payslip.daysInMonth - payslip.unpaidDays;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Top Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KeystoneColors.pineTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: KeystoneColors.pineDeep, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salary Invoice & Payslip',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$monthTitle · $invoiceNo',
                            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),

              // Content Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    // Corporate Banner Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Payroll & Human Resources',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 11),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.20),
                                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.50)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        color: Color(0xFF4ADE80),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoice #: $invoiceNo',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontFamily: 'monospace'),
                                ),
                                Text(
                                  payslip.status,
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Employee Meta Details
                    KeystoneCard(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 14,
                      child: Column(
                        children: [
                          _MetaRow('Employee Name', appState.user?.name ?? 'Employee'),
                          _MetaRow('Pay Period', monthTitle),
                          _MetaRow('Attendance Days', '$paidDays Paid · ${payslip.unpaidDays} LOP'),
                          _MetaRow('Payment Mode', 'Direct Bank Deposit (NEFT/IMPS)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Earnings Ledger
                    const KeystoneSectionHeader(title: 'Earnings Ledger', accentColor: KeystoneColors.emerald),
                    const SizedBox(height: 8),
                    KeystoneCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _InvoiceLine('Basic Salary', _currency.format(payslip.basic)),
                          _InvoiceLine('House Rent Allowance (HRA)', _currency.format(payslip.hra)),
                          _InvoiceLine('Special / Other Allowances', _currency.format(payslip.otherAllowance)),
                          if (payslip.bonus > 0)
                            _InvoiceLine('Performance Bonus', _currency.format(payslip.bonus)),
                          if (payslip.reimbursement > 0)
                            _InvoiceLine('Claims & Reimbursements', _currency.format(payslip.reimbursement)),
                          const Divider(height: 16),
                          _InvoiceLine(
                            'Gross Earnings',
                            _currency.format(payslip.grossEarnings),
                            bold: true,
                            highlightColor: KeystoneColors.emerald,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deductions Ledger
                    const KeystoneSectionHeader(title: 'Deductions Ledger', accentColor: KeystoneColors.clay),
                    const SizedBox(height: 8),
                    KeystoneCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _InvoiceLine('Income Tax (TDS)', _currency.format(payslip.incomeTax)),
                          _InvoiceLine('Loss of Pay (LOP Deduction)', _currency.format(payslip.lopDeduction)),
                          if (payslip.otherDeduction > 0)
                            _InvoiceLine('Other Deductions', _currency.format(payslip.otherDeduction)),
                          const Divider(height: 16),
                          _InvoiceLine(
                            'Total Deductions',
                            _currency.format(payslip.totalDeductions),
                            bold: true,
                            highlightColor: KeystoneColors.clay,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Net Take-Home Hero Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'NET SALARY PAYABLE',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currency.format(payslip.netSalary),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _numberToWords(payslip.netSalary),
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action: Download PDF
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: KeystoneColors.pine,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text(
                        'Download Official PDF',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        final opened = await appState.openPayslipPdf(payslip.month);
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloading salary slip & invoice PDF...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.16)),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: const Text('Open PDF in Browser', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      onPressed: () => appState.openPayslipPdf(payslip.month),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is a digitally certified salary invoice and payslip generated by Keystone HRMS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: Colors.black.withValues(alpha: 0.40)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine(this.label, this.amount, {this.bold = false, this.highlightColor});

  final String label;
  final String amount;
  final bool bold;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? Colors.black : Colors.black87,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlightColor ?? (bold ? Colors.black : Colors.black87),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
