// Sumone — reusable widgets for the Memory Pager app.
//
// A warm cream ground, soft rounded cards, one gentle heart-pink accent, and
// generous whitespace. Chrome is drawn with Material OUTLINED line icons — never
// emoji. Pet CHARACTERS stay hand-drawn (PetView); only glyphs/chrome are icons.
//
// All names are PUBLIC (no underscores). Widgets are built against the real app
// domain models in `../core/models.dart`, not the design-lab mock data. Token
// NAMES (cpMist/cpInk/cpEuc/…) are kept from the previous system so screens keep
// importing them; only their VALUES and this styling changed.

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

// ===========================================================================
// Send-mode labels
// ===========================================================================
// The real [SendMode] enum ({normal, ephemeral}) is a wire contract and carries
// no display copy, so the label/description live here.

/// Korean label for a [SendMode] tab ('일반' / '사라지기').
String cpSendModeLabel(SendMode mode) => switch (mode) {
      SendMode.normal => '일반',
      SendMode.ephemeral => '사라지기',
    };

/// One-line description of a [SendMode]'s behavior.
String cpSendModeDescription(SendMode mode) => switch (mode) {
      SendMode.normal => '다음 보내기 전까지 남음 · 레포트 반영',
      SendMode.ephemeral => '확인 후 사라짐 · 레포트 미반영',
    };

/// The line icon standing in for a doodle's content when no thumbnail/strokes
/// exist. A vector Material outlined icon — NOT an emoji.
IconData cpContentIcon(ContentType type) => switch (type) {
      ContentType.photo => Icons.image_outlined,
      ContentType.drawing => Icons.brush_outlined,
      ContentType.text => Icons.notes_outlined,
    };

// ===========================================================================
// Scaffold
// ===========================================================================

/// The app-wide scaffold: a [cpMist] ground, a SafeArea, an optional quiet top
/// bar (leading + title + actions), the [body] in an [Expanded], and an
/// optional [bottom] (e.g. [CpBottomNav]). The header appears only when at
/// least one of [title]/[leading]/[actions] is supplied.
class CpScaffold extends StatelessWidget {
  const CpScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.body,
    this.bottom,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottom;

  bool get _hasHeader =>
      title != null ||
      leading != null ||
      (actions != null && actions!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cpMist,
      body: SafeArea(
        child: Column(
          children: [
            if (_hasHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: cpSerif(
                            size: 22,
                            weight: FontWeight.w600,
                            style: FontStyle.normal,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (actions != null)
                      for (final a in actions!) ...[
                        const SizedBox(width: 10),
                        a,
                      ],
                  ],
                ),
              ),
            Expanded(child: body),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Card — THE surface
// ===========================================================================

/// A soft rounded card ([cpRadiusCard]) on warm white [matColor], framed by a
/// subtle warm border and a gentle shadow. Replaces the old hairline mat: the
/// signature surface is now soft and pastel, not a boxy 0.5px keyline.
class CpMatted extends StatelessWidget {
  const CpMatted({
    super.key,
    required this.child,
    this.mat = 18,
    this.inset = 0,
    this.matColor = cpPrint,
    this.radius = cpRadiusCard,
    this.keyline = 0, // retained for source compatibility; no longer drawn.
  });

  final Widget child;

  /// Inner padding of the card.
  final double mat;

  /// Extra padding inside the card, around [child].
  final double inset;
  final double radius;

  /// Retained so existing callers compile; the soft card no longer draws an
  /// inset keyline.
  final double keyline;
  final Color matColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(mat),
      decoration: BoxDecoration(
        color: matColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cpInkA(0.06)),
        boxShadow: [
          BoxShadow(
            color: cpInkA(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: inset > 0
          ? Padding(padding: EdgeInsets.all(inset), child: child)
          : child,
    );
  }
}

// ===========================================================================
// Small quiet primitives
// ===========================================================================

/// A soft label voice (the eyebrow). Gentle, small, slightly muted — no longer
/// tracked all-caps. Dims [color] for a calm secondary read.
class CpEyebrow extends StatelessWidget {
  const CpEyebrow(this.text, {super.key, this.color = cpInk, this.size = 11});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: cpEyebrowStyle(color: color.withValues(alpha: 0.6), size: size),
    );
  }
}

/// A 1px hairline rule at ink opacity [opacity].
class CpHair extends StatelessWidget {
  const CpHair({super.key, this.opacity = 0.08});

  final double opacity;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: cpInkA(opacity));
}

/// A soft circular icon button — a warm-white disc with a subtle border and a
/// line icon in muted ink. Used for back/leading and top-bar actions.
class CpIconButton extends StatelessWidget {
  const CpIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cpPrint,
          shape: BoxShape.circle,
          border: Border.all(color: cpInkA(0.07)),
        ),
        child: Icon(icon, size: 20, color: cpInkA(0.7)),
      ),
    );
  }
}

/// A primary, pill-shaped action button. [filled] (default) is a soft pink pill
/// with warm-white text; unfilled is a pink outline with pink text.
class CpPrimaryButton extends StatelessWidget {
  const CpPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: filled ? cpEuc : Colors.transparent,
          borderRadius: BorderRadius.circular(cpRadiusPill),
          border: filled ? null : Border.all(color: cpEucA(0.5)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: cpEucA(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: cpSans(
            size: 14,
            color: filled ? cpPrint : cpEuc,
            weight: FontWeight.w600,
            spacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// A rounded text field: an optional soft eyebrow [label] over a warm-white
/// filled box that warms its border to [cpEuc] on focus, with a quiet [hint].
class CpTextField extends StatelessWidget {
  const CpTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          CpEyebrow(label!),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          cursorColor: cpEuc,
          cursorWidth: 1.5,
          style: cpSans(size: 16),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: cpPrint,
            hintText: hint,
            hintStyle: cpSans(size: 16, color: cpInkA(0.35)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(cpRadiusSmall),
              borderSide: BorderSide(color: cpInkA(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(cpRadiusSmall),
              borderSide: const BorderSide(color: cpEuc, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Send controls
// ===========================================================================

/// The send-mode toggle: a soft pill segmented control on [cpDim]. The selected
/// segment lifts to a warm-white pill with pink text. Labels come from
/// [cpSendModeLabel]; pair with [cpSendModeDescription] for the caption line.
class CpModeToggle extends StatelessWidget {
  const CpModeToggle(this.value, this.onChanged, {super.key});

  final SendMode value;
  final ValueChanged<SendMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cpDim,
        borderRadius: BorderRadius.circular(cpRadiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in SendMode.values) _tab(m),
        ],
      ),
    );
  }

  Widget _tab(SendMode m) {
    final selected = m == value;
    return GestureDetector(
      onTap: () => onChanged(m),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cpPrint : Colors.transparent,
          borderRadius: BorderRadius.circular(cpRadiusPill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cpInkA(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          cpSendModeLabel(m),
          style: cpSans(
            size: 14,
            color: selected ? cpEuc : cpInkA(0.45),
            weight: selected ? FontWeight.w600 : FontWeight.w500,
            spacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// A soft stroke-thickness control: a rounded track, a pink circular thumb ringed
/// in warm white, and a live preview dot in the ink [color]. [value] and the
/// [onChanged] output range over 1..20.
class CpThickness extends StatelessWidget {
  const CpThickness({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        void update(double dx) {
          final t = (dx / w).clamp(0.0, 1.0);
          onChanged(1 + t * 19);
        }

        final t = ((value - 1) / 19).clamp(0.0, 1.0);
        return GestureDetector(
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cpInkA(0.12),
                    borderRadius: BorderRadius.circular(cpRadiusPill),
                  ),
                ),
                Container(
                  width: t * w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cpEucA(0.75),
                    borderRadius: BorderRadius.circular(cpRadiusPill),
                  ),
                ),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cpEuc,
                      shape: BoxShape.circle,
                      border: Border.all(color: cpPrint, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: cpInkA(0.10),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: value.clamp(3, 20),
                    height: value.clamp(3, 20),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A rounded action tile: a line [icon] over a [label]. [accent] warms the tile
/// and icon to the pink accent.
class CpAction extends StatelessWidget {
  const CpAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? cpEucA(0.12) : cpPrint,
              borderRadius: BorderRadius.circular(cpRadiusSmall),
              border: Border.all(
                color: accent ? cpEucA(0.4) : cpInkA(0.08),
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: accent ? cpEuc : cpInkA(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: cpSans(
              size: 11,
              color: accent ? cpEuc : cpInkA(0.6),
              spacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Pet pieces
// ===========================================================================

/// A coin-count pill on [cpDim] with a small PAINTED gold coin (no emoji).
class CpCoins extends StatelessWidget {
  const CpCoins(this.coins, {super.key});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cpDim,
        borderRadius: BorderRadius.circular(cpRadiusPill),
        border: Border.all(color: cpInkA(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CustomPaint(painter: _CoinPainter()),
          ),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: cpSans(size: 13, weight: FontWeight.w600, spacing: 0.3),
          ),
        ],
      ),
    );
  }
}

/// Paints a small gold coin: a filled [cpGold] disc with a subtle lighter inner
/// ring for a minted look. Purely decorative — the count lives beside it.
class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = cpGold
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      center,
      r * 0.6,
      Paint()
        ..color = cpMist.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinPainter oldDelegate) => false;
}

/// A soft rounded speech bubble — a warm-white slip the pet "says" on a pat,
/// framed by a gentle pink border. Carries a stable key so it fades cleanly in
/// switchers.
class CpSpeechSlip extends StatelessWidget {
  const CpSpeechSlip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: cpPrint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cpEucA(0.3)),
        boxShadow: [
          BoxShadow(
            color: cpInkA(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: cpSans(size: 13, weight: FontWeight.w500),
      ),
    );
  }
}

/// A soft rounded progress bar toward the next level. [growth] is 0..1; the
/// eyebrow reads [levelLabel] (default '다음 레벨') and the percentage is in accent.
class CpGrowth extends StatelessWidget {
  const CpGrowth(this.growth, {super.key, this.levelLabel = '다음 레벨'});

  final double growth;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    final pct = (growth.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: 224,
      child: Column(
        children: [
          Row(
            children: [
              CpEyebrow(levelLabel, size: 10),
              const Spacer(),
              Text(
                '$pct%',
                style: cpSans(size: 11, color: cpEuc, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(cpRadiusPill),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(width: w, height: 6, color: cpInkA(0.10)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 6,
                      color: cpEuc,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Album pieces
// ===========================================================================

/// A pill filter chip; selected chips warm to a soft pink tint + border.
class CpFilterChip extends StatelessWidget {
  const CpFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? cpEucA(0.12) : cpPrint,
            borderRadius: BorderRadius.circular(cpRadiusPill),
            border: Border.all(
              color: selected ? cpEucA(0.5) : cpInkA(0.10),
            ),
          ),
          child: Text(
            label,
            style: cpSans(
              size: 12,
              color: selected ? cpEuc : cpInkA(0.55),
              weight: selected ? FontWeight.w600 : FontWeight.w500,
              spacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontally-scrolling row of chips (typically [CpFilterChip]s).
class CpChipRow extends StatelessWidget {
  const CpChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.height = 40,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: children,
      ),
    );
  }
}

/// A two-segment date/type sort toggle — a soft pill control on [cpDim]; the
/// active segment lifts to a warm-white pill. Tapping toggles [byDate].
class CpSortToggle extends StatelessWidget {
  const CpSortToggle({super.key, required this.byDate, required this.onTap});

  final bool byDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? cpPrint : Colors.transparent,
            borderRadius: BorderRadius.circular(cpRadiusPill),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: cpInkA(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: cpSans(
              size: 11,
              color: on ? cpInk : cpInkA(0.45),
              weight: FontWeight.w600,
              spacing: 0.3,
            ),
          ),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cpDim,
          borderRadius: BorderRadius.circular(cpRadiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg('날짜별', byDate),
            const SizedBox(width: 2),
            seg('유형별', !byDate),
          ],
        ),
      ),
    );
  }
}

/// A section header: a soft [eyebrow] over a serif [title], with an optional
/// [trailing] control (e.g. [CpSortToggle]) pinned to the right.
class CpSectionHeader extends StatelessWidget {
  const CpSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CpEyebrow(eyebrow),
              const SizedBox(height: 6),
              Text(
                title,
                style: cpSerif(
                  size: 20,
                  weight: FontWeight.w600,
                  style: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ===========================================================================
// Doodle rendering
// ===========================================================================

/// Paints a doodle's [StrokeData] onto a canvas so real drawings display.
///
/// Points are in the authoring canvas's coordinate space ([StrokeData.canvas]);
/// they are scaled to fill the paint [Size]. Stroke widths scale by the smaller
/// axis so lines stay proportionate. An optional [background] fills first.
class CpDoodlePainter extends CustomPainter {
  const CpDoodlePainter(this.data, {this.background});

  final StrokeData data;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background!);
    }
    final cw = data.canvas.w <= 0 ? size.width : data.canvas.w.toDouble();
    final ch = data.canvas.h <= 0 ? size.height : data.canvas.h.toDouble();
    final sx = size.width / cw;
    final sy = size.height / ch;
    final s = sx < sy ? sx : sy; // uniform width scale

    for (final stroke in data.strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.colorValue
        ..strokeWidth = (stroke.width * s).clamp(0.5, double.infinity)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      if (stroke.points.length == 1) {
        final p = stroke.points.first;
        canvas.drawCircle(
          Offset(p.x * sx, p.y * sy),
          (stroke.width * s) / 2,
          Paint()
            ..color = stroke.colorValue
            ..isAntiAlias = true,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.x * sx, stroke.points.first.y * sy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x * sx, stroke.points[i].y * sy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CpDoodlePainter old) =>
      old.data != data || old.background != background;
}

/// A soft-rounded square thumbnail for a [Doodle].
///
/// If [strokes] are supplied it renders them with [CpDoodlePainter]; otherwise
/// it falls back to a muted pastel swatch derived deterministically from the
/// doodle's id, with a content-type line icon ([cpContentIcon]). The fallback is
/// an honest placeholder — it signals the *kind* of content, it never fakes a
/// drawing that isn't there. [active] warms the border to the pink accent.
class CpDoodleThumb extends StatelessWidget {
  const CpDoodleThumb(
    this.doodle, {
    super.key,
    this.strokes,
    this.size = 50,
    this.active = false,
  });

  final Doodle doodle;
  final StrokeData? strokes;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final swatch = _swatch(doodle.id);
    final border = Border.all(
      color: active ? cpEucA(0.6) : cpInkA(0.06),
      width: active ? 1.2 : 1,
    );
    final child = (strokes != null && strokes!.strokes.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(cpRadiusSmall),
            child: CustomPaint(
              size: Size.square(size),
              painter: CpDoodlePainter(strokes!, background: cpPrint),
            ),
          )
        : Center(
            child: Icon(
              cpContentIcon(doodle.contentType),
              size: size * 0.42,
              color: cpInkA(0.45),
            ),
          );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cpRadiusSmall),
        border: border,
        gradient: strokes != null
            ? null
            : LinearGradient(
                colors: [
                  Color.alphaBlend(cpPrint.withValues(alpha: 0.55), swatch.$1),
                  Color.alphaBlend(cpPrint.withValues(alpha: 0.55), swatch.$2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: child,
    );
  }

  /// Two muted colors seeded from [id] — a deterministic placeholder swatch.
  (Color, Color) _swatch(String id) {
    final hue = (id.hashCode % 360).abs().toDouble();
    final a = HSLColor.fromAHSL(1, hue, 0.30, 0.62).toColor();
    final b = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.28, 0.55).toColor();
    return (a, b);
  }
}

// ===========================================================================
// Bottom nav
// ===========================================================================

/// One tab of [CpBottomNav]: a line [icon] (inactive), a [activeIcon] (usually
/// the filled variant, shown when selected), and a short [label].
class CpNavItem {
  const CpNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// A soft floating bottom nav bar: warm cream, rounded top corners, a subtle top
/// hairline and a gentle upward shadow. Each [items] entry is a line icon over a
/// tiny label; the active tab lifts to a soft pink pill with the filled icon and
/// pink label.
class CpBottomNav extends StatelessWidget {
  const CpBottomNav({
    super.key,
    required this.current,
    required this.onTap,
    required this.items,
  });

  final int current;
  final ValueChanged<int> onTap;
  final List<CpNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(cpRadiusCard)),
        boxShadow: [
          BoxShadow(
            color: cpInkA(0.05),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(cpRadiusCard)),
        child: Container(
          decoration: BoxDecoration(
            color: cpMist,
            border: Border(top: BorderSide(color: cpInkA(0.06))),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _item(items[i], i, i == current)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(CpNavItem item, int index, bool active) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: active ? cpEucA(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(cpRadiusPill),
            ),
            child: Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? cpEuc : cpInkA(0.4),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: cpSans(
              size: 10.5,
              color: active ? cpEuc : cpInkA(0.4),
              weight: active ? FontWeight.w600 : FontWeight.w500,
              spacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Empty state
// ===========================================================================

/// A quiet empty state — a dimmed line [icon] in a soft disc over a single line
/// of [text]. Used to honestly signal "nothing here yet" instead of faking
/// content.
class CpEmptyState extends StatelessWidget {
  const CpEmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: cpDim,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: cpInkA(0.3)),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: cpSans(size: 13, color: cpInkA(0.5), spacing: 0.2),
          ),
        ],
      ),
    );
  }
}
