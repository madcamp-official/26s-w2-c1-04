// 앱 셸 — 하단 탭 4개 (design 2a: 아이콘 온리 + 활성 탭 블러시 필).
// 탭: 홈 · 낙서(캔버스 push) · 사진첩 · 펫. 86h, 흰 배경, 상단 헤어라인.

import 'package:flutter/material.dart';

import 'mock.dart';
import 'pet.dart';
import 'screens/album.dart';
import 'screens/draw_canvas.dart';
import 'screens/home.dart';
import 'screens/pet_house.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0; // 0 홈 · 1 사진첩 · 2 펫 (낙서는 push)

  void _openCanvas() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DrawCanvasScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mock,
      builder: (context, _) => Scaffold(
        backgroundColor: paperCard,
        body: IndexedStack(
          index: _tab,
          children: const [HomeScreen(), AlbumScreen(), PetHouseScreen()],
        ),
        bottomNavigationBar: Container(
          height: 86,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                active: _tab == 0,
                icon: _HomeIcon(color: _tab == 0 ? coral : muted),
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                active: false,
                icon: const _ScribbleIcon(color: muted),
                onTap: _openCanvas,
              ),
              _NavItem(
                active: _tab == 1,
                icon: Icon(Icons.photo_outlined,
                    size: 23, color: _tab == 1 ? coral : muted),
                onTap: () => setState(() => _tab = 1),
              ),
              _NavItem(
                active: _tab == 2,
                icon: PetTabIcon(color: _tab == 2 ? coral : muted),
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.active, required this.icon, required this.onTap});

  final bool active;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 58,
        height: 42,
        decoration: BoxDecoration(
          color: active ? blush : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

/// 집 아이콘 (design line SVG: 지붕 + 몸체).
class _HomeIcon extends StatelessWidget {
  const _HomeIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(23, 23), painter: _HomePainter(color));
  }
}

class _HomePainter extends CustomPainter {
  const _HomePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
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
  bool shouldRepaint(covariant _HomePainter old) => old.color != color;
}

/// 낙서 스트로크 아이콘 (design: M4 17 Q8 8 12 13 T20 7).
class _ScribbleIcon extends StatelessWidget {
  const _ScribbleIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: const Size(23, 23), painter: _ScribblePainter(color));
  }
}

class _ScribblePainter extends CustomPainter {
  const _ScribblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    // M4 17 Q8 8 12 13 T20 7  (T = 대칭 제어점)
    canvas.drawPath(
      Path()
        ..moveTo(4 * s, 17 * s)
        ..quadraticBezierTo(8 * s, 8 * s, 12 * s, 13 * s)
        ..quadraticBezierTo(16 * s, 18 * s, 20 * s, 7 * s),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ScribblePainter old) => old.color != color;
}
