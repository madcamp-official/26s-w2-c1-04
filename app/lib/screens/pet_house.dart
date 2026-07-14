// 1g — 집 관리 탭 · 펫 꾸미기/스토어. "모리네 집".
// 디자인: Memory Pager 디자인.dc.html #1g (lines 885-937) 실측값 그대로.

import 'dart:async';

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';
import '../widgets/pressable.dart';
import 'diary.dart';
import 'house_full.dart';
import 'neighbor.dart';

class PetHouseScreen extends StatefulWidget {
  const PetHouseScreen({super.key});

  @override
  State<PetHouseScreen> createState() => _PetHouseScreenState();
}

class _PetHouseScreenState extends State<PetHouseScreen> {
  static const _cats = ['모자', '옷', '가구', '배경', '소품'];
  String _cat = '모자';

  // 펫 말풍선(#11) — 평소 숨김, 탭하면 3초간 노출.
  bool _bubble = false;
  Timer? _bubbleTimer;

  void _showBubble() {
    setState(() => _bubble = true);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = false);
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  String _comma(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperCard,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _header(context),
                      _categoryChips(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          children: [
                            _itemGrid(),
                            _infoStrip(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _bottomRow(context),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: mock.roomColor,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${mock.petName}네 집',
                      style: sans(20, w: FontWeight.w800)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 일기장 버튼 — 코인 옆에 둔다(#14).
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DiaryScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('📖', style: sans(13)),
                              const SizedBox(width: 5),
                              Text('일기장',
                                  style: sans(13, w: FontWeight.w800, c: brown)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: goldCoin,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFE09E00), width: 2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(_comma(mock.coins),
                                style: sans(14, w: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _stage(context),
          ],
        ),
      ),
    );
  }

  // 센터 스테이지 — 집 + 모리 + 말풍선 + 일기장 진입 버튼.
  Widget _stage(BuildContext context) {
    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 6,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 집 (margin-right:-16 겹침 → 좌우 8px 씩 안쪽으로 당김)
                  Transform.translate(
                    offset: const Offset(8, 0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: CustomPaint(
                        size: const Size(108, 98),
                        painter: _HousePainter(),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: SizedBox(
                      width: 132,
                      height: 132,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 그림자 타원
                          Positioned(
                            bottom: 2,
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: ink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          // 착용 아이템까지 그린 펫(#12). 탭하면 말풍선을 잠깐 띄운다(#11).
                          Center(
                            child: GestureDetector(
                              onTap: _showBubble,
                              behavior: HitTestBehavior.opaque,
                              child: const DecoratedPet(size: 132),
                            ),
                          ),
                          // 말풍선(#11) — 평소엔 숨겨 모자·소품을 가리지 않고,
                          // 펫을 탭하면 3초간 보였다 사라진다.
                          if (_bubble)
                            Positioned(
                              top: 0,
                              right: -14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child:
                                    Text('헤헤!', style: hand(15, c: inkSoft)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 확대(전체화면) 버튼 — 우리 집 전체 모습을 풀스크린으로 본다(#13).
          Positioned(
            right: 18,
            bottom: 6,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseFullscreenScreen()),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(13, 13),
                  painter: _ExpandPainter(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- chips
  Widget _categoryChips() {
    Widget chip(String label) {
      final active = _cat == label;
      return GestureDetector(
        onTap: () => setState(() => _cat = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active ? ink : chipBg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: sans(
              13,
              w: active ? FontWeight.w700 : FontWeight.w600,
              c: active ? Colors.white : brown,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          for (int i = 0; i < _cats.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chip(_cats[i]),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- grid
  Widget _itemGrid() {
    Widget statusLine(StoreItem item) {
      if (item.wearing) {
        return Text('착용 중', style: sans(11.5, w: FontWeight.w800, c: coral));
      }
      if (item.owned) {
        return Text('보유', style: sans(11.5, w: FontWeight.w800, c: muted));
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: goldCoin, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('${item.price}',
              style: sans(11.5, w: FontWeight.w800, c: brown)),
        ],
      );
    }

    Widget card(StoreItem item) => Expanded(
          child: GestureDetector(
            onTap: () => _onItemTap(item),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: item.wearing ? coral : line,
                  width: item.wearing ? 2 : 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: item.owned ? 1 : 0.75,
                    child: SizedBox(
                      height: 26,
                      child: Center(
                        child: item.emoji != null
                            ? Text(item.emoji!, style: sans(22))
                            : CustomPaint(
                                size: const Size(44, 24.2),
                                painter: _HatGlyphPainter(item.name),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: sans(12, w: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(height: 16, child: statusLine(item)),
                ],
              ),
            ),
          ),
        );


    final items = mock.itemsForCategory(_cat);
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Text('$_cat 아이템은 곧 추가돼요',
            style: sans(13, w: FontWeight.w700, c: muted)),
      );
    }
    // 3열 그리드 — 개수에 맞춰 줄을 나눈다. 마지막 줄은 빈 칸으로 채워 정렬 유지.
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final chunk = items.sublist(i, (i + 3).clamp(0, items.length));
      final padded = <StoreItem?>[...chunk];
      while (padded.length < 3) {
        padded.add(null);
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var k = 0; k < padded.length; k++) ...[
            if (k > 0) const SizedBox(width: 10),
            padded[k] == null
                ? const Expanded(child: SizedBox())
                : card(padded[k]!),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }

  void _onSave() {
    final worn = mock
        .itemsForCategory('모자')
        .where((h) => h.wearing)
        .map((h) => h.name)
        .toList();
    final msg = worn.isEmpty ? '기본 모습으로 저장했어요' : '${worn.first} 착용을 저장했어요';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: sans(13, c: Colors.white)),
      ));
  }

  // 코인 게이팅: 미보유면 구매(코인 부족 시 안내), 보유면 착용/해제.
  Future<void> _onItemTap(StoreItem item) async {
    final err = await mock.buyOrWear(item);
    if (err != null && mounted) _showTopToast(err);
  }

  // 화면 '상단'에 잠깐 떴다 사라지는 토스트. 하단 스낵바는 탭바를 가려 다른 탭으로
  // 넘어가기 불편했다(코인 부족 안내가 대표적). 상단 배너로 올린다.
  void _showTopToast(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 20,
        right: 20,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙', style: sans(15)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style:
                          sans(13.5, w: FontWeight.w700, c: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1900), remove);
  }

  // ---------------------------------------------------------------- info
  Widget _infoStrip() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(20, 20),
            painter: _ScribblePainter(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: sans(12.5, c: brown, h: 1.5),
                children: [
                  TextSpan(
                      text: '${mock.petName}는 두 사람의 낙서 그림체를 배우는 중!\n'),
                  TextSpan(
                    text: '가끔 직접 그린 낙서를 선물해요',
                    style: sans(12.5, c: coral, w: FontWeight.w700, h: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- bottom
  Widget _bottomRow(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
        child: Row(
          children: [
            Expanded(
              child: Pressable(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NeighborScreen()),
                ),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: myPinkBg, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(16, 16),
                        painter: _HomeIconPainter(),
                      ),
                      const SizedBox(width: 8),
                      Text('이웃 집 놀러가기',
                          style: sans(14, w: FontWeight.w800, c: coral)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: _onSave,
              child: Container(
                width: 120,
                height: 52,
                decoration: BoxDecoration(
                  color: coral,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: coral.withValues(alpha: 0.3),
                      offset: const Offset(0, 6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text('저장하기',
                      style: sans(14, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ painters

/// 집 — viewBox 0 0 110 100: 지붕 삼각 + 흰 몸체 r6 + 문 + 동그란 창.
class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 110, sy = size.height / 100;

    canvas.drawPath(
      Path()
        ..moveTo(8 * sx, 42 * sy)
        ..lineTo(55 * sx, 8 * sy)
        ..lineTo(102 * sx, 42 * sy)
        ..close(),
      Paint()..color = dashPeach,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * sx, 40 * sy, 74 * sx, 50 * sy),
        Radius.circular(6 * sx),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(46 * sx, 58 * sy, 18 * sx, 32 * sy),
        Radius.circular(4 * sx),
      ),
      Paint()..color = myPinkBg,
    );
    canvas.drawCircle(
        Offset(76 * sx, 60 * sy), 8 * sx, Paint()..color = blush);
    canvas.drawCircle(
      Offset(76 * sx, 60 * sy),
      8 * sx,
      Paint()
        ..color = dashPeach
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * sx,
    );
  }

  @override
  bool shouldRepaint(covariant _HousePainter oldDelegate) => false;
}

/// 확대 화살표 — viewBox 24, coral 2.2 stroke.
class _ExpandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(14 * s, 4 * s)
        ..lineTo(20 * s, 4 * s)
        ..lineTo(20 * s, 10 * s),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10 * s, 20 * s)
        ..lineTo(4 * s, 20 * s)
        ..lineTo(4 * s, 14 * s),
      p,
    );
    canvas.drawLine(Offset(20 * s, 4 * s), Offset(14 * s, 10 * s), p);
    canvas.drawLine(Offset(4 * s, 20 * s), Offset(10 * s, 14 * s), p);
  }

  @override
  bool shouldRepaint(covariant _ExpandPainter oldDelegate) => false;
}

/// 낙서 곡선 — M4 17 Q8 8 12 13 T20 7, coral 2.5 stroke.
class _ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.drawPath(
      Path()
        ..moveTo(4 * s, 17 * s)
        ..quadraticBezierTo(8 * s, 8 * s, 12 * s, 13 * s)
        ..quadraticBezierTo(16 * s, 18 * s, 20 * s, 7 * s),
      Paint()
        ..color = coral
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScribblePainter oldDelegate) => false;
}

/// 집 아이콘 — 이웃 집 놀러가기 버튼용, coral 2 stroke.
class _HomeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(4 * s, 11 * s)
        ..lineTo(12 * s, 4 * s)
        ..lineTo(20 * s, 11 * s),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(6 * s, 10 * s)
        ..lineTo(6 * s, 19 * s)
        ..lineTo(18 * s, 19 * s)
        ..lineTo(18 * s, 10 * s),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeIconPainter oldDelegate) => false;
}

/// 아이템 글리프 — viewBox 0 0 40 22, 디자인 SVG를 이름별로 그대로 옮김.
class _HatGlyphPainter extends CustomPainter {
  const _HatGlyphPainter(this.name);

  final String name;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;

    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x * s, y * s, w * s, h * s), Radius.circular(r * s));

    switch (name) {
      case '중절모':
        final p = Paint()..color = ink;
        canvas.drawRRect(rr(4, 12, 32, 8, 4), p);
        canvas.drawRRect(rr(11, 2, 18, 12, 5), p);
      case '밀짚모자':
        final p = Paint()..color = goldCoin;
        canvas.drawRRect(rr(4, 12, 32, 8, 4), p);
        canvas.drawCircle(Offset(20 * s, 8 * s), 7 * s, p);
      case '딸기베레모':
        canvas.drawRRect(rr(8, 10, 24, 10, 5), Paint()..color = coral);
        canvas.drawCircle(
            Offset(20 * s, 8 * s), 5 * s, Paint()..color = salmon);
      case '비니':
        canvas.drawRRect(rr(6, 6, 28, 12, 6), Paint()..color = partnerBlue);
      case '새싹핀':
        canvas.drawCircle(Offset(20 * s, 14 * s), 8 * s,
            Paint()..color = const Color(0xFF41B979));
        canvas.drawRRect(
            rr(17, 2, 6, 8, 3), Paint()..color = const Color(0xFF2E8A58));
      case '리본':
        final wing = Paint()..color = salmon;
        canvas.drawPath(
          Path()
            ..moveTo(16 * s, 11 * s)
            ..lineTo(6 * s, 4 * s)
            ..lineTo(6 * s, 18 * s)
            ..close(),
          wing,
        );
        canvas.drawPath(
          Path()
            ..moveTo(24 * s, 11 * s)
            ..lineTo(34 * s, 4 * s)
            ..lineTo(34 * s, 18 * s)
            ..close(),
          wing,
        );
        canvas.drawCircle(
            Offset(20 * s, 11 * s), 4 * s, Paint()..color = coral);
      default:
        canvas.drawRRect(rr(6, 6, 28, 12, 6), Paint()..color = muted);
    }
  }

  @override
  bool shouldRepaint(covariant _HatGlyphPainter oldDelegate) =>
      oldDelegate.name != name;
}
