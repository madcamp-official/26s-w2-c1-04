// Memory Pager — Communication home (tab 2 · '소통').
//
// The partner-facing surface. It greets me by name and names my partner, then
// offers the two loud things this tab is for: a big "콕 찌르기" (poke) that fires
// `appState.poke(partnerId)` — the sim partner pokes back a beat later and the
// app-shell banner announces it — and a big "낙서 보내기" entry into
// [DrawSendScreen]. Below sit the single most-recent *received* doodle (a matted
// card that opens the [ViewerScreen]) and a short recent-exchange log (top of
// `appState.album`, each row opening the viewer), plus a quiet link into the
// home-widget preview ([WidgetPreviewScreen]).
//
// Renders inside the app shell's IndexedStack — NO back affordance, NO bottom
// nav of its own (AppShell owns [CpBottomNav]). All state is read from the global
// [appState] under a [ListenableBuilder]; mutations go through appState actions.
//
// Honesty over fallbacks: with no partner the poke is disabled (not faked), with
// no received doodle the hero shows an empty state (never a stand-in), and
// ephemeral doodles are labelled rather than pre-revealed. The 5s ephemeral
// countdown and the 404/410 split live in the [ViewerScreen] this screen pushes
// into — CommHome never fetches a doodle by id, so it can't manufacture those
// states; it only reflects `album` reactively (an expired doodle simply drops
// out when its `doodle:expired` event lands).

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'draw_send.dart';
import 'viewer.dart';
import 'widget_preview.dart';

class CommHomeScreen extends StatefulWidget {
  const CommHomeScreen({super.key});

  @override
  State<CommHomeScreen> createState() => _CommHomeState();
}

class _CommHomeState extends State<CommHomeScreen> {
  /// Set once a poke has been fired this session — shows a quiet confirmation
  /// slip. The partner's poke-back itself surfaces as the app-shell banner.
  bool _poked = false;

  // -- Partner / naming ------------------------------------------------------

  /// The other member of the 2-person group (null if I'm alone).
  Member? _partnerOf(Group? g, User? me) {
    if (g == null || me == null) return null;
    for (final m in g.members) {
      if (m.userId != me.id) return m;
    }
    return null;
  }

  String _displayNameOf(Member m) => m.nickname ?? m.displayName;

  /// Name for a doodle's sender, preferring a partner-given nickname.
  String _senderName(String senderId) {
    final me = appState.me;
    if (me != null && me.id == senderId) return me.displayName;
    final g = appState.group;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId == senderId) return _displayNameOf(m);
      }
    }
    return '상대';
  }

  bool _isMine(Doodle d) => appState.me?.id == d.senderId;

  // -- Content helpers -------------------------------------------------------

  String _preview(Doodle d) => switch (d.contentType) {
        ContentType.text =>
          (d.textBody?.trim().isNotEmpty ?? false) ? d.textBody!.trim() : '메시지',
        ContentType.photo => '사진을 보냈어요',
        ContentType.drawing => '그림을 그렸어요',
      };

  /// A short, deterministic stamp from the doodle's own timestamp. No wall
  /// clock is read (no `DateTime.now()`), so relative "n분 전" is intentionally
  /// avoided — the app has no shared clock accessor here.
  String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.month}월 ${d.day}일 · ${two(d.hour)}:${two(d.minute)}';
  }

  bool _isExpiring(Doodle d) => appState.ephemeralExpiry.containsKey(d.id);

  // -- Actions ---------------------------------------------------------------

  Future<void> _poke(Member partner) async {
    try {
      await appState.poke(partner.userId);
      if (mounted) setState(() => _poked = true);
    } catch (_) {
      // REST poke is best-effort; a failure just leaves the slip unshown.
    }
  }

  void _openViewer(Doodle d) {
    final idx = appState.album.indexWhere((x) => x.id == d.id);
    cpPush(context, ViewerScreen(initialIndex: idx < 0 ? 0 : idx));
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '소통',
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final me = appState.me;
          final group = appState.group;
          final partner = _partnerOf(group, me);
          final album = appState.album;

          // Newest doodle the partner sent (album is newest-first).
          final received = album
              .where((d) => !_isMine(d))
              .cast<Doodle?>()
              .firstWhere((d) => d != null, orElse: () => null);
          final recent = album.take(5).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 44),
            children: [
              _greeting(me, group, partner),
              const SizedBox(height: 26),

              _pokeTile(partner),
              if (_poked) ...[
                const SizedBox(height: 14),
                const Center(child: CpSpeechSlip('콕! 신호를 보냈어요 👉')),
              ],
              const SizedBox(height: 16),

              _sendTile(),
              const SizedBox(height: 34),

              const CpSectionHeader(eyebrow: '방금 도착', title: '최근 받은 낙서'),
              const SizedBox(height: 14),
              _receivedCard(received),
              const SizedBox(height: 34),

              const CpSectionHeader(eyebrow: '기록', title: '최근 소통'),
              const SizedBox(height: 14),
              _log(recent),
              const SizedBox(height: 30),

              _widgetLink(),
            ],
          );
        },
      ),
    );
  }

  // -- Sections --------------------------------------------------------------

  Widget _greeting(User? me, Group? group, Member? partner) {
    final line = partner == null
        ? '상대가 들어오면 낙서를 주고받을 수 있어요'
        : '오늘도 ${_displayNameOf(partner)}와(과) 이어져 있어요';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CpEyebrow(group?.name ?? '소통'),
        const SizedBox(height: 8),
        Text(
          '${me?.displayName ?? '나'}님, 안녕하세요',
          style: cpSans(size: 24, weight: FontWeight.w600, height: 1.15),
        ),
        const SizedBox(height: 7),
        Text(line, style: cpSans(size: 13, color: cpInkA(0.55))),
      ],
    );
  }

  Widget _pokeTile(Member? partner) {
    // Promote via a final local so both the label and the closure see a
    // non-null Member (a separate bool would not promote `partner`).
    final p = partner;
    final subtitle = p != null
        ? '${_displayNameOf(p)}에게 콕 신호를 보내요'
        : '상대가 없어 콕 찌를 수 없어요';
    return _BigTile(
      glyph: '👉',
      title: '콕 찌르기',
      subtitle: subtitle,
      accent: p != null,
      onTap: p != null ? () => _poke(p) : null,
    );
  }

  Widget _sendTile() {
    return _BigTile(
      glyph: '✏️',
      title: '낙서 보내기',
      subtitle: '그림 · 사진 · 메시지를 그려서 전해요',
      onTap: () => cpPush(context, const DrawSendScreen()),
    );
  }

  Widget _receivedCard(Doodle? d) {
    if (d == null) {
      return CpMatted(
        mat: 16,
        inset: 20,
        child: Center(
          child: Text(
            '아직 받은 낙서가 없어요',
            style: cpSans(size: 13, color: cpInkA(0.5)),
          ),
        ),
      );
    }

    final ephemeral = d.mode == SendMode.ephemeral;
    return GestureDetector(
      onTap: () => _openViewer(d),
      behavior: HitTestBehavior.opaque,
      child: CpMatted(
        mat: 16,
        inset: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CpDoodleThumb(d, size: 60, active: !d.viewedByMe),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _senderName(d.senderId),
                          overflow: TextOverflow.ellipsis,
                          style: cpSans(size: 15, weight: FontWeight.w600),
                        ),
                      ),
                      if (!d.viewedByMe) ...[
                        const SizedBox(width: 8),
                        _dot(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _preview(d),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 13, color: cpInkA(0.62), height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _stamp(d.createdAt),
                        style: cpSans(size: 11, color: cpInkA(0.42)),
                      ),
                      if (ephemeral) ...[
                        const SizedBox(width: 8),
                        _tag(
                          _isExpiring(d) ? '사라지는 중' : '확인하면 사라져요',
                          accent: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cpInkA(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _log(List<Doodle> items) {
    if (items.isEmpty) {
      return const CpEmptyState(
        icon: Icons.forum_outlined,
        text: '주고받은 낙서가 여기 쌓여요',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _logRow(items[i]),
          if (i != items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: CpHair(opacity: 0.08),
            ),
        ],
      ],
    );
  }

  Widget _logRow(Doodle d) {
    final mine = _isMine(d);
    return GestureDetector(
      onTap: () => _openViewer(d),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CpDoodleThumb(d, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _tag(mine ? '보냄' : '받음', accent: !mine),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          mine ? '나' : _senderName(d.senderId),
                          overflow: TextOverflow.ellipsis,
                          style: cpSans(size: 13, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _preview(d),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 12, color: cpInkA(0.55)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _stamp(d.createdAt),
              style: cpSans(size: 10, color: cpInkA(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _widgetLink() {
    return GestureDetector(
      onTap: () => cpPush(context, const WidgetPreviewScreen()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: cpInkA(0.14), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.widgets_outlined, size: 18, color: cpInkA(0.55)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '홈 위젯 미리보기',
                    style: cpSans(size: 13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '잠금화면에 뜰 최근 낙서를 확인해요',
                    style: cpSans(size: 11, color: cpInkA(0.5)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: cpInkA(0.3)),
          ],
        ),
      ),
    );
  }

  // -- Small private primitives ---------------------------------------------

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: cpEuc, shape: BoxShape.circle),
      );

  Widget _tag(String text, {bool accent = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: accent ? cpEucA(0.12) : cpDim,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: accent ? cpEucA(0.5) : cpInkA(0.10),
            width: 0.5,
          ),
        ),
        child: Text(
          text.toUpperCase(),
          style: cpSans(
            size: 9,
            color: accent ? cpEuc : cpInkA(0.55),
            weight: FontWeight.w600,
            spacing: 1.2,
          ),
        ),
      );
}

// ===========================================================================
// _BigTile — a full-width matted action (poke / send).
// ===========================================================================

/// A large tappable matted row: a glyph tile, a title + subtitle, and a chevron.
/// [accent] warms the mat to eucalyptus; a null [onTap] renders it disabled.
class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final String glyph;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final tile = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: CpMatted(
        mat: 16,
        inset: 16,
        matColor: accent ? cpEucA(0.10) : cpPrint,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent ? cpEucA(0.16) : cpMist,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: accent ? cpEucA(0.5) : cpInkA(0.12),
                  width: 0.5,
                ),
              ),
              child: Text(glyph, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cpSans(size: 16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: cpSans(size: 12, color: cpInkA(0.55), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cpInkA(0.3)),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}
