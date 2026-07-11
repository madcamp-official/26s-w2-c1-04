// Memory Pager — Reply to a doodle (full-screen push target).
//
// A thin, threaded wrapper over the shared authoring surface: it shows a quiet
// preview of the *parent* doodle (resolved from the loaded album first, then
// `repo.getDoodle` as the source of truth), then hands off to [DrawSendScreen]
// with [parentId] set so the drawing is saved as a reply (RV-1).
//
// The preview is honest: it never fabricates the parent's content. Missing /
// expired / not-found parents each surface a distinct, loud empty state — a
// 410 `doodle_expired` (the ephemeral self-destructed) reads differently from a
// 404 `not_found` (it never existed) — and neither offers a reply, because you
// cannot thread onto a doodle that is gone.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'draw_send.dart';

class ReplyScreen extends StatefulWidget {
  const ReplyScreen({super.key, required this.parentId});

  /// The doodle being replied to.
  final String parentId;

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

/// Resolution state of the parent doodle preview.
enum _RpStatus { loading, ready, notFound, expired, error }

class _ReplyScreenState extends State<ReplyScreen> {
  _RpStatus _status = _RpStatus.loading;
  Doodle? _parent;
  String _errorText = '원본을 불러오지 못했어요';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The album is already loaded when we arrive from the viewer, so prefer the
  /// in-memory row; only reach for the network when it isn't there.
  Doodle? _findInAlbum(String id) {
    for (final d in appState.album) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> _load() async {
    final cached = _findInAlbum(widget.parentId);
    if (cached != null) {
      setState(() {
        _parent = cached;
        _status = _RpStatus.ready;
      });
      return;
    }

    try {
      final d = await appState.repo.getDoodle(widget.parentId);
      if (!mounted) return;
      setState(() {
        _parent = d;
        _status = _RpStatus.ready;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // Contract edge: 410 (ephemeral gone) vs 404 (never existed) are
        // deliberately distinct states.
        if (e.status == 410 || e.code == 'doodle_expired') {
          _status = _RpStatus.expired;
        } else if (e.status == 404 || e.code == 'not_found') {
          _status = _RpStatus.notFound;
        } else {
          _status = _RpStatus.error;
          _errorText = e.message.isEmpty ? _errorText : e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _RpStatus.error);
    }
  }

  Future<void> _retry() async {
    setState(() => _status = _RpStatus.loading);
    await _load();
  }

  /// Hand off to the shared authoring surface, threaded onto this parent.
  void _openDraw() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DrawSendScreen(parentId: widget.parentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '답장하기',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      // Preview copy (sender name) is derived from live session state, so the
      // whole body rebuilds when appState notifies.
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) => _body(),
      ),
    );
  }

  Widget _body() {
    switch (_status) {
      case _RpStatus.loading:
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
          ),
        );

      case _RpStatus.expired:
        return const _RpNotice(
          icon: Icons.timer_off_outlined,
          text: '사라진 낙서예요\n확인하면 사라지는 낙서라 원본을 볼 수 없어요',
        );

      case _RpStatus.notFound:
        return const _RpNotice(
          icon: Icons.search_off,
          text: '원본 낙서를 찾을 수 없어요\n이미 지워졌을 수 있어요',
        );

      case _RpStatus.error:
        return _RpNotice(
          icon: Icons.cloud_off,
          text: _errorText,
          onRetry: _retry,
        );

      case _RpStatus.ready:
        return _ready(_parent!);
    }
  }

  Widget _ready(Doodle parent) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CpEyebrow('원본 낙서'),
                const SizedBox(height: 14),
                _RpParentCard(doodle: parent, senderName: _senderName(parent.senderId)),
                const SizedBox(height: 18),
                Text(
                  '답장은 원본 낙서에 이어져 사진첩에서 함께 볼 수 있어요.',
                  style: cpSans(size: 12.5, color: cpInkA(0.5), height: 1.5),
                ),
              ],
            ),
          ),
        ),
        _RpFooter(onTap: _openDraw),
      ],
    );
  }

  /// Display name for a sender id, preferring the partner-given nickname and
  /// labelling my own doodles as '나'. Falls back to a neutral '상대' — never a
  /// fabricated identity.
  String _senderName(String id) {
    if (appState.me?.id == id) return '나';
    final g = appState.group;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId == id) return m.nickname ?? m.displayName;
      }
    }
    return '상대';
  }
}

// ---------------------------------------------------------------------------
// Parent preview card
// ---------------------------------------------------------------------------

/// The matted preview of the doodle being replied to. Renders a content-kind
/// thumbnail (honest placeholder — it signals the *kind*, never fakes a
/// drawing), the sender, a meta line, an optional text body, and an ephemeral
/// marker when relevant.
class _RpParentCard extends StatelessWidget {
  const _RpParentCard({required this.doodle, required this.senderName});

  final Doodle doodle;
  final String senderName;

  @override
  Widget build(BuildContext context) {
    final body = doodle.textBody;
    final hasBody = body != null && body.trim().isNotEmpty;

    return CpMatted(
      mat: 16,
      inset: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CpDoodleThumb(doodle, size: 66),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CpEyebrow(_typeLabel(doodle.contentType)),
                    const SizedBox(height: 7),
                    Text(
                      senderName,
                      style: cpSans(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _metaLine(doodle),
                      style: cpSans(size: 12, color: cpInkA(0.5), spacing: 0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasBody) ...[
            const SizedBox(height: 14),
            const CpHair(),
            const SizedBox(height: 14),
            Text(
              body,
              style: cpSans(size: 14, height: 1.55),
            ),
          ],
          if (doodle.mode == SendMode.ephemeral) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.hourglass_bottom, size: 13, color: cpEucA(0.8)),
                const SizedBox(width: 6),
                Text(
                  '사라지는 낙서',
                  style: cpSans(
                    size: 11,
                    color: cpEuc,
                    weight: FontWeight.w600,
                    spacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(ContentType t) => switch (t) {
        ContentType.photo => '사진',
        ContentType.drawing => '그림',
        ContentType.text => '글',
      };

  String _metaLine(Doodle d) {
    final parts = <String>[_fmtWhen(d.createdAt), cpSendModeLabel(d.mode)];
    if (d.replyCount > 0) parts.add('답장 ${d.replyCount}');
    return parts.join('  ·  ');
  }

  /// Absolute month/day from the doodle's own timestamp — no wall clock read,
  /// so no relative "N분 전" is invented.
  String _fmtWhen(DateTime d) {
    final t = d.toLocal();
    return '${t.month}월 ${t.day}일';
  }
}

// ---------------------------------------------------------------------------
// Footer CTA
// ---------------------------------------------------------------------------

/// The pinned bottom action bar: a hairline rule over the primary CTA.
class _RpFooter extends StatelessWidget {
  const _RpFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cpMist,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CpHair(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: _RpWideButton(label: '답장 그리기', onTap: onTap),
          ),
        ],
      ),
    );
  }
}

/// A full-width, pill-shaped pink CTA — the Sumone primary voice. A soft brush
/// line icon paired with the label, warm-white text on the [cpEuc] accent, and a
/// gentle glow. Rounded [cpRadiusPill], never the old boxy 2px keyline.
class _RpWideButton extends StatelessWidget {
  const _RpWideButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: cpEuc,
          borderRadius: BorderRadius.circular(cpRadiusPill),
          boxShadow: [
            BoxShadow(
              color: cpEucA(0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.brush_outlined, size: 18, color: cpPrint),
            const SizedBox(width: 9),
            Text(
              label,
              style: cpSans(
                size: 14,
                color: cpPrint,
                weight: FontWeight.w600,
                spacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notice states (loud, honest failures)
// ---------------------------------------------------------------------------

/// A centered empty/failure state with an optional retry — used for the
/// distinct not-found / expired / error cases. No reply affordance: a gone
/// parent cannot be threaded onto.
class _RpNotice extends StatelessWidget {
  const _RpNotice({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CpEmptyState(icon: icon, text: text),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              CpPrimaryButton(label: '다시 시도', onTap: onRetry!, filled: false),
            ],
          ],
        ),
      ),
    );
  }
}
