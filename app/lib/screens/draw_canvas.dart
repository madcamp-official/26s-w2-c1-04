// 낙서 캔버스 — 디자인 1d(낙서하기 · 풀스크린 캔버스 + 컬러피커)
// + 4c(답장 보내기 · 1d와 동일한 캔버스, paperReply 바탕) 변형.
// 실제 프리핸드 드로잉: 스트로크(색·굵기·포인트) 기록 → CustomPainter로 라운드캡 페인팅.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

const double _pi = 3.1415926535897932;

enum _Tool { pen, eraser, highlighter }

class _Stroke {
  _Stroke({required this.color, required this.width, required this.tool});

  final Color color;
  final double width;
  final _Tool tool;
  final List<Offset> points = [];
}

class DrawCanvasScreen extends StatefulWidget {
  const DrawCanvasScreen({super.key, this.replyTo});

  /// null 이면 1d 새 낙서, 아니면 4c 답장 모드.
  final Doodle? replyTo;

  @override
  State<DrawCanvasScreen> createState() => _DrawCanvasScreenState();
}

class _DrawCanvasScreenState extends State<DrawCanvasScreen> {
  // 사진 배경은 사용자가 실제로 고른 사진이 있을 때만 표시한다(표시-전송 일치).
  // 예전엔 새 낙서가 샘플 사진을 깔았지만 전송 PNG엔 안 들어가 불일치를 냈다.
  bool _hasPhoto = false;
  Uint8List? _photoBytes; // 카메라/갤러리에서 고른 실제 사진(표시용)
  ui.Image? _photoImage; // 래스터 합성용 디코드 이미지
  bool _vanish = false;
  bool _showTools = false; // 펜 도구 패널(색·굵기) 표시 여부 — 펜 버튼으로 토글, 그리면 닫힘
  _Tool _tool = _Tool.pen;
  Color _color = coralHot;
  int _wheelIdx = 0;
  double _sizeT = .55; // 디자인 슬라이더 thumb left:55%
  final List<_Stroke> _strokes = [];

  static const List<Color> _wheel = [
    coralHot,
    goldCoin,
    Color(0xFF41B979),
    partnerBlue,
    lilac,
  ];

  bool get _isReply => widget.replyTo != null;

  /// 컨트롤 톤 — 사진 위(또는 잉크 바탕)는 다크, 답장 종이 바탕은 라이트.
  bool get _dark => _hasPhoto || !_isReply;

  double get _penWidth => 2 + _sizeT * 10;

  double get _strokeWidth => switch (_tool) {
        _Tool.pen => _penWidth,
        _Tool.eraser => _penWidth * 2.2,
        _Tool.highlighter => _penWidth * 2.4,
      };

  void _startStroke(Offset at) {
    setState(() {
      _showTools = false; // 캔버스를 그리기 시작하면 도구 팝업을 닫는다
      _strokes.add(
        _Stroke(color: _color, width: _strokeWidth, tool: _tool)..points.add(at),
      );
    });
  }

  void _extendStroke(Offset at) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.points.add(at));
  }

  bool _sending = false;

  // 카메라/갤러리에서 사진을 골라 캔버스 배경으로 넣는다.
  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: coral),
              title: Text('카메라로 촬영', style: sans(15, w: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: coral),
              title: Text('갤러리에서 선택', style: sans(15, w: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_photoBytes != null)
              ListTile(
                leading: const Icon(Icons.close_rounded, color: muted),
                title: Text('사진 제거', style: sans(15, w: FontWeight.w700, c: muted)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return; // 시트 그냥 닫음
    if (choice == 'remove') {
      setState(() {
        _photoBytes = null;
        _photoImage = null;
        _hasPhoto = false;
      });
      return;
    }
    try {
      final source =
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final picked =
          await ImagePicker().pickImage(source: source, maxWidth: 1600);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoImage = decoded;
        _hasPhoto = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진을 불러오지 못했어요', style: sans(13))),
        );
      }
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    if (mock.real) {
      setState(() => _sending = true);
      final size = MediaQuery.of(context).size;
      try {
        final png = await _rasterStrokes(size);
        await mock.sendDrawing(png, _strokeJson(size),
            ephemeral: _vanish, parentId: widget.replyTo?.id);
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        // 실패 시 화면을 닫지 않고 알린다(가짜 성공 방지).
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('전송에 실패했어요. 다시 시도해 주세요', style: sans(13))),
          );
        }
      }
      return;
    }
    // 데모
    mock.doodles.insert(
      0,
      Doodle(
        id: 'me-${DateTime.now().millisecondsSinceEpoch}',
        fromMe: true,
        type: DoodleType.drawing,
        text: '내 낙서',
        when: '방금 전',
        ephemeral: _vanish,
      ),
    );
    mock.refresh();
    Navigator.of(context).pop();
  }

  String _hex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  String _strokeJson(Size size) => jsonEncode({
        'canvas': {'w': size.width.round(), 'h': size.height.round()},
        'duration_ms': 1000,
        'strokes': [
          for (final s in _strokes)
            {
              'pen': s.tool.name,
              'color': _hex(s.color),
              'width': s.width.round().clamp(1, 40),
              'points': [
                for (final p in s.points) [p.dx.round(), p.dy.round(), 0]
              ],
            }
        ],
      });

  Future<List<int>> _rasterStrokes(Size size) async {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final w = size.width.toInt().clamp(1, 2000);
    final h = size.height.toInt().clamp(1, 2000);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = Colors.white);
    // 배경 사진을 먼저 깔아 전송 PNG 에 포함시킨다(cover fit).
    if (_photoImage != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        image: _photoImage!,
        fit: BoxFit.cover,
      );
    }
    for (final s in _strokes) {
      final paint = Paint()
        ..color = s.tool == _Tool.eraser ? Colors.white : s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.points, paint);
      } else {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final p in s.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
    final img = await rec.endRecording().toImage(w, h);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isReply && !_hasPhoto ? paperReply : ink,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ---- 사진 배경 + 상/하 그라데이션 (1d)
              if (_hasPhoto) ...[
                Positioned.fill(
                  child: _photoBytes != null
                      ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                      : Image.asset(
                          'assets/photos/photo_field.png',
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 130,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [overlay(.5), overlay(0)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 150,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [overlay(0), overlay(.55)],
                      ),
                    ),
                  ),
                ),
              ],

              // ---- 프리핸드 드로잉 레이어
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _startStroke(d.localPosition),
                  onPanUpdate: (d) => _extendStroke(d.localPosition),
                  child: CustomPaint(painter: _DoodlePainter(_strokes)),
                ),
              ),

              // ---- 컨트롤 오버레이
              SafeArea(
                child: Stack(
                  children: [
                    // 뒤로가기 (design top:64 = 상태바 52 + 12)
                    Positioned(top: 12, left: 20, child: _backButton(context)),

                    // 답장 모드 상단 필
                    if (_isReply)
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFA05A50)
                                      .withValues(alpha: .12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '${mock.partnerNick}에게 답장',
                              style: sans(13.5, w: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),

                    // 우상단: 펜 버튼 + 휘발 토글
                    Positioned(
                      top: 12,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            // 펜 버튼: 도구 패널(색·굵기)을 토글한다. 다시 누르면 닫힌다.
                            onTap: () => setState(() {
                              _tool = _Tool.pen;
                              _showTools = !_showTools;
                            }),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: coralHot, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _dark
                                        ? Colors.black.withValues(alpha: .25)
                                        : const Color(0xFFA05A50)
                                            .withValues(alpha: .2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const CustomPaint(
                                size: Size(19, 19),
                                painter: _PenIconPainter(coralHot),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => setState(() => _vanish = !_vanish),
                            child: _vanishToggle(),
                          ),
                          // 텍스트(T) 보내기 버튼 제거 — 낙서는 손그림으로 통일.
                        ],
                      ),
                    ),

                    // 휘발 ON 힌트 (design top:131 = 52+79, right:70)
                    if (_vanish)
                      Positioned(
                        top: 79,
                        right: 70,
                        child: Text(
                          '확인 후 5초 뒤 사라져요 · 레포트에 남지 않아요',
                          textAlign: TextAlign.right,
                          style: sans(
                            11.5,
                            w: FontWeight.w600,
                            c: _dark
                                ? Colors.white.withValues(alpha: .9)
                                : brown,
                          ).copyWith(
                            shadows: _dark
                                ? [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color:
                                          Colors.black.withValues(alpha: .4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),

                    // 도구 패널(색·굵기) — 펜 버튼을 눌렀을 때만 뜨는 팝업.
                    // 펜 버튼을 다시 누르거나 캔버스를 그리면 닫힌다.
                    if (_showTools)
                      Positioned(top: 190, right: 20, child: _toolPanel()),

                    // 답장 모드 — 받은 낙서 썸네일 카드
                    if (_isReply)
                      Positioned(
                        bottom: 104,
                        left: 20,
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA05A50)
                                    .withValues(alpha: .18),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: SizedBox(
                                  height: 76,
                                  width: double.infinity,
                                  child: Image.asset(
                                    widget.replyTo!.asset ??
                                        'assets/photos/photo_field.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  '받은 낙서 보기',
                                  textAlign: TextAlign.center,
                                  style: sans(11, w: FontWeight.w700, c: brown),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 좌하단: 사진 첨부 토글
                    Positioned(
                      bottom: 34,
                      left: 20,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: _photoButton(),
                      ),
                    ),

                    // 우하단: 보내기 필
                    Positioned(bottom: 32, right: 20, child: _sendPill()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------ 컨트롤 조각들

  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _dark ? overlay(.45) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: _dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFA05A50).withValues(alpha: .15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(18, 18),
          painter: _ChevronPainter(_dark ? Colors.white : brown),
        ),
      ),
    );
  }

  Widget _vanishToggle() {
    if (_vanish) {
      // ON — 흰 원 + 점선 잉크 원 안의 '5'
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: const _DashedCirclePainter(ink),
            child: Center(
              child: Text('5', style: sans(11, w: FontWeight.w800, c: ink)),
            ),
          ),
        ),
      );
    }
    // OFF — ∞ (다크: 오버레이 원 + 흰 테두리, 라이트: 흰 원 + 브라운 테두리)
    final Color fg = _dark ? Colors.white : brown;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _dark ? overlay(.45) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: _dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFA05A50).withValues(alpha: .15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: fg, width: 2),
        ),
        alignment: Alignment.center,
        child: Text('∞', style: sans(11, w: FontWeight.w800, c: fg, h: 1)),
      ),
    );
  }

  Widget _toolPanel() {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _dark ? Colors.white.withValues(alpha: .97) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _dark
                ? Colors.black.withValues(alpha: .25)
                : const Color(0xFFA05A50).withValues(alpha: .22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 도구 3개
          Row(
            children: [
              _toolButton(_Tool.pen),
              const SizedBox(width: 6),
              _toolButton(_Tool.eraser),
              const SizedBox(width: 6),
              _toolButton(_Tool.highlighter),
            ],
          ),
          const SizedBox(height: 11),
          // 컬러피커 링 + 퀵 스와치
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _wheelIdx = (_wheelIdx + 1) % _wheel.length;
                  _color = _wheel[_wheelIdx];
                }),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        coralHot,
                        goldCoin,
                        Color(0xFF41B979),
                        partnerBlue,
                        lilac,
                        coralHot,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _swatch(ink),
              const SizedBox(width: 6),
              _swatch(Colors.white, bordered: true),
              const SizedBox(width: 6),
              _swatch(goldCoin),
            ],
          ),
          const SizedBox(height: 11),
          // 굵기 아이콘 + 슬라이더
          Row(
            children: [
              const CustomPaint(
                size: Size(18, 18),
                painter: _DotsIconPainter(brown),
              ),
              const SizedBox(width: 8),
              Expanded(child: _sizeSlider()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolButton(_Tool t) {
    final active = _tool == t;
    final Color fg = active ? Colors.white : brown;
    final CustomPainter icon = switch (t) {
      _Tool.pen => _PenIconPainter(fg),
      _Tool.eraser => _QuillIconPainter(fg),
      _Tool.highlighter => _MarkerIconPainter(fg),
    };
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tool = t),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: active ? ink : chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: CustomPaint(size: const Size(16, 16), painter: icon),
        ),
      ),
    );
  }

  Widget _swatch(Color c, {bool bordered = false}) {
    return GestureDetector(
      onTap: () => setState(() => _color = c),
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: bordered ? Border.all(color: lineSoft, width: 1) : null,
        ),
      ),
    );
  }

  Widget _sizeSlider() {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        void setFrom(double dx) =>
            setState(() => _sizeT = (dx / w).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setFrom(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => setFrom(d.localPosition.dx),
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Positioned(
                  left: _sizeT * (w - 16),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: coralHot, width: 2.5),
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

  Widget _photoButton() {
    final Color fg = _dark ? Colors.white : brown;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _dark ? overlay(.55) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: _dark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFA05A50).withValues(alpha: .18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(20, 20), painter: _PhotoIconPainter(fg)),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _dark ? Colors.white : coral,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '+',
                style: sans(
                  13,
                  w: FontWeight.w800,
                  c: _dark ? ink : Colors.white,
                  h: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendPill() {
    return GestureDetector(
      onTap: _send,
      child: Container(
        height: 52,
        padding: _isReply
            ? const EdgeInsets.symmetric(horizontal: 22)
            : const EdgeInsets.only(left: 8, right: 20),
        decoration: BoxDecoration(
          color: coral,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: _isReply
                  ? coral.withValues(alpha: .35)
                  : Colors.black.withValues(alpha: .3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isReply) ...[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const PetFace(size: 26),
              ),
              const SizedBox(width: 9),
            ],
            Text(
              _isReply ? '답장 보내기' : '${mock.partnerNick}에게 보내기',
              style: sans(15, w: FontWeight.w800, c: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================ painters

/// 프리핸드 스트로크 — 라운드캡, 지우개는 BlendMode.clear (saveLayer 안에서).
class _DoodlePainter extends CustomPainter {
  const _DoodlePainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.width;
      switch (s.tool) {
        case _Tool.pen:
          p.color = s.color;
        case _Tool.highlighter:
          p.color = s.color.withValues(alpha: .45);
        case _Tool.eraser:
          p.color = Colors.white;
          p.blendMode = BlendMode.clear;
      }
      if (s.points.length == 1) {
        final dot = Paint()
          ..color = p.color
          ..blendMode = p.blendMode;
        canvas.drawCircle(s.points.first, s.width / 2, dot);
      } else if (s.points.length > 1) {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final pt in s.points.skip(1)) {
          path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, p);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) => true;
}

/// 뒤로가기 셰브론 — M14 6 L8 12 L14 18, stroke 2.5.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(14 * s, 6 * s)
        ..lineTo(8 * s, 12 * s)
        ..lineTo(14 * s, 18 * s),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) => old.color != color;
}

/// 펜 아이콘 — 몸통 외곽선 + 팁 라인 (디자인 SVG 그대로).
class _PenIconPainter extends CustomPainter {
  const _PenIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(15 * s, 5 * s)
        ..lineTo(19 * s, 9 * s)
        ..lineTo(9.5 * s, 18.5 * s)
        ..lineTo(5 * s, 19 * s)
        ..lineTo(5.5 * s, 14.5 * s)
        ..close(),
      p,
    );
    p.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(13 * s, 7 * s), Offset(17 * s, 11 * s), p);
  }

  @override
  bool shouldRepaint(covariant _PenIconPainter old) => old.color != color;
}

/// 지우개(깃펜) 아이콘 — 라인 + 채운 닙.
class _QuillIconPainter extends CustomPainter {
  const _QuillIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final st = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(18 * s, 4 * s), Offset(11 * s, 12 * s), st);
    final fill = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(11 * s, 12 * s)
        ..cubicTo(8 * s, 13 * s, 7 * s, 16 * s, 5.5 * s, 19.5 * s)
        ..cubicTo(9.5 * s, 18.5 * s, 12 * s, 17.5 * s, 13.5 * s, 14.5 * s)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _QuillIconPainter old) => old.color != color;
}

/// 형광펜 아이콘 — 두꺼운 사선 + 밑줄 2개.
class _MarkerIconPainter extends CustomPainter {
  const _MarkerIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    Paint p(double w) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(9 * s, 13 * s), Offset(16 * s, 6 * s), p(5));
    canvas.drawLine(Offset(6 * s, 16.5 * s), Offset(10.5 * s, 16.5 * s), p(3));
    canvas.drawLine(Offset(5 * s, 20 * s), Offset(14 * s, 20 * s), p(2));
  }

  @override
  bool shouldRepaint(covariant _MarkerIconPainter old) => old.color != color;
}

/// 사진 아이콘 — 라운드 사각 + 태양 + 산 능선.
class _PhotoIconPainter extends CustomPainter {
  const _PhotoIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final st = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 * s, 5.5 * s, 16 * s, 13 * s),
        Radius.circular(3.5 * s),
      ),
      st,
    );
    canvas.drawCircle(Offset(9 * s, 10.5 * s), 1.6 * s, Paint()..color = color);
    final ridge = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(6.5 * s, 16 * s)
        ..lineTo(11 * s, 11.8 * s)
        ..lineTo(14 * s, 14.6 * s)
        ..lineTo(16 * s, 12.8 * s)
        ..lineTo(18 * s, 15 * s),
      ridge,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoIconPainter old) => old.color != color;
}

/// 굵기 아이콘 — 커지는 점 3개.
class _DotsIconPainter extends CustomPainter {
  const _DotsIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()..color = color;
    canvas.drawCircle(Offset(4.5 * s, 12 * s), 1.4 * s, p);
    canvas.drawCircle(Offset(11 * s, 12 * s), 2.4 * s, p);
    canvas.drawCircle(Offset(19 * s, 12 * s), 3.6 * s, p);
  }

  @override
  bool shouldRepaint(covariant _DotsIconPainter old) => old.color != color;
}

/// 점선 원 테두리 — 휘발 ON 상태의 '5' 배지.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 1,
    );
    const dashes = 8;
    const sweep = 2 * _pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * .55, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color;
}
