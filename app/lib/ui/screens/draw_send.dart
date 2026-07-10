// Memory Pager — Draw & Send (P0, full-screen; also the reply composer).
//
// The one screen that authors a doodle. It captures REAL strokes with per-point
// timestamps and ships them as `stroke_data` exactly as docs/API.md §4 specifies:
//
//   points: [[x, y, t], ...]   // t = ms elapsed *from that stroke's start*
//
// `DragUpdateDetails.sourceTimeStamp` is null on web, so we time each stroke
// with a Stopwatch instead — same semantics, portable.
//
// content_type is judged HERE (the server never recomputes it, API.md §4):
//   strokes present -> drawing ; else photo attached -> photo ; else -> text.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

/// The ink palette. Hex is 6-digit uppercase, no `#` — the wire format.
const List<_Pen> _pens = <_Pen>[
  _Pen('26282B', 'pen'),
  _Pen('8A9A8E', 'marker'),
  _Pen('B5654A', 'marker'),
  _Pen('4A6B8A', 'marker'),
  _Pen('7C6A9C', 'marker'),
  _Pen('A98B3E', 'marker'),
];

class _Pen {
  const _Pen(this.hex, this.kind);
  final String hex;
  final String kind;
  Color get color => hexToColor(hex);
}

/// One stroke being drawn / already drawn, in canvas-local coordinates.
class _LiveStroke {
  _LiveStroke(this.pen, this.width);
  final _Pen pen;
  final double width;
  final List<StrokePoint> points = <StrokePoint>[];
}

class DrawSendScreen extends StatefulWidget {
  /// [parentId] threads a reply to an existing doodle; null for a fresh send.
  /// Kept callable as `const DrawSendScreen()` for the existing deep-link route.
  const DrawSendScreen({super.key, this.parentId});

  final String? parentId;

  @override
  State<DrawSendScreen> createState() => _DrawSendScreenState();
}

class _DrawSendScreenState extends State<DrawSendScreen> {
  final List<_LiveStroke> _strokes = <_LiveStroke>[];
  final TextEditingController _text = TextEditingController();

  /// Elapsed time for the whole composition (duration_ms) — never DateTime.now().
  final Stopwatch _session = Stopwatch();

  /// `_session.elapsedMilliseconds` when the current stroke began.
  int _strokeBaseMs = 0;

  int _penIndex = 0;
  double _width = 6;
  SendMode _mode = SendMode.normal;
  Uint8List? _photo;
  Size _canvas = const Size(1, 1);
  bool _sending = false;

  _Pen get _pen => _pens[_penIndex];

  bool get _hasContent =>
      _strokes.isNotEmpty || _photo != null || _text.text.trim().isNotEmpty;

  /// The app decides the type; the server trusts it (API.md §4).
  ContentType get _contentType {
    if (_strokes.isNotEmpty) return ContentType.drawing;
    if (_photo != null) return ContentType.photo;
    return ContentType.text;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  // -- drawing ---------------------------------------------------------------

  void _panStart(Offset p) {
    if (!_session.isRunning) _session.start();
    _strokeBaseMs = _session.elapsedMilliseconds;
    final s = _LiveStroke(_pen, _width)
      ..points.add(StrokePoint(x: p.dx, y: p.dy, t: 0));
    setState(() => _strokes.add(s));
  }

  void _panUpdate(Offset p) {
    if (_strokes.isEmpty) return;
    final t = _session.elapsedMilliseconds - _strokeBaseMs;
    setState(() => _strokes.last.points.add(StrokePoint(x: p.dx, y: p.dy, t: t)));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(_strokes.removeLast);
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(_strokes.clear);
  }

  // -- photo -----------------------------------------------------------------

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1440);
      if (x == null) return;
      final bytes = await x.readAsBytes(); // web-safe (no dart:io)
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (_) {
      if (!mounted) return;
      _toast('이 기기에서는 사진을 가져올 수 없어요');
    }
  }

  // -- send ------------------------------------------------------------------

  StrokeData? _buildStrokeData() {
    if (_strokes.isEmpty) return null;
    return StrokeData(
      canvas: CanvasSize(w: _canvas.width.round(), h: _canvas.height.round()),
      durationMs: _session.elapsedMilliseconds,
      strokes: <Stroke>[
        for (final s in _strokes)
          Stroke(
            pen: s.pen.kind,
            color: s.pen.hex,
            width: s.width,
            points: s.points,
          ),
      ],
    );
  }

  Future<void> _send() async {
    if (!_hasContent || _sending) return;
    setState(() => _sending = true);
    final body = _text.text.trim();
    try {
      await appState.sendDoodle(
        mode: _mode,
        contentType: _contentType,
        parentId: widget.parentId,
        textBody: body.isEmpty ? null : body,
        photoBytes: _photo,
        strokeData: _buildStrokeData(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _toast(e.error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _toast('보내지 못했어요');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: cpSans(size: 13, color: cpMist)),
        backgroundColor: cpInk,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(_partnerName()),
              const SizedBox(height: 14),
              Expanded(child: _canvasArea()),
              const SizedBox(height: 10),
              _canvasTools(),
              const SizedBox(height: 12),
              CpTextField(
                controller: _text,
                hint: '한마디 적어보세요 (선택)',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CpEyebrow('잉크 · INK', size: 9),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 16),
              CpThickness(
                value: _width,
                color: _pen.color,
                onChanged: (v) => setState(() => _width = v),
              ),
              const SizedBox(height: 16),
              const CpHair(),
              const SizedBox(height: 12),
              CpModeToggle(_mode, (m) => setState(() => _mode = m)),
              const SizedBox(height: 8),
              Text(_modeDescription(_mode),
                  style: cpSans(size: 12, color: cpInkA(0.5))),
              const SizedBox(height: 14),
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(String partner) {
    return Row(
      children: [
        CpIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        Column(
          children: [
            CpEyebrow(widget.parentId == null ? 'TO' : '답장 · RE', size: 9),
            const SizedBox(height: 4),
            Text(partner,
                style: cpSans(size: 17, weight: FontWeight.w600, spacing: 0.4)),
          ],
        ),
        const Spacer(),
        Opacity(
          opacity: _hasContent && !_sending ? 1 : 0.35,
          child: CpPrimaryButton(
            label: _sending ? '보내는 중' : '보내기',
            onTap: _send,
          ),
        ),
      ],
    );
  }

  Widget _canvasArea() {
    return CpMatted(
      mat: 12,
      inset: 0,
      child: LayoutBuilder(
        builder: (context, c) {
          _canvas = Size(c.maxWidth, c.maxHeight);
          return ClipRect(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _panStart(d.localPosition),
              onPanUpdate: (d) => _panUpdate(d.localPosition),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (_photo != null)
                    Image.memory(_photo!, fit: BoxFit.cover)
                  else if (_strokes.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CpEyebrow('BLANK PRINT', size: 9),
                          const SizedBox(height: 12),
                          Text('여기에 낙서를 시작하세요',
                              style: cpSans(size: 14, color: cpInkA(0.35))),
                        ],
                      ),
                    ),
                  CustomPaint(
                    painter: _LivePainter(_strokes),
                    size: Size.infinite,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _canvasTools() {
    return Row(
      children: [
        CpEyebrow('획 ${_strokes.length}', size: 9),
        const Spacer(),
        _tinyButton('되돌리기', _strokes.isEmpty ? null : _undo),
        const SizedBox(width: 8),
        _tinyButton('전체 지우기', _strokes.isEmpty ? null : _clear),
        if (_photo != null) ...[
          const SizedBox(width: 8),
          _tinyButton('사진 제거', () => setState(() => _photo = null)),
        ],
      ],
    );
  }

  Widget _tinyButton(String label, VoidCallback? onTap) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: cpInkA(on ? 0.16 : 0.07), width: 0.5),
        ),
        child: Text(label,
            style: cpSans(
                size: 10, color: cpInkA(on ? 0.6 : 0.25), spacing: 0.5)),
      ),
    );
  }

  Widget _penRow() {
    return Row(
      children: <Widget>[
        for (int i = 0; i < _pens.length; i++) ...<Widget>[
          GestureDetector(
            onTap: () => setState(() => _penIndex = i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _penIndex == i ? cpInkA(0.45) : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _pens[i].color,
                  shape: BoxShape.circle,
                  border: Border.all(color: cpInkA(0.14)),
                ),
              ),
            ),
          ),
          if (i != _pens.length - 1) const Spacer(),
        ],
      ],
    );
  }

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CpAction(
          glyph: '🖼',
          label: '갤러리',
          onTap: () => _pickPhoto(ImageSource.gallery),
        ),
        CpAction(
          glyph: '📷',
          label: '사진 찍기',
          onTap: () => _pickPhoto(ImageSource.camera),
        ),
        CpAction(
          glyph: '✍️',
          label: _contentTypeLabel(_contentType),
          accent: true,
          onTap: () {},
        ),
      ],
    );
  }

  String _partnerName() {
    final g = appState.group;
    final meId = appState.me?.id;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId != meId) return m.nickname ?? m.displayName;
      }
    }
    return '상대';
  }
}

// ===========================================================================
// Painter — draws the in-progress strokes
// ===========================================================================

class _LivePainter extends CustomPainter {
  const _LivePainter(this.strokes);

  final List<_LiveStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      if (s.points.length == 1) {
        final p = s.points.first;
        canvas.drawCircle(
          Offset(p.x, p.y),
          s.width / 2,
          Paint()..color = s.pen.color,
        );
        continue;
      }
      final paint = Paint()
        ..color = s.pen.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.x, s.points.first.y);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LivePainter old) => true;
}

// ===========================================================================
// Labels
// ===========================================================================

String _modeDescription(SendMode m) => switch (m) {
      SendMode.normal => '다음 낙서를 보낼 때까지 남아요 · 레포트에 반영',
      SendMode.ephemeral => '상대가 확인하고 5초 뒤 사라져요 · 레포트 미반영',
    };

String _contentTypeLabel(ContentType c) => switch (c) {
      ContentType.drawing => '그림 위주',
      ContentType.photo => '사진 위주',
      ContentType.text => '텍스트 위주',
    };
