import 'package:flutter/material.dart';
import '../theme/keystone_theme.dart';

enum BadgeTone { pine, emerald, ochre, clay, indigo, sky, violet, neutral }

/// Atmospheric multi-tone canvas matching the Keystone website's soft mint, ivory,
/// and sunlit amber ambient washes without harsh lines or sterile white emptiness.
class KeystoneBackdrop extends StatelessWidget {
  const KeystoneBackdrop({
    super.key,
    required this.child,
    this.warmAccent = false,
  });

  final Widget child;
  final bool warmAccent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: warmAccent
                  ? const [
                      Color(0xFFE7F5EE),
                      Color(0xFFF6FAF7),
                      Color(0xFFFEF6DF),
                    ]
                  : const [
                      Color(0xFFEAF6EF),
                      Color(0xFFF6FAF7),
                      Color(0xFFFCF7E8),
                    ],
              stops: const [0.0, 0.54, 1.0],
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _BackdropObjectsPainter(warmAccent: warmAccent),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropObjectsPainter extends CustomPainter {
  const _BackdropObjectsPainter({required this.warmAccent});

  final bool warmAccent;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft organic mint bloom top-right
    final mintOrb = Paint()
      ..shader = RadialGradient(
        colors: [
          KeystoneColors.emerald.withValues(alpha: warmAccent ? 0.16 : 0.12),
          KeystoneColors.emerald.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.92, size.height * 0.10),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.10),
      size.width * 0.55,
      mintOrb,
    );

    // Sunlit gold wash bottom-left
    final goldOrb = Paint()
      ..shader = RadialGradient(
        colors: [
          KeystoneColors.gold.withValues(alpha: warmAccent ? 0.14 : 0.10),
          KeystoneColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.72),
          radius: size.width * 0.52,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.72),
      size.width * 0.52,
      goldOrb,
    );

    // Subtle sky-indigo breeze middle-right
    final skyOrb = Paint()
      ..shader = RadialGradient(
        colors: [
          KeystoneColors.sky.withValues(alpha: 0.07),
          KeystoneColors.sky.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.52),
          radius: size.width * 0.40,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.52),
      size.width * 0.40,
      skyOrb,
    );

    // Crisp architectural concentric rings (top-right subtle landmark object)
    final ringPaint = Paint()
      ..color = KeystoneColors.pine.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final topCenter = Offset(size.width * 0.95, 42);
    canvas.drawCircle(topCenter, 58, ringPaint);
    canvas.drawCircle(topCenter, 92, ringPaint);
    canvas.drawCircle(topCenter, 128, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BackdropObjectsPainter oldDelegate) =>
      oldDelegate.warmAccent != warmAccent;
}

/// Borderless elevated card separated purely by soft pine-tinted elevation and tone.
class KeystoneCard extends StatelessWidget {
  const KeystoneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = KeystoneColors.surface,
    this.gradient,
    this.borderRadius = 18,
    this.border,
    this.shadowColor = KeystoneColors.cardShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Gradient? gradient;
  final double borderRadius;
  final BoxBorder? border;
  final Color shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final padded = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? padded : InkWell(onTap: onTap, child: padded),
      ),
    );
  }
}

/// Colorful website-matched emerald/pine CTA button.
class KeystoneGradientButton extends StatelessWidget {
  const KeystoneGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.busy = false,
    this.colors = const [KeystoneColors.pineDeep, KeystoneColors.pine, Color(0xFF15803D)],
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool busy;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
        color: disabled ? KeystoneColors.wash : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: disabled ? KeystoneColors.muted : Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: disabled ? KeystoneColors.muted : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft colorful pill badge with zero hairline borders.
class KeystoneBadge extends StatelessWidget {
  const KeystoneBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
    this.dotColor,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.pine => (KeystoneColors.pineTint, KeystoneColors.pineDeep),
      BadgeTone.emerald => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      BadgeTone.ochre => (KeystoneColors.ochreTint, const Color(0xFF92400E)),
      BadgeTone.clay => (KeystoneColors.clayTint, KeystoneColors.clay),
      BadgeTone.indigo => (KeystoneColors.indigoTint, KeystoneColors.indigo),
      BadgeTone.sky => (KeystoneColors.skyTint, const Color(0xFF0369A1)),
      BadgeTone.violet => (KeystoneColors.violetTint, KeystoneColors.violet),
      BadgeTone.neutral => (KeystoneColors.wash, KeystoneColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6.5,
              height: 6.5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colorful soft rounded icon tile used inside list items and metric headers.
class KeystoneIconBadge extends StatelessWidget {
  const KeystoneIconBadge({
    super.key,
    required this.icon,
    this.background = KeystoneColors.pineTint,
    this.color = KeystoneColors.pineDeep,
    this.size = 40,
    this.iconSize = 19,
    this.radius = 12,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// Crisp tracked section label with an optional colored indicator dot & trailing action.
class KeystoneSectionHeader extends StatelessWidget {
  const KeystoneSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.accentColor,
  });

  final String title;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (accentColor != null) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
        ],
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
            color: KeystoneColors.muted,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class KeystoneAvatar extends StatelessWidget {
  const KeystoneAvatar({
    super.key,
    required this.initials,
    this.size = 40,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KeystoneColors.emerald, KeystoneColors.gold],
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: KeystoneColors.pineDeep,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class KeystoneEmptyState extends StatelessWidget {
  const KeystoneEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accentColor = KeystoneColors.pine,
    this.tintColor = KeystoneColors.pineTint,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color accentColor;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return KeystoneCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 25, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Exact trapezoid mark from the Keystone website (`hrm/src/shared/components/Logo.tsx`).
class KeystoneMark extends StatelessWidget {
  const KeystoneMark({
    super.key,
    this.size = 20,
    this.inverse = false,
  });

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _KeystoneMarkPainter(inverse: inverse),
    );
  }
}

class _KeystoneMarkPainter extends CustomPainter {
  const _KeystoneMarkPainter({required this.inverse});

  final bool inverse;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 18.0;
    final sy = size.height / 18.0;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      // Outer keystone trapezoid: M5.6 2h6.8l3.1 14H2.5L5.6 2Z
      ..moveTo(5.6 * sx, 2.0 * sy)
      ..lineTo(12.4 * sx, 2.0 * sy)
      ..lineTo(15.5 * sx, 16.0 * sy)
      ..lineTo(2.5 * sx, 16.0 * sy)
      ..close()
      // Inner cutout trapezoid: M7.9 6.2h2.2l1 5.6H6.9l1-5.6Z
      ..moveTo(7.9 * sx, 6.2 * sy)
      ..lineTo(10.1 * sx, 6.2 * sy)
      ..lineTo(11.1 * sx, 11.8 * sy)
      ..lineTo(6.9 * sx, 11.8 * sy)
      ..close();

    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    if (inverse) {
      paint.color = const Color(0xFFFBFBFA);
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10B981), Color(0xFF15803D)],
      ).createShader(rect);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _KeystoneMarkPainter oldDelegate) =>
      oldDelegate.inverse != inverse;
}

/// Squircle app icon badge matching the Keystone website favicon (`hrm/public/favicon.png`).
class KeystoneAppBadge extends StatelessWidget {
  const KeystoneAppBadge({
    super.key,
    this.size = 38,
    this.radius,
  });

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final cornerRadius = radius ?? size * 0.27;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF264437),
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: [
          BoxShadow(
            color: KeystoneColors.pineDeep.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: KeystoneMark(size: size * 0.62, inverse: true),
    );
  }
}

/// Full Keystone website logo (`Logo.tsx`): trapezoid mark + dual-tone `Keystone` wordmark.
class KeystoneLogo extends StatelessWidget {
  const KeystoneLogo({
    super.key,
    this.size = 20,
    this.inverse = false,
  });

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final fontSize = size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeystoneMark(size: size, inverse: inverse),
        SizedBox(width: size * 0.4),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.03 * fontSize,
              height: 1.0,
            ),
            children: [
              TextSpan(
                text: 'Key',
                style: TextStyle(
                  color: inverse ? const Color(0xFFFBFBFA) : KeystoneColors.ink,
                ),
              ),
              TextSpan(
                text: 'stone',
                style: TextStyle(
                  color: inverse ? const Color(0xFFA4DBC6) : const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
