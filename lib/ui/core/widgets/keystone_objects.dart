import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../domain/models/employee_models.dart';
import '../theme/keystone_theme.dart';
import 'keystone_ui.dart';

/// Real-product UI object collage displayed at the top of the Sign-in screen,
/// echoing the Keystone web workspace modules (Attendance, Leave, Payroll).
class LoginHeroObjects extends StatelessWidget {
  const LoginHeroObjects({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123E2E),
            Color(0xFF166534),
            Color(0xFF0E7490),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: KeystoneColors.pineDeep.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle topographic arcs
          Positioned.fill(
            child: CustomPaint(painter: _HeroGridPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left card object: Employee ID & Clock-in Pass
                Expanded(
                  flex: 11,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const KeystoneAppBadge(size: 24, radius: 7),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Text(
                                'Keystone ID',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: KeystoneColors.emerald, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                '09:00 · HQ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: KeystoneColors.pineDeep,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.78,
                            minHeight: 5,
                            backgroundColor: KeystoneColors.wash,
                            valueColor: AlwaysStoppedAnimation(KeystoneColors.emerald),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Right column: Leave badge + Payslip bar card
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: KeystoneColors.ochreTint,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, size: 14, color: KeystoneColors.ochre),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '18d Leave',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, size: 13, color: KeystoneColors.indigo),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Payslip',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: KeystoneColors.ink),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _miniBar(10, KeystoneColors.pineTint),
                                const SizedBox(width: 4),
                                _miniBar(16, KeystoneColors.emerald),
                                const SizedBox(width: 4),
                                _miniBar(13, KeystoneColors.indigoTint),
                                const SizedBox(width: 4),
                                _miniBar(22, KeystoneColors.indigo),
                                const SizedBox(width: 4),
                                _miniBar(18, KeystoneColors.gold),
                                const Spacer(),
                                const Icon(Icons.verified_rounded, size: 15, color: KeystoneColors.emerald),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniBar(double h, Color c) {
    return Container(
      width: 8,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _HeroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          KeystoneColors.gold.withValues(alpha: 0.25),
          KeystoneColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.15), radius: 110));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 110, glow);

    final arc = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 1.05), 88, arc);
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 1.05), 130, arc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Interactive horizontal visual strip matching the website's "Ways to punch" showcase
/// (01 Mobile, 02 Selfie, 03 Biometric, 04 Field/GPS).
class PunchMethodVisualCards extends StatelessWidget {
  const PunchMethodVisualCards({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PunchMethod selected;
  final ValueChanged<PunchMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        method: PunchMethod.mobile,
        code: '01',
        title: 'Mobile app',
        accent: KeystoneColors.emerald,
        tint: KeystoneColors.pineTint,
        object: _PhonePunchGlyph(active: selected == PunchMethod.mobile),
      ),
      (
        method: PunchMethod.selfie,
        code: '02',
        title: 'Selfie scan',
        accent: KeystoneColors.sky,
        tint: KeystoneColors.skyTint,
        object: _SelfieFrameGlyph(active: selected == PunchMethod.selfie),
      ),
      (
        method: PunchMethod.biometric,
        code: '03',
        title: 'Biometric',
        accent: KeystoneColors.violet,
        tint: KeystoneColors.violetTint,
        object: _BiometricTerminalGlyph(active: selected == PunchMethod.biometric),
      ),
      (
        method: PunchMethod.field,
        code: '04',
        title: 'Field & GPS',
        accent: KeystoneColors.ochre,
        tint: KeystoneColors.ochreTint,
        object: _FieldRouteGlyph(active: selected == PunchMethod.field),
      ),
    ];

    Widget rowOf(int a, int b) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 58,
              child: _MethodObjectTile(
                code: items[a].code,
                title: items[a].title,
                accent: items[a].accent,
                tint: items[a].tint,
                isSelected: selected == items[a].method,
                glyph: items[a].object,
                onTap: () => onSelect(items[a].method),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 58,
              child: _MethodObjectTile(
                code: items[b].code,
                title: items[b].title,
                accent: items[b].accent,
                tint: items[b].tint,
                isSelected: selected == items[b].method,
                glyph: items[b].object,
                onTap: () => onSelect(items[b].method),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        rowOf(0, 1),
        const SizedBox(height: 8),
        rowOf(2, 3),
      ],
    );
  }
}

class _MethodObjectTile extends StatelessWidget {
  const _MethodObjectTile({
    required this.code,
    required this.title,
    required this.accent,
    required this.tint,
    required this.isSelected,
    required this.glyph,
    required this.onTap,
  });

  final String code;
  final String title;
  final Color accent;
  final Color tint;
  final bool isSelected;
  final Widget glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? tint : KeystoneColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                glyph,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: KeystoneColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhonePunchGlyph extends StatelessWidget {
  const _PhonePunchGlyph({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(color: KeystoneColors.pine.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 10, height: 2.5, decoration: BoxDecoration(color: KeystoneColors.wash, borderRadius: BorderRadius.circular(2))),
          Container(
            width: 24,
            height: 13,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? KeystoneColors.pine : KeystoneColors.emerald,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SelfieFrameGlyph extends StatelessWidget {
  const _SelfieFrameGlyph({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(color: KeystoneColors.sky.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.face_retouching_natural_rounded, size: 20, color: active ? KeystoneColors.sky : const Color(0xFF38BDF8)),
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: KeystoneColors.emerald, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricTerminalGlyph extends StatelessWidget {
  const _BiometricTerminalGlyph({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [const Color(0xFF4C1D95), KeystoneColors.violet]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.fingerprint_rounded, size: 21, color: Color(0xFF6EE7B7)),
      ),
    );
  }
}

class _FieldRouteGlyph extends StatelessWidget {
  const _FieldRouteGlyph({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(color: KeystoneColors.ochre.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: CustomPaint(painter: _MiniRoutePainter(active: active)),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  const _MiniRoutePainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final route = Paint()
      ..color = active ? KeystoneColors.ochre : KeystoneColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(7, size.height - 9)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.25, size.width - 9, 10);
    canvas.drawPath(path, route);

    canvas.drawCircle(Offset(7, size.height - 9), 3.2, Paint()..color = KeystoneColors.emerald);
    canvas.drawCircle(Offset(size.width - 9, 10), 4.0, Paint()..color = KeystoneColors.ochre);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) => oldDelegate.active != active;
}

/// Clean circular ring gauge for leave quotas and attendance percentages.
class KeystoneRingGauge extends StatelessWidget {
  const KeystoneRingGauge({
    super.key,
    required this.progress,
    required this.centerText,
    required this.color,
    required this.trackColor,
    this.size = 52,
    this.strokeWidth = 5.5,
  });

  final double progress;
  final String centerText;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: color,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            centerText,
            style: TextStyle(
              fontSize: size * 0.27,
              fontWeight: FontWeight.w700,
              color: KeystoneColors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Multi-segment compensation bar matching real fintech/payroll apps.
class SalaryBreakdownBar extends StatelessWidget {
  const SalaryBreakdownBar({
    super.key,
    required this.basic,
    required this.hra,
    required this.allowances,
    required this.deductions,
  });

  final double basic;
  final double hra;
  final double allowances;
  final double deductions;

  @override
  Widget build(BuildContext context) {
    final total = (basic + hra + allowances + deductions).clamp(1.0, double.infinity);
    final segments = [
      (label: 'Basic', value: basic, color: const Color(0xFF6EE7B7)),
      (label: 'HRA', value: hra, color: const Color(0xFF93C5FD)),
      (label: 'Extras', value: allowances, color: const Color(0xFFFDE047)),
      (label: 'Tax/Ded', value: deductions, color: const Color(0xFFFDA4AF)),
    ].where((s) => s.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 9,
            child: Row(
              children: [
                for (var i = 0; i < segments.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2.5),
                  Expanded(
                    flex: ((segments[i].value / total) * 1000).round().clamp(1, 1000),
                    child: Container(color: segments[i].color),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final s in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
