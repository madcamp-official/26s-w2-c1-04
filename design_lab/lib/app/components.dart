// Cold Press — DESIGN SYSTEM · components.
//
// The Cold Press widgets promoted to PUBLIC, reusable components for the real
// Memory Pager app. Every widget here mirrors the private originals from
// lib/designs/design_11_cold_press faithfully: sharp 1–2px radii, 0.5px
// hairline borders, tracked-caps eyebrows, generous whitespace, and — the
// signature — a hairline passe-partout keyline framing the one hero element.
//
// Self-contained: Flutter Material/services only. No packages, assets,
// network, Random, or DateTime.now().

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/models.dart';
import 'theme.dart';

// ======================================================= scaffold / chrome

/// A mist-ground scaffold with SafeArea and an optional quiet top bar
/// (leading + centered title + actions) and an optional pinned [bottom]
/// (e.g. [CpBottomNav]). [body] fills the space between.
class CpScaffold extends StatelessWidget {
  const CpScaffold({
    super.key,
    this.title,
    this.leading,
    this.actions,
    required this.body,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(28, 14, 28, 16),
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottom;
  final EdgeInsets padding;

  bool get _hasBar => title != null || leading != null || actions != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cpMist,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasBar) ...[
                      _bar(),
                      const SizedBox(height: 20),
                    ],
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }

  Widget _bar() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (title != null)
            Center(
              child: Text(
                title!,
                style: cpSans(size: 17, weight: FontWeight.w600, spacing: 0.4),
              ),
            ),
          if (leading != null)
            Align(alignment: Alignment.centerLeft, child: leading!),
          if (actions != null && actions!.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ),
        ],
      ),
    );
  }
}

// ================================================================ signature

/// THE SIGNATURE — a hairline passe-partout. Content floats in a wide
/// off-white mat, framed by a single 0.5px inset keyline. Use once per screen
/// on the one hero element.
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
          // the single hairline keyline — the only ornament.
          border: Border.all(color: cpInkA(keyline), width: 0.5),
        ),
        padding: EdgeInsets.all(inset),
        child: child,
      ),
    );
  }
}

// ============================================================ small atoms

/// Tracked-caps eyebrow label. Uppercases its text and applies the quiet
/// architectural label voice at ~0.55 opacity of [color].
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

/// A 1px hairline divider in ink at a whisper opacity.
class CpHair extends StatelessWidget {
  const CpHair({super.key, this.opacity = 0.10});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: cpInkA(opacity));
}

/// A quiet tappable icon with a comfortable hit target.
class CpIconTap extends StatelessWidget {
  const CpIconTap({super.key, required this.icon, required this.onTap});
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

/// The Cold Press button. [filled] (default) is a sharp slate block with
/// tracked mist caps; unfilled is a hairline-outlined ink label.
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
              : Border.all(color: cpInkA(0.5), width: 0.5),
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

/// A Cold Press text field — sharp corners, a single 0.5px hairline border,
/// print surface, and an optional tracked-caps [label] above it.
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
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: cpPrint,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: cpInkA(0.14), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            cursorColor: cpEuc,
            cursorWidth: 1.5,
            style: cpSans(size: 14, spacing: 0.3),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: cpSans(size: 14, color: cpInkA(0.35), spacing: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================== send mode

/// The 일반 / 사라지기 underline tabs. Renders every [SendMode] with an
/// eucalyptus underline under the selected one; calls [onChanged] on tap.
class CpModeToggle extends StatelessWidget {
  const CpModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });
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
    final selected = value == m;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(m);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.label,
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

/// A minimal thickness control — no Material Slider chrome. A hairline track,
/// a small square-stone thumb, and a live ink-colour preview dot on the right.
class CpThickness extends StatelessWidget {
  const CpThickness({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
  });
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final span = (max - min);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        void update(double dx) {
          final t = (dx / w).clamp(0.0, 1.0);
          onChanged(min + t * span);
        }

        final t = ((value - min) / span).clamp(0.0, 1.0);
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

/// A quiet square action tile: a glyph in a sharp print frame with a tracked
/// label beneath. [accent] switches the frame to a eucalyptus tint.
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

// ============================================================== pet pieces

/// The coin balance pill — a dim-ground chip with a hairline border.
class CpCoins extends StatelessWidget {
  const CpCoins({super.key, required this.coins});
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

/// The pet's speech slip — a small print card framed by an accent hairline.
class CpSpeechSlip extends StatelessWidget {
  const CpSpeechSlip({super.key, required this.text});
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

/// The "다음 레벨" growth bar — an eyebrow + percentage over a 3px hair rail.
/// Fills the parent width unless a [width] is given.
class CpGrowth extends StatelessWidget {
  const CpGrowth({super.key, required this.growth, this.width});
  final double growth;
  final double? width;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const CpEyebrow('다음 레벨', size: 9),
            const Spacer(),
            Text(
              '$pct%',
              style: cpSans(size: 11, color: cpEuc, weight: FontWeight.w600),
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
    );
    return width == null ? content : SizedBox(width: width, child: content);
  }
}

/// A small store card for a [PetItem]: emoji + name + a status line
/// (착용중 / 보유 / price). An optional [trailing] overrides the status line.
class CpStoreCard extends StatelessWidget {
  const CpStoreCard({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });
  final PetItem item;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cpPrint,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: item.equipped ? cpEucA(0.55) : cpInkA(0.10),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cpSans(size: 11),
            ),
            const SizedBox(height: 6),
            trailing ?? _statusLine(item),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(PetItem it) {
    if (it.equipped) {
      return Text(
        '착용중',
        style: cpSans(
          size: 9,
          color: cpEuc,
          weight: FontWeight.w600,
          spacing: 1,
        ),
      );
    }
    if (it.owned) {
      return Text(
        '보유',
        style: cpSans(size: 9, color: cpInkA(0.45), spacing: 1),
      );
    }
    return Text('🪙 ${it.price}', style: cpSans(size: 9, color: cpInkA(0.6)));
  }
}

// ============================================================ album pieces

/// The 날짜별 / 유형별 sort toggle — a hairline-bordered pill with a filled
/// slate segment marking the active sort.
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

/// A sharp filter chip — hairline border, eucalyptus tint when [selected].
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

/// A muted swatch tile — a doodle's gradient stand-in with its emoji centred.
/// The swatch colours are blended toward the print field so nothing shouts.
/// Used inside memory rows and featured cards.
class CpSwatchTile extends StatelessWidget {
  const CpSwatchTile({
    super.key,
    required this.swatch,
    required this.emoji,
    this.size = 50,
    this.emojiSize = 22,
    this.blend = 0.38,
    this.radius = 1,
    this.borderColor,
  });
  final List<Color> swatch;
  final String emoji;
  final double size;
  final double emojiSize;
  final double blend;
  final double radius;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) {
    final first = swatch.isNotEmpty ? swatch.first : cpDim;
    final last = swatch.isNotEmpty ? swatch.last : cpDim;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(cpPrint.withOpacity(blend), first),
            Color.alphaBlend(cpPrint.withOpacity(blend), last),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 0.5),
      ),
      child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}

// ============================================================== bottom nav

/// The underline bottom nav. Labels are ['펫키우기','사진첩','소통'] at index
/// 0/1/2; the active tab wears a short eucalyptus underline. Taps call
/// [onTap] with the tapped index.
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
          for (int i = 0; i < labels.length; i++)
            _navItem(labels[i], i, i == current),
        ],
      ),
    );
  }

  Widget _navItem(String label, int index, bool active) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
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
