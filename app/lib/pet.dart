// 펫 "모리" — 디자인 SVG(viewBox 0 0 120 110)를 CustomPainter 로 옮김.
// 몸통 ellipse(60,62,rx42,ry38) + 귀 circle(30,26,r12)(90,26,r12) + 눈 + 볼 + 미소.
//
// 꾸미기 아이템(#5)은 이모지 오버레이(하얀 테두리·둥둥 뜸)를 버리고, 몸통 좌표계
// 안에서 직접 그린다: 모자는 머리 위, 옷은 몸통 실루엣에 클립해 "입은" 느낌, 안경/목도리는
// 얼굴·목에 얹는다. 배경/가구/소품은 방 장면으로 페인트한다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mock.dart';
import 'theme.dart';

// 착용 아이템 한 개 — 이모지(실서버) 또는 이름(데모)으로 어떤 모양을 그릴지 고른다.
typedef WornItem = ({String? emoji, String? name});

WornItem? _wi(StoreItem? it) =>
    it == null ? null : (emoji: it.emoji, name: it.name);

/// 펫이 입고/쓰고 있는 것(#5). null 이면 해당 부위 미착용.
class PetOutfit {
  const PetOutfit({this.hat, this.clothes, this.acc});
  final WornItem? hat;
  final WornItem? clothes;
  final WornItem? acc;
  bool get isEmpty => hat == null && clothes == null && acc == null;
}

enum _Hat { fedora, beanie, straw, beret, ribbon, sprout, crown }
enum _Cloth { shirt, hoodie, dress, suit, space }
enum _Acc { glasses, sunglasses, scarf, bag }
enum _Bg { mint, flower, night, beach, mountain }
enum _Furn { plant, rug, books, sofa, clock, fire }
enum _Prop { balloon, cake, gift, bouquet }

bool _has(WornItem w, String emoji, List<String> names) {
  final e = w.emoji ?? '';
  final n = w.name ?? '';
  return e.contains(emoji) || names.any(n.contains);
}

_Hat? _hatKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '🎩', ['중절모'])) return _Hat.fedora;
  if (_has(w, '🧢', ['비니'])) return _Hat.beanie;
  if (_has(w, '👒', ['밀짚'])) return _Hat.straw;
  if (_has(w, '🍓', ['딸기', '베레'])) return _Hat.beret;
  if (_has(w, '🎀', ['리본'])) return _Hat.ribbon;
  if (_has(w, '🌱', ['새싹'])) return _Hat.sprout;
  if (_has(w, '👑', ['왕관'])) return _Hat.crown;
  return _Hat.fedora;
}

_Cloth? _clothKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '👕', ['티셔츠', '티'])) return _Cloth.shirt;
  if (_has(w, '🧥', ['후드', '자켓', '재킷'])) return _Cloth.hoodie;
  if (_has(w, '👗', ['원피스', '드레스'])) return _Cloth.dress;
  if (_has(w, '🤵', ['정장', '수트'])) return _Cloth.suit;
  if (_has(w, '🚀', ['우주'])) return _Cloth.space;
  return _Cloth.shirt;
}

_Acc? _accKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '🕶', ['선글라스'])) return _Acc.sunglasses;
  if (_has(w, '👓', ['안경'])) return _Acc.glasses;
  if (_has(w, '🧣', ['목도리', '머플러'])) return _Acc.scarf;
  if (_has(w, '🎒', ['가방', '백팩'])) return _Acc.bag;
  return _Acc.glasses;
}

_Bg? _bgKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '🟩', ['민트'])) return _Bg.mint;
  if (_has(w, '🌸', ['벚꽃', '꽃'])) return _Bg.flower;
  if (_has(w, '🌌', ['밤하늘', '밤'])) return _Bg.night;
  if (_has(w, '🏖', ['바닷가', '바다'])) return _Bg.beach;
  if (_has(w, '🏔', ['설원', '산'])) return _Bg.mountain;
  return _Bg.mint;
}

_Furn? _furnKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '🪴', ['화분', '식물'])) return _Furn.plant;
  if (_has(w, '🟫', ['러그', '카펫'])) return _Furn.rug;
  if (_has(w, '📚', ['책장', '책'])) return _Furn.books;
  if (_has(w, '🛋', ['소파'])) return _Furn.sofa;
  if (_has(w, '🕰', ['괘종', '시계'])) return _Furn.clock;
  if (_has(w, '🔥', ['벽난로', '난로'])) return _Furn.fire;
  return _Furn.plant;
}

_Prop? _propKind(WornItem? w) {
  if (w == null) return null;
  if (_has(w, '🎈', ['풍선'])) return _Prop.balloon;
  if (_has(w, '🍰', ['케이크'])) return _Prop.cake;
  if (_has(w, '🎁', ['선물'])) return _Prop.gift;
  if (_has(w, '💐', ['화환', '꽃다발'])) return _Prop.bouquet;
  return _Prop.balloon;
}

/// 펫 + 착용/배치 아이템(#5) — 방 안에 펫이 앉아 있고, 배경·가구·소품이 방을,
/// 모자·옷·액세서리가 펫을 꾸미는 '작은 방 장면'. 미리보기(132)·전체화면(200)에서
/// 동일 비율로 보이도록 모든 요소를 size 비율로 배치한다.
class DecoratedPet extends StatelessWidget {
  const DecoratedPet({
    super.key,
    required this.size,
    this.color = salmon,
    this.faceInk = ink,
    this.showBackground = true,
  });

  final double size;
  final Color color;
  final Color faceInk;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final s = size;
    final outfit = PetOutfit(
      hat: _wi(mock.equippedItem('hat')),
      clothes: _wi(mock.equippedItem('clothes')),
      acc: _wi(mock.equippedItem('accessory')),
    );
    final bg = _wi(mock.equippedItem('background'));
    final furn = _wi(mock.equippedItem('furniture'));
    final prop = _wi(mock.equippedItem('prop'));

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 배경 벽 장식(#5) — 큰 반투명 이모지 대신 방 뒷벽을 페인트한다.
          if (showBackground && bg != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: s * 0.74,
              child: CustomPaint(painter: _RoomBgPainter(_bgKind(bg)!)),
            ),
          // 바닥 그림자 — 펫이 바닥에 앉아 있는 느낌.
          Positioned(
            bottom: s * 0.065,
            left: s * 0.2,
            right: s * 0.2,
            child: Container(
              height: s * 0.045,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // 가구 — 바닥 왼쪽(펫 뒤).
          if (furn != null)
            Positioned(
              bottom: s * 0.05,
              left: 0,
              width: s * 0.32,
              height: s * 0.4,
              child: CustomPaint(painter: _FurniturePainter(_furnKind(furn)!)),
            ),
          // 펫 — 바닥 중앙. 아이템 자리를 위해 살짝 작게(0.82).
          Positioned(
            bottom: s * 0.09,
            left: 0,
            right: 0,
            child: Center(
              child: PetFace(
                size: s * 0.82,
                color: color,
                faceInk: faceInk,
                outfit: outfit,
              ),
            ),
          ),
          // 소품 — 바닥 오른쪽(펫 앞, 작은 전경 오브젝트).
          if (prop != null)
            Positioned(
              bottom: s * 0.05,
              right: 0,
              width: s * 0.3,
              height: s * 0.38,
              child: CustomPaint(painter: _PropPainter(_propKind(prop)!)),
            ),
        ],
      ),
    );
  }
}

class PetFace extends StatelessWidget {
  const PetFace({
    super.key,
    this.size = 120,
    this.color = salmon,
    this.faceInk = ink,
    this.hat = false,
    this.cheeks = true,
    this.eyesOpen = true,
    this.outfit,
  });

  final double size;
  final Color color;
  final Color faceInk;
  final bool hat;
  final bool cheeks;
  final bool eyesOpen;
  final PetOutfit? outfit;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 110 / 120),
      painter: _PetPainter(
        color: color,
        faceInk: faceInk,
        hat: hat,
        cheeks: cheeks,
        eyesOpen: eyesOpen,
        outfit: outfit,
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  const _PetPainter({
    required this.color,
    required this.faceInk,
    required this.hat,
    required this.cheeks,
    required this.eyesOpen,
    this.outfit,
  });

  final Color color;
  final Color faceInk;
  final bool hat;
  final bool cheeks;
  final bool eyesOpen;
  final PetOutfit? outfit;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120, sy = size.height / 110;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final body = Paint()..color = color;

    final clothKind = _clothKind(outfit?.clothes);
    final accKind = _accKind(outfit?.acc);
    final hatKind = hat ? _Hat.fedora : _hatKind(outfit?.hat);

    // 귀 → 몸통 (디자인 SVG 순서)
    canvas.drawCircle(p(30, 26), 12 * sx, body);
    canvas.drawCircle(p(90, 26), 12 * sx, body);
    final bodyOval =
        Rect.fromCenter(center: p(60, 62), width: 84 * sx, height: 76 * sy);
    canvas.drawOval(bodyOval, body);

    // 옷 — 몸통 실루엣에 클립해 아래쪽을 감싼다("입은" 느낌, 하얀 테두리 없음).
    if (clothKind != null) _paintClothes(canvas, sx, sy, clothKind, bodyOval);

    // 볼 (흰 55%)
    if (cheeks) {
      final cheek = Paint()..color = Colors.white.withValues(alpha: 0.55);
      canvas.drawOval(
        Rect.fromCenter(center: p(38, 70), width: 12 * sx, height: 8 * sy),
        cheek,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p(82, 70), width: 12 * sx, height: 8 * sy),
        cheek,
      );
    }

    // 눈
    final eye = Paint()..color = faceInk;
    if (eyesOpen) {
      canvas.drawCircle(p(46, 58), 4 * sx, eye);
      canvas.drawCircle(p(74, 58), 4 * sx, eye);
    } else {
      final st = Paint()
        ..color = faceInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * sx
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(42 * sx, 58 * sy)
          ..quadraticBezierTo(46 * sx, 54 * sy, 50 * sx, 58 * sy),
        st,
      );
      canvas.drawPath(
        Path()
          ..moveTo(70 * sx, 58 * sy)
          ..quadraticBezierTo(74 * sx, 54 * sy, 78 * sx, 58 * sy),
        st,
      );
    }

    // 미소 M56 66 Q60 70 64 66
    final smile = Paint()
      ..color = faceInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(56 * sx, 66 * sy)
        ..quadraticBezierTo(60 * sx, 70 * sy, 64 * sx, 66 * sy),
      smile,
    );

    // 액세서리 — 안경은 눈 위, 목도리/가방은 목·몸통에.
    if (accKind != null) _paintAcc(canvas, sx, sy, accKind, bodyOval);

    // 모자 — 항상 맨 위.
    if (hatKind != null) _paintHat(canvas, sx, sy, hatKind);
  }

  // ---- 옷: 머리(몸통) 아래에 '옷 입은 작은 몸'을 만든다 ----
  // 블롭형 펫이라 목선을 얼굴 한참 아래(y≈80)에 두고, 몸통 밖으로 살짝 나오는
  // 어깨/소매 혹을 그려 '머리가 옷 입은 몸 위에 얹힌' 실루엣을 만든다(#5).
  void _paintClothes(Canvas c, double sx, double sy, _Cloth k, Rect bodyOval) {
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    late Color col, trim;
    switch (k) {
      case _Cloth.shirt:
        col = const Color(0xFF7FB2E3);
        trim = const Color(0xFF5E93C7);
      case _Cloth.hoodie:
        col = const Color(0xFF8FA36B);
        trim = const Color(0xFF6E824C);
      case _Cloth.dress:
        col = const Color(0xFFF098BE);
        trim = const Color(0xFFDB6F9C);
      case _Cloth.suit:
        col = const Color(0xFF3B4358);
        trim = const Color(0xFF2C3244);
      case _Cloth.space:
        col = const Color(0xFFEDEFF4);
        trim = const Color(0xFFB9C2D0);
    }
    const collar = 80.0; // 목선 — 얼굴(입 y70)을 가리지 않게 낮게.
    final body = Paint()..color = col;

    // 어깨/소매 — 몸통 밖으로 나오는 두 혹(클립 없이) → 옷 입은 몸통 실루엣.
    c.drawOval(
        Rect.fromCenter(center: p(21, 89), width: 24 * sx, height: 22 * sy),
        body);
    c.drawOval(
        Rect.fromCenter(center: p(99, 89), width: 24 * sx, height: 22 * sy),
        body);

    c.save();
    c.clipPath(Path()..addOval(bodyOval));
    // 몸통 하단을 감싸는 가먼트(목선은 가운데로 살짝 내려온 라운드넥).
    final g = Path()
      ..moveTo(10 * sx, collar * sy)
      ..quadraticBezierTo(60 * sx, (collar + 10) * sy, 110 * sx, collar * sy)
      ..lineTo(110 * sx, 104 * sy)
      ..lineTo(10 * sx, 104 * sy)
      ..close();
    c.drawPath(g, body);
    // 옷깃 라인
    c.drawPath(
      Path()
        ..moveTo(10 * sx, collar * sy)
        ..quadraticBezierTo(60 * sx, (collar + 10) * sy, 110 * sx, collar * sy),
      Paint()
        ..color = trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * sx
        ..strokeCap = StrokeCap.round,
    );

    switch (k) {
      case _Cloth.shirt:
        break; // 기본 티셔츠.
      case _Cloth.hoodie:
        // 지퍼 + 주머니 + 후드끈
        c.drawLine(p(60, collar + 3), p(60, 103),
            Paint()..color = trim..strokeWidth = 2.4 * sx);
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(50 * sx, 92 * sy, 20 * sx, 9 * sy),
              Radius.circular(3 * sx)),
          Paint()
            ..color = trim
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * sx,
        );
        c.drawCircle(p(56, collar + 5), 1.6 * sx, Paint()..color = trim);
        c.drawCircle(p(64, collar + 5), 1.6 * sx, Paint()..color = trim);
      case _Cloth.dress:
        // 허리선 + 밑단
        c.drawLine(p(20, 90), p(100, 90),
            Paint()..color = trim..strokeWidth = 2.5 * sx);
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(28 * sx, 100 * sy, 64 * sx, 4 * sy),
              Radius.circular(2 * sx)),
          Paint()..color = const Color(0xFFF8C2D8),
        );
      case _Cloth.suit:
        // 흰 셔츠 V + 넥타이 + 라펠
        c.drawPath(
          Path()
            ..moveTo(60 * sx, (collar + 1) * sy)
            ..lineTo(53 * sx, 103 * sy)
            ..lineTo(67 * sx, 103 * sy)
            ..close(),
          Paint()..color = Colors.white,
        );
        c.drawPath(
          Path()
            ..moveTo(60 * sx, (collar + 3) * sy)
            ..lineTo(57 * sx, 95 * sy)
            ..lineTo(60 * sx, 100 * sy)
            ..lineTo(63 * sx, 95 * sy)
            ..close(),
          Paint()..color = const Color(0xFFCC4E5C),
        );
        c.drawPath(
          Path()
            ..moveTo(60 * sx, (collar + 1) * sy)
            ..lineTo(46 * sx, (collar + 2) * sy)
            ..lineTo(57 * sx, 100 * sy)
            ..close(),
          Paint()..color = trim,
        );
        c.drawPath(
          Path()
            ..moveTo(60 * sx, (collar + 1) * sy)
            ..lineTo(74 * sx, (collar + 2) * sy)
            ..lineTo(63 * sx, 100 * sy)
            ..close(),
          Paint()..color = trim,
        );
      case _Cloth.space:
        // 가슴 컨트롤 패널
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: p(60, 94), width: 24 * sx, height: 11 * sy),
              Radius.circular(4 * sx)),
          Paint()..color = const Color(0xFFB9C2D0),
        );
        c.drawCircle(p(54, 94), 1.9 * sx, Paint()..color = const Color(0xFFE05A5A));
        c.drawCircle(p(60, 94), 1.9 * sx, Paint()..color = const Color(0xFF5AB06A));
        c.drawCircle(p(66, 94), 1.9 * sx, Paint()..color = const Color(0xFF5A7FE0));
    }
    c.restore();
  }

  // ---- 모자: 머리 위(y<26)에 얹는다 ----
  void _paintHat(Canvas c, double sx, double sy, _Hat k) {
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Paint fill(Color col) => Paint()..color = col;
    switch (k) {
      case _Hat.fedora:
        const col = Color(0xFF4A4550);
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(38 * sx, 18 * sy, 44 * sx, 7 * sy),
              Radius.circular(4 * sx)),
          fill(col),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(48 * sx, 3 * sy, 24 * sx, 17 * sy),
              Radius.circular(6 * sx)),
          fill(col),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(48 * sx, 15 * sy, 24 * sx, 4 * sy),
              Radius.circular(2 * sx)),
          fill(const Color(0xFF2E2A33)),
        );
      case _Hat.beanie:
        const col = Color(0xFF4FB0A0);
        c.drawPath(
          Path()
            ..moveTo(40 * sx, 25 * sy)
            ..quadraticBezierTo(60 * sx, -3 * sy, 80 * sx, 25 * sy)
            ..close(),
          fill(col),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(38 * sx, 21 * sy, 44 * sx, 7 * sy),
              Radius.circular(3 * sx)),
          fill(const Color(0xFF3E8F82)),
        );
        c.drawCircle(p(60, 1), 4 * sx, fill(Colors.white));
      case _Hat.straw:
        c.drawOval(
          Rect.fromCenter(center: p(60, 23), width: 68 * sx, height: 15 * sy),
          fill(const Color(0xFFE3C878)),
        );
        c.drawPath(
          Path()
            ..moveTo(44 * sx, 23 * sy)
            ..quadraticBezierTo(60 * sx, 1 * sy, 76 * sx, 23 * sy)
            ..close(),
          fill(const Color(0xFFEED89A)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(45 * sx, 17 * sy, 30 * sx, 5 * sy),
              Radius.circular(2 * sx)),
          fill(const Color(0xFFD98C7A)),
        );
      case _Hat.beret:
        c.drawOval(
          Rect.fromCenter(center: p(58, 15), width: 46 * sx, height: 22 * sy),
          fill(const Color(0xFFD1495B)),
        );
        c.drawCircle(p(58, 5), 3 * sx, fill(const Color(0xFF7BC47F)));
        final seed = fill(const Color(0xFFFFE08A));
        c.drawCircle(p(50, 15), 1.4 * sx, seed);
        c.drawCircle(p(60, 13), 1.4 * sx, seed);
        c.drawCircle(p(66, 17), 1.4 * sx, seed);
      case _Hat.ribbon:
        const col = Color(0xFFF07CA8);
        c.drawPath(
          Path()
            ..moveTo(60 * sx, 14 * sy)
            ..lineTo(44 * sx, 7 * sy)
            ..lineTo(44 * sx, 21 * sy)
            ..close(),
          fill(col),
        );
        c.drawPath(
          Path()
            ..moveTo(60 * sx, 14 * sy)
            ..lineTo(76 * sx, 7 * sy)
            ..lineTo(76 * sx, 21 * sy)
            ..close(),
          fill(col),
        );
        c.drawCircle(p(60, 14), 4 * sx, fill(const Color(0xFFE0678F)));
      case _Hat.sprout:
        final stem = Paint()
          ..color = const Color(0xFF6BBF6F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * sx
          ..strokeCap = StrokeCap.round;
        c.drawLine(p(60, 22), p(60, 9), stem);
        c.drawPath(
          Path()
            ..moveTo(60 * sx, 15 * sy)
            ..quadraticBezierTo(48 * sx, 7 * sy, 51 * sx, 17 * sy)
            ..close(),
          fill(const Color(0xFF7BC47F)),
        );
        c.drawPath(
          Path()
            ..moveTo(60 * sx, 13 * sy)
            ..quadraticBezierTo(72 * sx, 5 * sy, 69 * sx, 15 * sy)
            ..close(),
          fill(const Color(0xFF8FD093)),
        );
      case _Hat.crown:
        const col = Color(0xFFF2C94C);
        c.drawPath(
          Path()
            ..moveTo(42 * sx, 24 * sy)
            ..lineTo(46 * sx, 8 * sy)
            ..lineTo(54 * sx, 18 * sy)
            ..lineTo(60 * sx, 5 * sy)
            ..lineTo(66 * sx, 18 * sy)
            ..lineTo(74 * sx, 8 * sy)
            ..lineTo(78 * sx, 24 * sy)
            ..close(),
          fill(col),
        );
        final jewel = fill(const Color(0xFFE0567A));
        c.drawCircle(p(46, 9), 1.8 * sx, jewel);
        c.drawCircle(p(60, 7), 2 * sx, jewel);
        c.drawCircle(p(74, 9), 1.8 * sx, jewel);
    }
  }

  // ---- 액세서리 ----
  void _paintAcc(Canvas c, double sx, double sy, _Acc k, Rect bodyOval) {
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    switch (k) {
      case _Acc.glasses:
      case _Acc.sunglasses:
        final frame = Paint()
          ..color = const Color(0xFF3A3A42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * sx;
        final lens = k == _Acc.sunglasses
            ? (Paint()..color = const Color(0xCC2A2A33))
            : (Paint()..color = const Color(0x33FFFFFF));
        c.drawCircle(p(46, 58), 7 * sx, lens);
        c.drawCircle(p(74, 58), 7 * sx, lens);
        c.drawCircle(p(46, 58), 7 * sx, frame);
        c.drawCircle(p(74, 58), 7 * sx, frame);
        c.drawLine(p(53, 58), p(67, 58), frame);
      case _Acc.scarf:
        c.save();
        c.clipPath(Path()..addOval(bodyOval));
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(24 * sx, 72 * sy, 72 * sx, 12 * sy),
              Radius.circular(6 * sx)),
          Paint()..color = const Color(0xFFE0685E),
        );
        c.restore();
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(54 * sx, 80 * sy, 12 * sx, 20 * sy),
              Radius.circular(4 * sx)),
          Paint()..color = const Color(0xFFC9564D),
        );
      case _Acc.bag:
        c.save();
        c.clipPath(Path()..addOval(bodyOval));
        c.drawLine(
          p(40, 50),
          p(82, 92),
          Paint()
            ..color = const Color(0xFF8A6D4B)
            ..strokeWidth = 5 * sx,
        );
        c.restore();
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(84 * sx, 66 * sy, 15 * sx, 22 * sy),
              Radius.circular(5 * sx)),
          Paint()..color = const Color(0xFFB5895B),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) =>
      old.color != color ||
      old.hat != hat ||
      old.cheeks != cheeks ||
      old.eyesOpen != eyesOpen ||
      old.outfit != outfit;
}

// ============================================================ 방 장식 페인터

/// 배경 벽(#5) — 방 뒷벽 패널을 테마 색으로 그린다(둥둥 뜬 이모지 대신).
class _RoomBgPainter extends CustomPainter {
  const _RoomBgPainter(this.kind);
  final _Bg kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.9, h * 0.9),
      Radius.circular(w * 0.06),
    );
    canvas.save();
    canvas.clipRRect(panel);
    Paint fill(Color c) => Paint()..color = c;
    switch (kind) {
      case _Bg.mint:
        canvas.drawPaint(fill(const Color(0xFFCDEBD3)));
      case _Bg.flower:
        canvas.drawPaint(fill(const Color(0xFFF7D9E6)));
        final petal = fill(const Color(0xFFF3A9C6));
        for (final o in [
          Offset(w * 0.22, h * 0.28),
          Offset(w * 0.72, h * 0.22),
          Offset(w * 0.5, h * 0.52),
          Offset(w * 0.8, h * 0.6),
        ]) {
          for (var i = 0; i < 5; i++) {
            final a = i * 1.2566;
            canvas.drawCircle(
                o + Offset(w * 0.03 * math.cos(a), w * 0.03 * math.sin(a)),
                w * 0.022, petal);
          }
          canvas.drawCircle(o, w * 0.02, fill(const Color(0xFFFFE08A)));
        }
      case _Bg.night:
        canvas.drawPaint(fill(const Color(0xFF2E2E52)));
        final star = fill(Colors.white);
        for (final o in [
          Offset(w * 0.2, h * 0.25),
          Offset(w * 0.4, h * 0.15),
          Offset(w * 0.6, h * 0.3),
          Offset(w * 0.78, h * 0.2),
          Offset(w * 0.3, h * 0.45),
          Offset(w * 0.68, h * 0.5),
        ]) {
          canvas.drawCircle(o, w * 0.012, star);
        }
        // 초승달
        canvas.drawCircle(Offset(w * 0.76, h * 0.32), w * 0.07,
            fill(const Color(0xFFF3E7A8)));
        canvas.drawCircle(Offset(w * 0.8, h * 0.29), w * 0.07,
            fill(const Color(0xFF2E2E52)));
      case _Bg.beach:
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.62),
            fill(const Color(0xFFBFE6F0)));
        canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
            fill(const Color(0xFFEFE0B0)));
        canvas.drawCircle(Offset(w * 0.72, h * 0.24), w * 0.08,
            fill(const Color(0xFFFFD27A)));
      case _Bg.mountain:
        canvas.drawPaint(fill(const Color(0xFFDCEAF6)));
        final rock = fill(const Color(0xFFAFC0D4));
        final snow = fill(Colors.white);
        for (final b in [
          [w * 0.3, w * 0.22],
          [w * 0.62, w * 0.28],
        ]) {
          final cx = b[0], hw = b[1];
          final base = h * 0.66, peak = h * 0.2;
          canvas.drawPath(
            Path()
              ..moveTo(cx - hw, base)
              ..lineTo(cx, peak)
              ..lineTo(cx + hw, base)
              ..close(),
            rock,
          );
          canvas.drawPath(
            Path()
              ..moveTo(cx - hw * 0.28, peak + (base - peak) * 0.22)
              ..lineTo(cx, peak)
              ..lineTo(cx + hw * 0.28, peak + (base - peak) * 0.22)
              ..lineTo(cx + hw * 0.1, peak + (base - peak) * 0.3)
              ..lineTo(cx, peak + (base - peak) * 0.2)
              ..lineTo(cx - hw * 0.1, peak + (base - peak) * 0.3)
              ..close(),
            snow,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoomBgPainter old) => old.kind != kind;
}

/// 가구(#5) — 바닥 왼쪽에 놓이는 방 오브젝트. viewBox 40x50.
class _FurniturePainter extends CustomPainter {
  const _FurniturePainter(this.kind);
  final _Furn kind;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 40, sy = size.height / 50;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
    Paint fill(Color c) => Paint()..color = c;
    switch (kind) {
      case _Furn.plant:
        // 화분
        canvas.drawPath(
          Path()
            ..moveTo(12 * sx, 34 * sy)
            ..lineTo(28 * sx, 34 * sy)
            ..lineTo(25 * sx, 48 * sy)
            ..lineTo(15 * sx, 48 * sy)
            ..close(),
          fill(const Color(0xFFC98A5E)),
        );
        // 잎
        final leaf = fill(const Color(0xFF77BE79));
        canvas.drawOval(
            Rect.fromCenter(center: p(20, 22), width: 10 * sx, height: 22 * sy),
            leaf);
        canvas.drawOval(
            Rect.fromCenter(center: p(13, 26), width: 9 * sx, height: 18 * sy),
            fill(const Color(0xFF8CD08E)));
        canvas.drawOval(
            Rect.fromCenter(center: p(27, 26), width: 9 * sx, height: 18 * sy),
            fill(const Color(0xFF8CD08E)));
      case _Furn.rug:
        canvas.drawOval(
            Rect.fromCenter(center: p(20, 42), width: 38 * sx, height: 14 * sy),
            fill(const Color(0xFFB98A5C)));
        canvas.drawOval(
            Rect.fromCenter(center: p(20, 42), width: 26 * sx, height: 9 * sy),
            Paint()
              ..color = const Color(0xFFE7C79A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * sx);
      case _Furn.books:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(10, 40, 22, 8), Radius.circular(1.5 * sx)),
            fill(const Color(0xFFCC6B5A)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(12, 31, 18, 8), Radius.circular(1.5 * sx)),
            fill(const Color(0xFF6DA0C8)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(11, 22, 20, 8), Radius.circular(1.5 * sx)),
            fill(const Color(0xFF7FB98A)));
      case _Furn.sofa:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(4, 30, 32, 16), Radius.circular(5 * sx)),
            fill(const Color(0xFFB58ACB)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(7, 23, 26, 11), Radius.circular(5 * sx)),
            fill(const Color(0xFFC79EDA)));
      case _Furn.clock:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(13, 8, 14, 40), Radius.circular(3 * sx)),
            fill(const Color(0xFF9C6B45)));
        canvas.drawCircle(p(20, 18), 5 * sx, fill(Colors.white));
        canvas.drawLine(p(20, 18), p(20, 15),
            Paint()..color = const Color(0xFF3A2E2A)..strokeWidth = 1.2 * sx);
        canvas.drawCircle(p(20, 40), 2.5 * sx, fill(const Color(0xFFF2C94C)));
      case _Furn.fire:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(6, 24, 28, 22), Radius.circular(3 * sx)),
            fill(const Color(0xFF8A6D55)));
        canvas.drawRect(r(11, 30, 18, 16), fill(const Color(0xFF3A2E2A)));
        canvas.drawPath(
          Path()
            ..moveTo(20 * sx, 44 * sy)
            ..quadraticBezierTo(13 * sx, 38 * sy, 18 * sx, 33 * sy)
            ..quadraticBezierTo(19 * sx, 38 * sy, 22 * sx, 34 * sy)
            ..quadraticBezierTo(27 * sx, 39 * sy, 20 * sx, 44 * sy)
            ..close(),
          fill(const Color(0xFFF29B4B)),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _FurniturePainter old) => old.kind != kind;
}

/// 소품(#5) — 바닥 오른쪽 전경 오브젝트. viewBox 36x46.
class _PropPainter extends CustomPainter {
  const _PropPainter(this.kind);
  final _Prop kind;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 36, sy = size.height / 46;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);
    Paint fill(Color c) => Paint()..color = c;
    switch (kind) {
      case _Prop.balloon:
        canvas.drawLine(p(18, 24), p(20, 44),
            Paint()..color = const Color(0xFFB0A0A0)..strokeWidth = 1.2 * sx);
        canvas.drawOval(
            Rect.fromCenter(center: p(18, 14), width: 22 * sx, height: 26 * sy),
            fill(const Color(0xFFE06D82)));
        canvas.drawOval(
            Rect.fromCenter(
                center: p(14, 9), width: 6 * sx, height: 8 * sy),
            fill(Colors.white.withValues(alpha: .4)));
      case _Prop.cake:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(6, 30, 24, 12), Radius.circular(2 * sx)),
            fill(const Color(0xFFF7C9A0)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(8, 20, 20, 12), Radius.circular(2 * sx)),
            fill(const Color(0xFFFBE0EC)));
        canvas.drawCircle(p(18, 14), 3 * sx, fill(const Color(0xFFE0567A)));
      case _Prop.gift:
        canvas.drawRRect(
            RRect.fromRectAndRadius(r(6, 22, 24, 20), Radius.circular(2 * sx)),
            fill(const Color(0xFF7FB98A)));
        canvas.drawRect(r(16, 22, 4, 20), fill(const Color(0xFFF2C94C)));
        canvas.drawRect(r(6, 30, 24, 4), fill(const Color(0xFFF2C94C)));
        canvas.drawCircle(p(15, 20), 3 * sx, fill(const Color(0xFFF2C94C)));
        canvas.drawCircle(p(21, 20), 3 * sx, fill(const Color(0xFFF2C94C)));
      case _Prop.bouquet:
        final stem = Paint()
          ..color = const Color(0xFF6BBF6F)
          ..strokeWidth = 1.6 * sx;
        canvas.drawLine(p(18, 42), p(14, 26), stem);
        canvas.drawLine(p(18, 42), p(18, 24), stem);
        canvas.drawLine(p(18, 42), p(22, 26), stem);
        final f1 = fill(const Color(0xFFF29BB8));
        final f2 = fill(const Color(0xFFF2C94C));
        canvas.drawCircle(p(14, 24), 4 * sx, f1);
        canvas.drawCircle(p(18, 21), 4 * sx, f2);
        canvas.drawCircle(p(22, 24), 4 * sx, f1);
    }
  }

  @override
  bool shouldRepaint(covariant _PropPainter old) => old.kind != kind;
}

/// 탭바용 미니 펫 아이콘 (design 2a 네 번째 탭).
class PetTabIcon extends StatelessWidget {
  const PetTabIcon({super.key, this.color = muted, this.size = 23});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _PetTabPainter(color));
  }
}

class _PetTabPainter extends CustomPainter {
  const _PetTabPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final body = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(12 * s, 13.5 * s), width: 16 * s, height: 14 * s),
      body,
    );
    canvas.drawCircle(Offset(6.5 * s, 6 * s), 2.6 * s, body);
    canvas.drawCircle(Offset(17.5 * s, 6 * s), 2.6 * s, body);
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(9.3 * s, 13 * s), 1.1 * s, eye);
    canvas.drawCircle(Offset(14.7 * s, 13 * s), 1.1 * s, eye);
  }

  @override
  bool shouldRepaint(covariant _PetTabPainter old) => old.color != color;
}
