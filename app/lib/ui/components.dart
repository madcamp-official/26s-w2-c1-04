// Cold Press — reusable widgets for the Memory Pager app.
//
// The signature ornament is a hairline passe-partout ([CpMatted]): content
// floats in a wide off-white mat, framed by a single 0.5px inset keyline.
// Everything else is quiet — tracked-caps eyebrows, hairline rules, one accent.
//
// All names are PUBLIC (no underscores). Widgets are built against the real app
// domain models in `../core/models.dart`, not the design-lab mock data.

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'theme.dart';

// ===========================================================================
// Send-mode labels
// ===========================================================================
// The real [SendMode] enum ({normal, ephemeral}) is a wire contract and carries
// no display copy, so the Cold Press label/description live here.

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

/// Glyph standing in for a doodle's content when no thumbnail/strokes exist.
String cpContentGlyph(ContentType type) => switch (type) {
      ContentType.photo => '📷',
      ContentType.drawing => '✏️',
      ContentType.text => '✍️',
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
                padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 10),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          style: cpSans(size: 20, weight: FontWeight.w600),
                        ),
                      )
                    else
                      const Spacer(),
                    if (actions != null)
                      for (final a in actions!) ...[
                        const SizedBox(width: 8),
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
// Passe-partout — THE signature
// ===========================================================================

/// The hairline passe-partout: [child] floats inside a [mat] of [matColor],
/// framed by a single 0.5px inset [keyline]. The one ornament of Cold Press.
class CpMatted extends StatelessWidget {
  const CpMatted({
    super.key,
    required this.child,
    this.mat = 18,
    this.inset = 0,
    this.matColor = cpPrint,
    this.radius = 2,
    this.keyline = 0.30,
  });

  final Widget child;
  final double mat;
  final double inset;
  final double radius;

  /// Ink opacity (0..1) of the inset keyline.
  final double keyline;
  final Color matColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: matColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cpInkA(0.07)),
      ),
      padding: EdgeInsets.all(mat),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: cpInkA(keyline), width: 0.5),
        ),
        padding: EdgeInsets.all(inset),
        child: child,
      ),
    );
  }
}

// ===========================================================================
// Small quiet primitives
// ===========================================================================

/// Tracked-caps eyebrow label. Uppercases [text] and dims [color] to 0.55.
class CpEyebrow extends StatelessWidget {
  const CpEyebrow(this.text, {super.key, this.color = cpInk, this.size = 10});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: cpEyebrowStyle(color: color.withOpacity(0.55), size: size),
    );
  }
}

/// A 1px hairline rule at ink opacity [opacity].
class CpHair extends StatelessWidget {
  const CpHair({super.key, this.opacity = 0.10});

  final double opacity;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: cpInkA(opacity));
}

/// A quiet, chromeless icon tap target (20px glyph at 0.7 ink).
class CpIconButton extends StatelessWidget {
  const CpIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: cpInkA(0.7)),
      ),
    );
  }
}

/// A primary action button. [filled] (default) is ink on ground; unfilled is a
/// hairline outline with ink text. Tracked caps, radius 2 — no Material chrome.
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? cpInk : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: filled
              ? null
              : Border.all(color: cpInkA(0.45), width: 0.5),
        ),
        child: Text(
          label,
          style: cpSans(
            size: 12,
            color: filled ? cpMist : cpInk,
            weight: FontWeight.w600,
            spacing: 1.6,
          ),
        ),
      ),
    );
  }
}

/// A Cold Press text field: optional eyebrow [label], hairline underline that
/// warms to [cpEuc] on focus, and a quiet [hint].
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
            hintText: hint,
            hintStyle: cpSans(size: 16, color: cpInkA(0.35)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cpInkA(0.18), width: 0.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: cpEuc, width: 1),
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

/// The send-mode toggle: one underlined tab per [SendMode], the selected one
/// inked and warmed with a [cpEuc] underline. Labels come from
/// [cpSendModeLabel]; pair with [cpSendModeDescription] for the caption line.
class CpModeToggle extends StatelessWidget {
  const CpModeToggle(this.value, this.onChanged, {super.key});

  final SendMode value;
  final ValueChanged<SendMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final m in SendMode.values) ...[
          _tab(m),
          if (m != SendMode.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _tab(SendMode m) {
    final selected = m == value;
    return GestureDetector(
      onTap: () => onChanged(m),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cpSendModeLabel(m),
            style: cpSans(
              size: 14,
              color: selected ? cpInk : cpInkA(0.4),
              weight: selected ? FontWeight.w600 : FontWeight.w400,
              spacing: 0.6,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 1.5,
            width: 48,
            color: selected ? cpEuc : cpInkA(0.08),
          ),
        ],
      ),
    );
  }
}

/// Minimal stroke-thickness control (no Material Slider chrome): a hairline
/// track, a small square stone thumb, and a live preview dot of the ink
/// [color]. [value] and the [onChanged] output range over 1..20.
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
                Container(width: w, height: 1, color: cpInkA(0.14)),
                Container(width: t * w, height: 1.5, color: cpEucA(0.8)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cpInk,
                      borderRadius: BorderRadius.circular(1),
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

/// A quiet square action (glyph tile + label). [accent] warms it to eucalyptus.
class CpAction extends StatelessWidget {
  const CpAction({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String glyph;
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
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? cpEucA(0.12) : cpPrint,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: accent ? cpEucA(0.5) : cpInkA(0.12),
                width: 0.5,
              ),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: cpSans(
              size: 11,
              color: accent ? cpEuc : cpInkA(0.6),
              spacing: 0.6,
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

/// A coin count pill on [cpDim] with a 🪙 glyph.
class CpCoins extends StatelessWidget {
  const CpCoins(this.coins, {super.key});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cpDim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: cpInkA(0.10), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text(
            '$coins',
            style: cpSans(size: 13, weight: FontWeight.w600, spacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// A small speech slip — a printed card the pet "says" on a pat. Framed by a
/// eucalyptus hairline. Carries a stable key so it fades cleanly in switchers.
class CpSpeechSlip extends StatelessWidget {
  const CpSpeechSlip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: cpPrint,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: cpEucA(0.45), width: 0.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: cpSans(size: 13, weight: FontWeight.w500),
      ),
    );
  }
}

/// A hairline progress bar toward the next level. [growth] is 0..1; the eyebrow
/// reads [levelLabel] (default '다음 레벨') and the percentage is shown in accent.
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
              CpEyebrow(levelLabel, size: 9),
              const Spacer(),
              Text(
                '$pct%',
                style:
                    cpSans(size: 11, color: cpEuc, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(width: w, height: 3, color: cpInkA(0.10)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 3,
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

/// A pill filter chip; selected chips warm to a eucalyptus keyline + tint.
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cpEucA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: selected ? cpEucA(0.5) : cpInkA(0.14),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: cpSans(
              size: 11,
              color: selected ? cpInk : cpInkA(0.55),
              weight: selected ? FontWeight.w600 : FontWeight.w500,
              spacing: 0.6,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 28),
    this.height = 34,
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

/// A two-segment date/type sort toggle (inked pill segments).
class CpSortToggle extends StatelessWidget {
  const CpSortToggle({super.key, required this.byDate, required this.onTap});

  final bool byDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? cpInk : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(
            label,
            style: cpSans(
              size: 10,
              color: on ? cpMist : cpInkA(0.45),
              weight: FontWeight.w600,
              spacing: 0.6,
            ),
          ),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: cpInkA(0.12), width: 0.5),
        ),
        child: Row(
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

/// A section header: a tracked-caps [eyebrow] over a [title], with an optional
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
              const SizedBox(height: 5),
              Text(title, style: cpSans(size: 20, weight: FontWeight.w600)),
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

/// A square thumbnail for a [Doodle].
///
/// If [strokes] are supplied it renders them with [CpDoodlePainter]; otherwise
/// it falls back to a muted swatch derived deterministically from the doodle's
/// id, with a content-type glyph. The fallback is an honest placeholder — it
/// signals the *kind* of content, it never fakes a drawing that isn't there.
/// [active] warms the keyline to eucalyptus.
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
      width: 0.5,
    );
    final child = (strokes != null && strokes!.strokes.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: CustomPaint(
              size: Size.square(size),
              painter: CpDoodlePainter(strokes!, background: cpPrint),
            ),
          )
        : Center(
            child: Text(
              cpContentGlyph(doodle.contentType),
              style: TextStyle(fontSize: size * 0.44),
            ),
          );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: border,
        gradient: strokes != null
            ? null
            : LinearGradient(
                colors: [
                  Color.alphaBlend(cpPrint.withOpacity(0.38), swatch.$1),
                  Color.alphaBlend(cpPrint.withOpacity(0.38), swatch.$2),
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

/// The three-tab bottom nav — '펫키우기' / '사진첩' / '소통'. The active tab is
/// inked and topped with a short eucalyptus tick.
class CpBottomNav extends StatelessWidget {
  const CpBottomNav({super.key, required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  static const List<String> labels = ['펫키우기', '사진첩', '소통'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: cpMist,
        border: Border(top: BorderSide(color: Color(0x1A26282B))),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < labels.length; i++)
            _item(labels[i], i, i == current),
        ],
      ),
    );
  }

  Widget _item(String label, int index, bool active) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1.5,
            width: 16,
            color: active ? cpEuc : Colors.transparent,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: cpSans(
              size: 12,
              color: active ? cpInk : cpInkA(0.4),
              weight: active ? FontWeight.w600 : FontWeight.w400,
              spacing: 0.8,
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

/// A quiet empty state — a dimmed [icon] over a single line of [text]. Used to
/// honestly signal "nothing here yet" instead of faking content.
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
          Icon(icon, size: 34, color: cpInkA(0.28)),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: cpSans(size: 13, color: cpInkA(0.5), spacing: 0.4),
          ),
        ],
      ),
    );
  }
}
