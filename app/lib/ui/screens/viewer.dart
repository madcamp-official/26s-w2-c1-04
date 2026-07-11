// Memory Pager — Doodle viewer (P0/P1, full-screen push target).
//
// Opens on [initialIndex] of the album and pages through it. Opening a doodle
// registers the view (`appState.openDoodle` -> `POST /doodles/{id}/view`,
// idempotent) and, when it is an *ephemeral* doodle that someone else sent,
// arms the 5-second countdown the server also runs. When the timer lands the
// doodle is gone for good and we say so.
//
// The contract distinguishes two absences and so do we (API.md §0):
//   410 doodle_expired -> "사라졌어요"  (it existed; it self-destructed)
//   404 not_found      -> "없는 낙서예요" (it never existed / bad link)

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/mock_repository.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'draw_send.dart';

/// The server's ephemeral lifetime (API.md §4: `expires_at = now + 5s`).
const Duration _kEphemeral = Duration(seconds: 5);

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late int _index = widget.initialIndex;

  /// Set once the doodle on screen has burned down (410) — we hold the frame
  /// and say so rather than silently sliding to the next memory.
  bool _expired = false;

  /// Set when the id simply isn't there (404).
  bool _missing = false;

  Timer? _tick;
  double _remain = 0;
  String? _armedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Doodle? get _current {
    final a = appState.album;
    if (_index < 0 || _index >= a.length) return null;
    return a[_index];
  }

  // -- open / countdown ------------------------------------------------------

  Future<void> _open() async {
    final d = _current;
    if (d == null) {
      setState(() => _missing = true);
      return;
    }
    try {
      await appState.openDoodle(d.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.status == 410) {
          _expired = true;
        } else if (e.status == 404) {
          _missing = true;
        }
      });
      return;
    }
    if (!mounted) return;

    // Only a *received* ephemeral burns down; my own copy stays.
    final armed = appState.ephemeralExpiry[d.id] != null &&
        d.senderId != appState.me?.id;
    if (armed) _arm(d.id);
  }

  void _arm(String id) {
    _tick?.cancel();
    _armedId = id;
    _remain = _kEphemeral.inMilliseconds / 1000;
    _tick = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remain -= 0.1);
      final gone = !appState.album.any((d) => d.id == id);
      if (_remain <= 0 || gone) {
        t.cancel();
        setState(() {
          _armedId = null;
          _expired = true;
        });
      }
    });
  }

  void _disarm() {
    _tick?.cancel();
    _tick = null;
    _armedId = null;
    _remain = 0;
  }

  // -- navigation ------------------------------------------------------------

  void _go(int delta) {
    final a = appState.album;
    if (a.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    // After an expiry the list already shifted; the same index is the next one.
    final next = (_expired && delta > 0) ? _index : _index + delta;
    if (next < 0 || next >= a.length) return;
    _disarm();
    setState(() {
      _index = next;
      _expired = false;
      _missing = false;
    });
    _open();
  }

  Future<void> _reply(Doodle d) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => DrawSendScreen(parentId: d.id)),
    );
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final a = appState.album;
        final d = _expired || _missing ? null : _current;
        final canPrev = !_missing && _index > 0;
        final canNext = !_missing && _index < a.length - (_expired ? 0 : 1);

        return CpScaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(d),
                  const SizedBox(height: 16),
                  if (_armedId != null) ...[
                    _Countdown(remain: _remain),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: (v) {
                        final vx = v.primaryVelocity ?? 0;
                        if (vx < -120 && canNext) _go(1);
                        if (vx > 120 && canPrev) _go(-1);
                      },
                      child: Center(child: _stage(d)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (d != null) _meta(d),
                  const SizedBox(height: 14),
                  _controls(d, canPrev: canPrev, canNext: canNext),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(Doodle? d) {
    return Row(
      children: [
        CpIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        Column(
          children: [
            const CpEyebrow('받은 그림'),
            const SizedBox(height: 4),
            Text(
              d == null ? '—' : _senderName(d.senderId),
              style: cpSerif(
                size: 17,
                weight: FontWeight.w600,
                style: FontStyle.normal,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _stage(Doodle? d) {
    if (_missing) {
      return const CpEmptyState(
        icon: Icons.help_outline,
        text: '없는 낙서예요\n링크가 잘못됐을 수 있어요',
      );
    }
    if (_expired || d == null) {
      return const CpEmptyState(
        icon: Icons.lock_clock,
        text: '사라졌어요\n사라지기 모드 낙서는 확인 후 5초 뒤 지워져요',
      );
    }
    return AspectRatio(
      aspectRatio: 0.86,
      child: CpMatted(mat: 16, inset: 0, child: _content(d)),
    );
  }

  Widget _content(Doodle d) {
    final repo = appState.repo;
    final StrokeData? strokes =
        repo is MockRepository ? repo.strokeDataFor(d.id) : null;
    final Uint8List? photo =
        repo is MockRepository ? repo.photoBytesFor(d.id) : null;

    final layers = <Widget>[];
    if (photo != null) {
      layers.add(Positioned.fill(child: Image.memory(photo, fit: BoxFit.cover)));
    }
    if (strokes != null && strokes.strokes.isNotEmpty) {
      layers.add(Positioned.fill(
        child: CustomPaint(
          painter: CpDoodlePainter(strokes, background: photo == null ? cpPrint : null),
        ),
      ));
    }
    if (layers.isEmpty) {
      // Honest placeholder: we say what kind of memory this is, we don't fake it.
      layers.add(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: cpDim,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cpContentIcon(d.contentType),
                  size: 38,
                  color: cpInkA(0.4),
                ),
              ),
              const SizedBox(height: 16),
              if ((d.textBody ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    d.textBody!,
                    textAlign: TextAlign.center,
                    style: cpSans(size: 17, height: 1.5),
                  ),
                )
              else
                Text('이미지를 불러올 수 없어요',
                    style: cpSans(size: 12, color: cpInkA(0.4))),
            ],
          ),
        ),
      );
    } else if ((d.textBody ?? '').isNotEmpty) {
      layers.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: cpPrint.withValues(alpha: 0.86),
            child: Text(d.textBody!,
                textAlign: TextAlign.center, style: cpSans(size: 14)),
          ),
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: layers);
  }

  Widget _meta(Doodle d) {
    final chips = <String>[
      _contentTypeLabel(d.contentType),
      if (d.mode == SendMode.ephemeral) '사라지기',
      if (d.replyCount > 0) '답장 ${d.replyCount}',
    ];
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [for (final c in chips) _Chip(c)],
        ),
        const SizedBox(height: 10),
        Text(
          '${_senderName(d.senderId)} · ${_stamp(d.createdAt)}',
          style: cpSans(size: 11, color: cpInkA(0.5)),
        ),
      ],
    );
  }

  Widget _controls(Doodle? d, {required bool canPrev, required bool canNext}) {
    return Row(
      children: [
        _arrow(Icons.chevron_left, canPrev ? () => _go(-1) : null),
        const Spacer(),
        if (d != null)
          SizedBox(
            width: 150,
            child: CpPrimaryButton(label: '답장하기', onTap: () => _reply(d)),
          )
        else
          SizedBox(
            width: 150,
            child: CpPrimaryButton(
              label: '닫기',
              filled: false,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        const Spacer(),
        _arrow(Icons.chevron_right, canNext ? () => _go(1) : null),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.2 : 1,
      child: CpIconButton(icon: icon, onTap: onTap ?? () {}),
    );
  }

  String _senderName(String userId) {
    if (appState.me?.id == userId) return '나';
    final g = appState.group;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId == userId) return m.nickname ?? m.displayName;
      }
    }
    return '상대';
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remain});

  final double remain;

  @override
  Widget build(BuildContext context) {
    final r = remain < 0 ? 0.0 : remain;
    final frac = (r / _kEphemeral.inSeconds).clamp(0.0, 1.0);
    return Column(
      children: [
        Text('${r.ceil()}초 뒤 사라져요',
            style: cpSans(size: 12, color: cpEuc, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(cpRadiusPill),
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(width: c.maxWidth, height: 4, color: cpInkA(0.10)),
                Container(width: c.maxWidth * frac, height: 4, color: cpEuc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: cpDim,
        borderRadius: BorderRadius.circular(cpRadiusPill),
        border: Border.all(color: cpInkA(0.06)),
      ),
      child: Text(label,
          style: cpSans(
            size: 11,
            color: cpInkA(0.6),
            weight: FontWeight.w500,
            spacing: 0.3,
          )),
    );
  }
}

String _contentTypeLabel(ContentType c) => switch (c) {
      ContentType.drawing => '그림 위주',
      ContentType.photo => '사진 위주',
      ContentType.text => '텍스트 위주',
    };

String _two(int n) => n < 10 ? '0$n' : '$n';

String _stamp(DateTime utc) {
  final t = utc.toLocal();
  return '${t.month}/${t.day} ${_two(t.hour)}:${_two(t.minute)}';
}
