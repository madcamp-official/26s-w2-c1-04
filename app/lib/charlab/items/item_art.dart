// Hand-drawn pet items — one place that knows how to paint each catalog item
// both as a SHOP THUMBNAIL (the item alone) and WORN ON A PET (placed at the
// species anchor for its slot). No emoji, no assets: everything is vector,
// drawn with the same warm hand as the pets (toolkit `Hand`).
//
// Each item is an [ItemArt]. It draws itself into a unit box (0..0 → size×size);
// the shop shows it centered, and [PetItemLayer] scales+places it on the pet via
// the species [PetAnchors]. The mock catalog ids (11,12,21,22,31,32,41,42) map
// to concrete arts in [itemArtById]; unknown ids fall back to a soft dot so the
// UI never shows a broken slot (and never a fake — a plain marker, honestly).

import 'package:flutter/material.dart';

import '../anchors.dart';
import '../toolkit.dart';

/// Warm palette shared by items (kept close to the app tokens, but this file is
/// charlab-local so it has no app import).
class _Ink {
  static const line = Color(0xFF6B5B47); // warm brown outline
  static const cream = Color(0xFFFFFDF7);
  static const pink = Color(0xFFD98A93);
  static const gold = Color(0xFFC99A5B);
  static const sage = Color(0xFFA3B49E);
  static const sky = Color(0xFF9FB4C4);
  static const straw = Color(0xFFDCC9A3);
}

/// One drawable item.
abstract class ItemArt {
  const ItemArt();

  /// Catalog id (matches the mock `Item.id`).
  String get id;

  /// Which body slot it occupies.
  ItemSlot get slot;

  /// Relative size within the pet box for the worn render (0..1 of box width),
  /// before the species [PetAnchors.unit] multiplier.
  double get wornScale;

  /// Paint the item into a [size]×[size] box (origin top-left). Used for both
  /// the shop thumbnail and (scaled) the worn overlay.
  void paint(Canvas canvas, Size size);
}

/// Look up an item's art by catalog id.
ItemArt itemArtById(String id) => _items[id] ?? _FallbackDot(id);

/// A shop thumbnail of an item — the item art alone, centered in a [size] box.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.itemId, {super.key, this.size = 44});

  final String itemId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ThumbPainter(itemArtById(itemId))),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.art);
  final ItemArt art;
  @override
  void paint(Canvas canvas, Size size) => art.paint(canvas, size);
  @override
  bool shouldRepaint(_ThumbPainter old) => old.art.id != art.id;
}

/// A soft neutral marker for an id we have no art for — honest, not a fake item.
class _FallbackDot extends ItemArt {
  const _FallbackDot(this.id);
  @override
  final String id;
  @override
  ItemSlot get slot => ItemSlot.prop;
  @override
  double get wornScale => 0.18;
  @override
  void paint(Canvas c, Size s) {
    c.drawCircle(s.center(Offset.zero), s.width * 0.18,
        Paint()..color = _Ink.line.withValues(alpha: 0.22));
  }
}

// ===========================================================================
// A widget that overlays a pet's worn items on top of the pet box.
// ===========================================================================

/// Paints all [itemIds] worn on the species, each at its slot anchor. Stack this
/// OVER a [PetView] of the same [box] size.
class PetItemLayer extends StatelessWidget {
  const PetItemLayer({
    super.key,
    required this.speciesId,
    required this.itemIds,
    required this.box,
  });

  final String speciesId;
  final List<String> itemIds;
  final double box;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: box,
        height: box,
        child: CustomPaint(
          painter: _WornPainter(anchorsFor(speciesId), itemIds),
        ),
      ),
    );
  }
}

class _WornPainter extends CustomPainter {
  _WornPainter(this.anchors, this.itemIds);
  final PetAnchors anchors;
  final List<String> itemIds;

  @override
  void paint(Canvas canvas, Size size) {
    // Body items first, then face, then hats on top (natural layering).
    final arts = itemIds.map(itemArtById).toList()
      ..sort((a, b) => _z(a.slot).compareTo(_z(b.slot)));
    for (final art in arts) {
      final anchor = anchors.of(art.slot);
      final w = size.width * art.wornScale * anchors.unit;
      final center = Offset(anchor.dx * size.width, anchor.dy * size.height);
      canvas.save();
      canvas.translate(center.dx - w / 2, center.dy - w / 2);
      art.paint(canvas, Size(w, w));
      canvas.restore();
    }
  }

  int _z(ItemSlot s) => switch (s) {
        ItemSlot.body => 0,
        ItemSlot.prop => 1,
        ItemSlot.face => 2,
        ItemSlot.hat => 3,
      };

  @override
  bool shouldRepaint(_WornPainter old) =>
      old.itemIds.join() != itemIds.join();
}

// ===========================================================================
// The catalog. Concrete arts (workflow refines these). Kept simple + warm.
// ===========================================================================

final Map<String, ItemArt> _items = {
  '11': const _StrawHat(),
  '12': const _PartyHat(),
  '21': const _Raincoat(),
  '22': const _StripeTee(),
  '31': const _Cushion(),
  '32': const _Desk(),
  '41': const _Ball(),
  '42': const _BowTie(),
};

Paint get _outline => Hand.outline(_Ink.line, 3);
Paint _fill(Color c) => Hand.fill(c);

// -- hats -------------------------------------------------------------------
class _StrawHat extends ItemArt {
  const _StrawHat();
  @override
  String get id => '11';
  @override
  ItemSlot get slot => ItemSlot.hat;
  @override
  double get wornScale => 0.42;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // brim
    final brim = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.72), width: w * 0.98, height: h * 0.32));
    c.drawPath(brim, _fill(_Ink.straw));
    c.drawPath(brim, _outline);
    // crown
    final crown = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.48), width: w * 0.5, height: h * 0.5),
          Radius.circular(w * 0.14)));
    c.drawPath(crown, _fill(_Ink.straw));
    c.drawPath(crown, _outline);
    // band
    c.drawRect(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.62), width: w * 0.5, height: h * 0.09),
        _fill(_Ink.pink));
  }
}

class _PartyHat extends ItemArt {
  const _PartyHat();
  @override
  String get id => '12';
  @override
  ItemSlot get slot => ItemSlot.hat;
  @override
  double get wornScale => 0.36;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final cone = Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.22, h * 0.8)
      ..lineTo(w * 0.78, h * 0.8)
      ..close();
    c.drawPath(cone, _fill(_Ink.pink));
    c.drawPath(cone, _outline);
    // stripes
    for (var i = 0; i < 3; i++) {
      final y = h * (0.34 + i * 0.16);
      c.drawLine(Offset(w * (0.5 - (y / h) * 0.36), y),
          Offset(w * (0.5 + (y / h) * 0.36), y), Hand.outline(_Ink.cream, 2.4));
    }
    // pom
    c.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.09, _fill(_Ink.gold));
    c.drawCircle(Offset(w * 0.5, h * 0.1), w * 0.09, _outline);
  }
}

// -- clothes ----------------------------------------------------------------
class _Raincoat extends ItemArt {
  const _Raincoat();
  @override
  String get id => '21';
  @override
  ItemSlot get slot => ItemSlot.body;
  @override
  double get wornScale => 0.62;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = Path()
      ..moveTo(w * 0.24, h * 0.28)
      ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.76, h * 0.28)
      ..lineTo(w * 0.82, h * 0.9)
      ..lineTo(w * 0.18, h * 0.9)
      ..close();
    c.drawPath(body, _fill(_Ink.straw));
    c.drawPath(body, _outline);
    c.drawLine(Offset(w * 0.5, h * 0.22), Offset(w * 0.5, h * 0.9),
        Hand.outline(_Ink.line, 1.8));
  }
}

class _StripeTee extends ItemArt {
  const _StripeTee();
  @override
  String get id => '22';
  @override
  ItemSlot get slot => ItemSlot.body;
  @override
  double get wornScale => 0.6;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.24, w * 0.6, h * 0.62),
        Radius.circular(w * 0.14));
    c.drawRRect(body, _fill(_Ink.cream));
    c.drawRRect(body, _outline);
    for (var i = 0; i < 3; i++) {
      final y = h * (0.36 + i * 0.16);
      c.drawLine(Offset(w * 0.22, y), Offset(w * 0.78, y),
          Hand.outline(_Ink.sky, 3));
    }
  }
}

// -- props ------------------------------------------------------------------
class _Cushion extends ItemArt {
  const _Cushion();
  @override
  String get id => '31';
  @override
  ItemSlot get slot => ItemSlot.prop;
  @override
  double get wornScale => 0.4;
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.12, s.height * 0.4, s.width * 0.76, s.height * 0.4),
        Radius.circular(s.width * 0.16));
    c.drawRRect(r, _fill(_Ink.sage));
    c.drawRRect(r, _outline);
  }
}

class _Desk extends ItemArt {
  const _Desk();
  @override
  String get id => '32';
  @override
  ItemSlot get slot => ItemSlot.prop;
  @override
  double get wornScale => 0.44;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.76, h * 0.12),
        _fill(_Ink.straw));
    c.drawRect(Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.76, h * 0.12), _outline);
    c.drawRect(Rect.fromLTWH(w * 0.18, h * 0.54, w * 0.08, h * 0.28), _fill(_Ink.straw));
    c.drawRect(Rect.fromLTWH(w * 0.74, h * 0.54, w * 0.08, h * 0.28), _fill(_Ink.straw));
  }
}

class _Ball extends ItemArt {
  const _Ball();
  @override
  String get id => '41';
  @override
  ItemSlot get slot => ItemSlot.prop;
  @override
  double get wornScale => 0.3;
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width * 0.5, s.height * 0.6);
    c.drawCircle(center, s.width * 0.34, _fill(_Ink.pink));
    c.drawCircle(center, s.width * 0.34, _outline);
    c.drawArc(
        Rect.fromCircle(center: center, radius: s.width * 0.34),
        3.6, 1.6, false, Hand.outline(_Ink.cream, 2.4));
  }
}

// -- accessory (face) -------------------------------------------------------
class _BowTie extends ItemArt {
  const _BowTie();
  @override
  String get id => '42';
  @override
  ItemSlot get slot => ItemSlot.body;
  @override
  double get wornScale => 0.34;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final left = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.18, h * 0.34)
      ..lineTo(w * 0.18, h * 0.66)
      ..close();
    final right = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.82, h * 0.34)
      ..lineTo(w * 0.82, h * 0.66)
      ..close();
    for (final p in [left, right]) {
      c.drawPath(p, _fill(_Ink.pink));
      c.drawPath(p, _outline);
    }
    c.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.08, _fill(_Ink.pink));
    c.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.08, _outline);
  }
}
