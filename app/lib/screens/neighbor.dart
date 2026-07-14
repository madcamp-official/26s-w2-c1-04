// 1h 이웃 집 방문 — 풀스크린 라일락 방 + 그룹 코드로 집 찾아가기.
// 디자인: Memory Pager 디자인.dc.html #1h (390x844).

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

class NeighborScreen extends StatefulWidget {
  const NeighborScreen({super.key});

  @override
  State<NeighborScreen> createState() => _NeighborScreenState();
}

class _NeighborScreenState extends State<NeighborScreen> {
  bool _showSearch = false;
  int _likes = 128;
  final _code = TextEditingController();

  // 실서버에서 매칭된 이웃(#15). null 이면 데모 방(별이네)을 보여준다.
  Map<String, dynamic>? _neighbor;
  // 방문 히스토리(#14) — < > 로 이전/다음 집 이동. 끝에서 > 면 새 랜덤 이웃.
  final List<Map<String, dynamic>> _history = [];
  int _idx = -1;
  // 이미 방문한 이웃(pet_id) — 같은 집이 다음 집으로 다시 나오는 것을 막는다(#3).
  final Set<String> _seen = {};
  // 더 놀러갈 새 집이 없음(#3) — > 버튼을 흐리게 비활성해 "넘어가는 척"을 막는다.
  bool _exhausted = false;
  bool _loadingNext = false;

  String _key(Map<String, dynamic> n) => '${n['pet_id'] ?? n['group_id'] ?? ''}';

  void _pushNeighbor(Map<String, dynamic> n) {
    setState(() {
      _neighbor = n;
      _likes = (n['likes'] as num?)?.toInt() ?? 0;
      _history.add(n);
      _idx = _history.length - 1;
      _seen.add(_key(n));
    });
  }

  void _goPrev() {
    if (_idx <= 0) return;
    setState(() {
      _idx--;
      _neighbor = _history[_idx];
      _likes = (_neighbor!['likes'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> _goNext() async {
    // 히스토리 안에서 앞으로 이동(이미 본 집).
    if (_idx < _history.length - 1) {
      setState(() {
        _idx++;
        _neighbor = _history[_idx];
        _likes = (_neighbor!['likes'] as num?)?.toInt() ?? 0;
      });
      return;
    }
    if (!mock.real) {
      _toast('데모에선 다음 집이 없어요');
      return;
    }
    if (_loadingNext || _exhausted) return;
    _loadingNext = true;
    try {
      // 서버 randomNeighbor 는 rand() 라 방문한 집이 또 나올 수 있다. 안 본 집을
      // 몇 번 시도해 찾고, 못 찾으면 더 없는 것으로 보고 > 를 비활성한다(#3).
      Map<String, dynamic>? fresh;
      for (var i = 0; i < 6; i++) {
        final n = await mock.api!.randomNeighbor();
        if (!mounted) return;
        if (n == null) break; // 공개된 다른 집이 아예 없음
        if (!_seen.contains(_key(n))) {
          fresh = n;
          break;
        }
      }
      if (!mounted) return;
      if (fresh == null) {
        setState(() => _exhausted = true); // 더 없음 → 버튼 흐리게
        _toast('더 놀러갈 집이 없어요');
        return;
      }
      _pushNeighbor(fresh);
    } catch (_) {
      if (mounted) _toast('다음 집을 불러오지 못했어요');
    } finally {
      _loadingNext = false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (mock.real) _loadNeighbor();
  }

  Future<void> _loadNeighbor() async {
    try {
      final n = await mock.api!.randomNeighbor();
      if (!mounted) return;
      if (n != null) {
        _pushNeighbor(n); // 히스토리에 넣어 < > 이동 가능(#14)
      }
    } catch (_) {
      // 실패해도 데모 방으로 보여준다(방문 자체가 부가 기능).
    }
  }

  bool get _isReal => _neighbor != null;
  int get _petLevel =>
      _isReal ? (_neighbor!['pet_level'] as num?)?.toInt() ?? 1 : 6;

  // 이웃마다 고정된 개성(색·모자·펫이름·커플이름)을 id 로 결정한다. 실제 그룹들이 전부
  // 기본 펫('모리')·같은 모습이라 "전부 똑같아" 보이던 것을 개선(#이웃1·2).
  _Persona get _persona => _personaFor(
        _isReal ? '${_neighbor!['pet_id'] ?? _neighbor!['group_name'] ?? ''}' : 'demo',
      );
  String get _petName => _persona.pet;
  String get _coupleName => _persona.couple;
  String get _subtitle {
    if (!_isReal) return 'D+89';
    final c = DateTime.tryParse('${_neighbor!['created_at']}');
    if (c == null) return '이웃 커플';
    final d = DateTime.now().toUtc().difference(c).inDays + 1;
    return 'D+$d';
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  // 코드로 특정 집 방문(#15). 실서버면 by-code 조회, 데모면 안내만.
  Future<void> _visit() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (!mock.real) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content:
              Text("'$code' 집은 데모에선 열리지 않아요", style: sans(13, c: Colors.white)),
        ));
      return;
    }
    try {
      final n = await mock.api!.neighborByCode(code);
      if (!mounted) return;
      if (n == null) {
        _toast('그런 집이 없어요');
        return;
      }
      _pushNeighbor(n); // 히스토리에 추가(#14)
      setState(() {
        _showSearch = false;
        _code.clear();
      });
    } catch (_) {
      if (mounted) _toast('그 집을 찾지 못했어요');
    }
  }

  Future<void> _like() async {
    if (_isReal) {
      final petId = '${_neighbor!['pet_id']}';
      setState(() => _likes += 1); // 낙관적
      try {
        final likes = await mock.api!.likeNeighbor(petId);
        if (mounted) setState(() => _likes = likes);
      } catch (_) {
        if (mounted) setState(() => _likes -= 1); // 되돌림
      }
    } else {
      setState(() => _likes += 1); // 데모
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: sans(13, c: Colors.white)),
      ));
  }

  // < > 다른 집 이동 버튼(#14). onTap 이 null 이면 흐리게 비활성.
  Widget _navButton({required bool forward, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .4 : 1,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF785AA0).withValues(alpha: 0.2),
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _ChevronPainter(color: lilacInk, forward: forward),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lilacBg,
      body: Stack(
        children: [
          // ---- 바닥
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: ColoredBox(color: Color(0xFFE3D5F7)),
          ),

          // ---- 창문 (top:190 left:42, 106x106 — 상태바 52 제외 좌표)
          const Positioned(
            top: 138,
            left: 42,
            child: CustomPaint(size: Size(106, 106), painter: _WindowPainter()),
          ),

          // ---- 플로어 램프 (right:38, 바닥 위)
          const Positioned(
            right: 38,
            bottom: 190,
            child: CustomPaint(size: Size(48, 106), painter: _LampPainter()),
          ),

          // ---- 러그
          Positioned(
            left: 0,
            right: 0,
            bottom: 158,
            child: Center(
              child: Container(
                width: 256,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C6F2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),

          // ---- 이웃 펫 — 이웃마다 색·모자를 달리해 서로 다른 커플로 보이게(#이웃1).
          Positioned(
            left: 0,
            right: 0,
            bottom: 184,
            child: Center(
              child: SizedBox(
                width: 172,
                height: 160,
                child: PetFace(
                  size: 172,
                  color: _persona.color,
                  faceInk: _persona.ink,
                  outfit: _persona.hat == null
                      ? null
                      : PetOutfit(hat: (emoji: _persona.hat, name: null)),
                ),
              ),
            ),
          ),

          // ---- 말풍선
          Positioned(
            left: 0,
            right: 0,
            bottom: 352,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '어서와, 우리 집은 처음이지?',
                  style: hand(18, c: lilacInk),
                ),
              ),
            ),
          ),

          // ---- 상단 바 + 검색 카드
          SafeArea(
            child: Stack(
              children: [
                // 뒤로가기
                Positioned(
                  top: 10,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.18),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(17, 17),
                          painter: _ChevronPainter(
                              color: lilacInk, forward: false),
                        ),
                      ),
                    ),
                  ),
                ),

                // 집 이름 필
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.12),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 상단엔 임의의 커플 이름(모리네 집 X) — 이웃마다 다르게(#이웃2).
                          Text(_coupleName,
                              style: sans(14, w: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Text(
                            _subtitle,
                            style: sans(12,
                                w: FontWeight.w700,
                                c: const Color(0xFF8A7A9B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 검색 버튼
                Positioned(
                  top: 10,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: lilac,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(17, 17),
                          painter: _SearchPainter(),
                        ),
                      ),
                    ),
                  ),
                ),

                // 그룹 코드 찾아가기 카드
                if (_showSearch)
                  Positioned(
                    top: 62,
                    right: 20,
                    child: Container(
                      width: 224,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.22),
                            offset: const Offset(0, 10),
                            blurRadius: 26,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '그룹 코드로 집 찾아가기',
                            style:
                                sans(12, w: FontWeight.w800, c: lilacInk),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F0FA),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: TextField(
                                    controller: _code,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    textInputAction: TextInputAction.go,
                                    onSubmitted: (_) => _visit(),
                                    style: sans(13, ls: 2, c: lilacInk),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      border: InputBorder.none,
                                      hintText: '코드 입력',
                                      hintStyle: sans(13,
                                          ls: 2,
                                          c: const Color(0xFFB0A3C2)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _visit,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: lilac,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Center(
                                    child: CustomPaint(
                                      size: Size(15, 15),
                                      painter: _ChevronPainter(
                                          color: Colors.white, forward: true),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- 하단: 펫 이름 + 레벨
          Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_petName, style: sans(17, w: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: lilac,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Lv.$_petLevel',
                    style: sans(12, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ---- 하단: < 좋아요 > (좋아요 양옆으로 다른 집 이동 #14)
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navButton(forward: false, onTap: _idx > 0 ? _goPrev : null),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _like,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF785AA0).withValues(alpha: 0.2),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('♥', style: sans(18, c: coral)),
                          const SizedBox(width: 8),
                          Text('$_likes',
                              style: sans(15, w: FontWeight.w800, c: coral)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 히스토리 끝 + 더 없음이면 흐리게 비활성 — "넘어가는 척" 방지(#3).
                  _navButton(
                    forward: true,
                    onTap: (_exhausted && _idx >= _history.length - 1)
                        ? null
                        : _goNext,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 이웃 개성(#이웃1·2) — id 로 고정 선택해, 같은 이웃은 늘 같은 모습·이름, 다른 이웃은 다르게.
class _Persona {
  const _Persona(this.color, this.ink, this.pet, this.couple, this.hat);
  final Color color;
  final Color ink;
  final String pet; // 하단 펫 이름
  final String couple; // 상단 커플 이름
  final String? hat; // 착용 모자 이모지(없으면 null)
}

const List<_Persona> _personas = [
  _Persona(Color(0xFFB49BE0), Color(0xFF2E2440), '몽실', '달래 ♥ 보리', '🎀'),
  _Persona(Color(0xFFF3A6B8), Color(0xFF5A2A38), '초코', '토리 ♥ 마루', null),
  _Persona(Color(0xFFF6C270), Color(0xFF5A4020), '단추', '코코 ♥ 별이', '👑'),
  _Persona(Color(0xFF8FD0C0), Color(0xFF20463E), '두부', '하루 ♥ 나나', '🌱'),
  _Persona(Color(0xFF9FC0F0), Color(0xFF223A5A), '방울', '밤이 ♥ 솔이', '🧢'),
  _Persona(Color(0xFFC0D890), Color(0xFF3A4620), '감자', '유자 ♥ 미소', null),
  _Persona(Color(0xFFE0A0D0), Color(0xFF4A2044), '젤리', '앵두 ♥ 자두', '👒'),
  _Persona(Color(0xFFF0A98C), Color(0xFF5A3020), '마요', '노을 ♥ 바다', null),
];

_Persona _personaFor(String key) {
  final k = key.isEmpty ? 'demo' : key;
  return _personas[k.hashCode.abs() % _personas.length];
}

// ---------------------------------------------------------------- painters

/// 창문 — viewBox 0 0 60 60: 흰 라운드 프레임 + 라일락 십자.
class _WindowPainter extends CustomPainter {
  const _WindowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    const frame = Color(0xFFC9B8E8);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * s, 3 * s, 54 * s, 54 * s),
      Radius.circular(10 * s),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFDFBFF));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * s,
    );

    final cross = Paint()
      ..color = frame
      ..strokeWidth = 4 * s;
    canvas.drawLine(Offset(30 * s, 8 * s), Offset(30 * s, 52 * s), cross);
    canvas.drawLine(Offset(8 * s, 30 * s), Offset(52 * s, 30 * s), cross);
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) => false;
}

/// 플로어 램프 — viewBox 0 0 40 90: 라일락 갓 + 회보라 기둥·받침.
class _LampPainter extends CustomPainter {
  const _LampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 40, sy = size.height / 90;
    const pole = Color(0xFF8A7A9B);

    // 갓 M8 24 L32 24 L26 4 L14 4 Z
    final shade = Path()
      ..moveTo(8 * sx, 24 * sy)
      ..lineTo(32 * sx, 24 * sy)
      ..lineTo(26 * sx, 4 * sy)
      ..lineTo(14 * sx, 4 * sy)
      ..close();
    canvas.drawPath(shade, Paint()..color = lilac);

    // 기둥
    canvas.drawLine(
      Offset(20 * sx, 24 * sy),
      Offset(20 * sx, 78 * sy),
      Paint()
        ..color = pole
        ..strokeWidth = 4 * sx,
    );

    // 받침
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(20 * sx, 82 * sy),
          width: 24 * sx,
          height: 10 * sy),
      Paint()..color = pole,
    );
  }

  @override
  bool shouldRepaint(covariant _LampPainter old) => false;
}

/// 좌/우 셰브론 — stroke 2.5, round cap/join.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color, required this.forward});

  final Color color;
  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = forward
        ? (Path()
          ..moveTo(10 * s, 6 * s)
          ..lineTo(16 * s, 12 * s)
          ..lineTo(10 * s, 18 * s))
        : (Path()
          ..moveTo(14 * s, 6 * s)
          ..lineTo(8 * s, 12 * s)
          ..lineTo(14 * s, 18 * s));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) =>
      old.color != color || old.forward != forward;
}

/// 돋보기 — 흰 stroke 2.5.
class _SearchPainter extends CustomPainter {
  const _SearchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(10 * s, 10 * s), 6 * s, paint);
    canvas.drawLine(Offset(15 * s, 15 * s), Offset(20 * s, 20 * s), paint);
  }

  @override
  bool shouldRepaint(covariant _SearchPainter old) => false;
}
