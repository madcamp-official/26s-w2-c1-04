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
//
// 이어그리기: when this is a reply ([parentId] != null) the received doodle is
// laid UNDER the canvas as a gentle tracing background (its real strokes via
// [CpDoodlePainter], or its real photo) so you draw on top of what you got.
//
// Sumone skin: warm cream ground, soft-rounded surfaces, one pink accent, and
// Material OUTLINED line icons for chrome — zero emoji anywhere.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/mock_repository.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

/// The ink palette. Hex is 6-digit uppercase, no `#` — the wire format.
const List<_Pen> _pens = <_Pen>[
  _Pen('473D33', 'pen'), // warm brown-ink
  _Pen('E4707E', 'marker'), // heart pink
  _Pen('B5654A', 'marker'), // clay
  _Pen('C99A5B', 'marker'), // gold
  _Pen('8A9A8E', 'marker'), // sage
  _Pen('7C6A9C', 'marker'), // plum
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

  // 이어그리기 — the received doodle's real content, laid under the canvas as a
  // tracing background on a reply. Honest: it's the actual parent, just dimmed.
  StrokeData? _parentStrokes;
  Uint8List? _parentPhoto;

  _Pen get _pen => _pens[_penIndex];

  bool get _hasParentBackground =>
      (_parentStrokes != null && _parentStrokes!.strokes.isNotEmpty) ||
      _parentPhoto != null;

  bool get _hasContent =>
      _strokes.isNotEmpty || _photo != null || _text.text.trim().isNotEmpty;

  /// The app decides the type; the server trusts it (API.md §4).
  ContentType get _contentType {
    if (_strokes.isNotEmpty) return ContentType.drawing;
    if (_photo != null) return ContentType.photo;
    return ContentType.text;
  }

  @override
  void initState() {
    super.initState();
    // Pull the parent's real content for the tracing background (mock only —
    // the REST client streams pixels, so there is nothing to inline there).
    final pid = widget.parentId;
    if (pid != null) {
      final repo = appState.repo;
      if (repo is MockRepository) {
        _parentStrokes = repo.strokeDataFor(pid);
        _parentPhoto = repo.photoBytesFor(pid);
      }
    }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cpRadiusSmall),
        ),
      ),
    );
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
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
            const SizedBox(height: 18),
            CpEyebrow('잉크'),
            const SizedBox(height: 12),
            _penRow(),
            const SizedBox(height: 16),
            CpThickness(
              value: _width,
              color: _pen.color,
              onChanged: (v) => setState(() => _width = v),
            ),
            const SizedBox(height: 18),
            const CpHair(),
            const SizedBox(height: 14),
            CpModeToggle(_mode, (m) => setState(() => _mode = m)),
            const SizedBox(height: 8),
            Text(
              _modeDescription(_mode),
              style: cpSans(size: 12, color: cpInkA(0.5)),
            ),
            const SizedBox(height: 16),
            _bottomActions(),
          ],
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
            CpEyebrow(widget.parentId == null ? '받는 사람' : '답장', size: 10),
            const SizedBox(height: 4),
            Text(
              partner,
              style: cpSans(size: 17, weight: FontWeight.w600, spacing: 0.3),
            ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cpRadiusSmall),
        child: LayoutBuilder(
          builder: (context, c) {
            _canvas = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _panStart(d.localPosition),
              onPanUpdate: (d) => _panUpdate(d.localPosition),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // 이어그리기 background — the real received doodle, gently dimmed
                  // so your fresh ink reads on top of it.
                  if (_parentPhoto != null)
                    Opacity(
                      opacity: 0.5,
                      child: Image.memory(_parentPhoto!, fit: BoxFit.cover),
                    ),
                  if (_parentStrokes != null &&
                      _parentStrokes!.strokes.isNotEmpty)
                    Opacity(
                      opacity: 0.45,
                      child: CustomPaint(
                        painter: CpDoodlePainter(_parentStrokes!),
                      ),
                    ),
                  // Your own photo replaces the surface below it.
                  if (_photo != null) Image.memory(_photo!, fit: BoxFit.cover),
                  // Honest empty state — only when there is truly nothing yet.
                  if (_photo == null &&
                      _strokes.isEmpty &&
                      !_hasParentBackground)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gesture, size: 34, color: cpInkA(0.22)),
                          const SizedBox(height: 12),
                          Text(
                            '여기에 낙서를 시작하세요',
                            style: cpSans(size: 14, color: cpInkA(0.35)),
                          ),
                        ],
                      ),
                    ),
                  // Your live strokes, always on top.
                  CustomPaint(
                    painter: _LivePainter(_strokes),
                    size: Size.infinite,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _canvasTools() {
    return Row(
      children: [
        CpEyebrow(
          widget.parentId != null
              ? '이어그리기 · 획 ${_strokes.length}'
              : '획 ${_strokes.length}',
          size: 10,
        ),
        const Spacer(),
        _tinyButton(Icons.undo, '되돌리기', _strokes.isEmpty ? null : _undo),
        const SizedBox(width: 8),
        _tinyButton(
            Icons.delete_outline, '전체 지우기', _strokes.isEmpty ? null : _clear),
        if (_photo != null) ...[
          const SizedBox(width: 8),
          _tinyButton(
              Icons.hide_image_outlined, '사진 제거', () => setState(() => _photo = null)),
        ],
      ],
    );
  }

  Widget _tinyButton(IconData icon, String label, VoidCallback? onTap) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? cpPrint : Colors.transparent,
          borderRadius: BorderRadius.circular(cpRadiusPill),
          border: Border.all(color: cpInkA(on ? 0.12 : 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cpInkA(on ? 0.6 : 0.25)),
            const SizedBox(width: 5),
            Text(
              label,
              style: cpSans(
                size: 11,
                color: cpInkA(on ? 0.6 : 0.25),
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                  color: _penIndex == i ? cpEucA(0.6) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _pens[i].color,
                  shape: BoxShape.circle,
                  border: Border.all(color: cpInkA(0.10)),
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
          icon: Icons.image_outlined,
          label: '갤러리',
          onTap: () => _pickPhoto(ImageSource.gallery),
        ),
        CpAction(
          icon: Icons.photo_camera_outlined,
          label: '사진 찍기',
          onTap: () => _pickPhoto(ImageSource.camera),
        ),
        CpAction(
          icon: cpContentIcon(_contentType),
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
