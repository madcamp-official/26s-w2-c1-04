// Memory Pager — Poke ('콕 찌르기').
//
// A small, calm auxiliary screen: send a poke to the partner (`appState.poke`)
// and reflect the send + the partner's poke-back with a quiet ripple. CommHome
// already carries the primary poke affordance, so this is deliberately minimal —
// one focal tap target, honest status, no invented data.
//
// The poke-back is the partner poking me: it surfaces as a
// `NotificationKind.pokeReceived` entry pushed onto `appState.notifications` by
// the realtime layer (~2s after I poke, in the mock). This screen is pushed
// full-screen over the AppShell — hiding the shell's own banner — so it watches
// `appState.notifications` directly and animates the return in place.
//
// Determinism: no DateTime.now(), no Random. Timestamps/scheduling are owned by
// AppState/realtime; this screen only renders animation progress.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

/// Public entry (route target). Kept a [StatelessWidget] with the stub's exact
/// constructor; all real work lives in the private [_PokeBody].
class PokeScreen extends StatelessWidget {
  const PokeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '콕 찌르기',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: const _PokeBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// State machine
// ---------------------------------------------------------------------------

enum _PokePhase { idle, sending, sent, returned, error }

class _PokeBody extends StatefulWidget {
  const _PokeBody();

  @override
  State<_PokeBody> createState() => _PokeBodyState();
}

class _PokeBodyState extends State<_PokeBody> with TickerProviderStateMixin {
  // Outbound/inbound ripple (one controller, direction chosen by [_inbound]).
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  // Gentle press-in nudge on the button.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  _PokePhase _phase = _PokePhase.idle;
  bool _inbound = false;
  String? _errorMsg;

  /// pokeReceived notification ids that existed when I last sent — so the *new*
  /// poke-back can be told apart from any already sitting in the queue.
  Set<String> _knownPokeIds = <String>{};

  @override
  void initState() {
    super.initState();
    appState.addListener(_onState);
  }

  @override
  void dispose() {
    appState.removeListener(_onState);
    _ripple.dispose();
    _press.dispose();
    super.dispose();
  }

  // -- Partner resolution ----------------------------------------------------

  /// The other member (not me). Null when there is no partner yet.
  Member? _partner() {
    final g = appState.group;
    if (g == null) return null;
    final meId = appState.me?.id;
    for (final m in g.members) {
      if (meId == null || m.userId != meId) return m;
    }
    return null;
  }

  String _name(Member m) =>
      (m.nickname != null && m.nickname!.isNotEmpty) ? m.nickname! : m.displayName;

  // -- Poke-back detection ---------------------------------------------------

  void _onState() {
    if (!mounted || _phase != _PokePhase.sent) return;
    final partnerId = _partner()?.userId;
    if (partnerId == null) return;
    for (final n in appState.notifications) {
      if (n.kind == NotificationKind.pokeReceived &&
          n.fromUserId == partnerId &&
          !_knownPokeIds.contains(n.id)) {
        _knownPokeIds.add(n.id);
        setState(() {
          _phase = _PokePhase.returned;
          _inbound = true;
        });
        _ripple.forward(from: 0);
        return;
      }
    }
  }

  // -- Send ------------------------------------------------------------------

  Future<void> _sendPoke() async {
    final partner = _partner();
    if (partner == null || _phase == _PokePhase.sending) return;

    // Snapshot existing poke-backs so we only react to a fresh one.
    _knownPokeIds = appState.notifications
        .where((n) => n.kind == NotificationKind.pokeReceived)
        .map((n) => n.id)
        .toSet();

    setState(() {
      _phase = _PokePhase.sending;
      _inbound = false;
      _errorMsg = null;
    });
    _nudge();
    _ripple.forward(from: 0);

    try {
      await appState.poke(partner.userId); // REST is truth; await then reflect.
      if (!mounted) return;
      setState(() => _phase = _PokePhase.sent);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _PokePhase.error;
        _errorMsg = _errorLine(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _PokePhase.error;
        _errorMsg = '콕 찌르기를 보내지 못했어요';
      });
    }
  }

  void _nudge() {
    _press.forward(from: 0).whenComplete(() {
      if (mounted) _press.reverse();
    });
  }

  String _errorLine(ApiException e) {
    switch (e.status) {
      case 404:
        return '상대를 찾을 수 없어요';
      default:
        return '콕 찌르기를 보내지 못했어요';
    }
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final partner = _partner();
        if (partner == null) {
          return const Center(
            child: CpEmptyState(
              icon: Icons.person_outline,
              text: '아직 상대가 없어요\n짝이 들어오면 콕 찔러볼 수 있어요',
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CpEyebrow('가벼운 안부'),
                      const SizedBox(height: 14),
                      Text(
                        _name(partner),
                        style: cpSans(size: 26, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '가볍게 콕 찔러 안부를 전해요',
                        style: cpSans(size: 13, color: cpInkA(0.5), spacing: 0.4),
                      ),
                      const SizedBox(height: 44),
                      _pokePad(),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 96,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: KeyedSubtree(
                              key: ValueKey(_phase),
                              child: _status(partner),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '소통 홈에서도 콕 찌를 수 있어요',
                        style: cpSans(size: 11, color: cpInkA(0.32), spacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -- The focal tap target --------------------------------------------------

  Widget _pokePad() {
    final busy = _phase == _PokePhase.sending;
    final warm = _phase == _PokePhase.sending ||
        _phase == _PokePhase.sent ||
        _phase == _PokePhase.returned;
    return CpMatted(
      mat: 24,
      child: SizedBox(
        width: 208,
        height: 208,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ripple,
                builder: (context, _) => CustomPaint(
                  painter: _CpPokeRipplePainter(
                    progress: _ripple.value,
                    inbound: _inbound,
                    color: _inbound ? cpInk : cpEuc,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: busy ? null : _sendPoke,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _press,
                builder: (context, child) =>
                    Transform.scale(scale: 1 - _press.value * 0.06, child: child),
                child: Container(
                  width: 116,
                  height: 116,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: warm ? cpEucA(0.10) : cpPrint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: warm ? cpEucA(0.6) : cpInkA(0.12),
                      width: 1.2,
                    ),
                  ),
                  // A soft line heart that fills warm on a poke — the pastel focal
                  // glyph (Material outlined/filled vector icon, never an emoji).
                  child: Icon(
                    warm ? Icons.favorite : Icons.favorite_border,
                    size: 44,
                    color: warm ? cpEuc : cpInkA(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Status area (calm, honest per phase) ----------------------------------

  Widget _status(Member partner) {
    switch (_phase) {
      case _PokePhase.returned:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CpSpeechSlip('${_name(partner)}님이 콕 되받았어요'),
            const SizedBox(height: 12),
            Text(
              '또 콕 찔러볼까요?',
              style: cpSans(size: 12, color: cpInkA(0.5), spacing: 0.4),
            ),
          ],
        );
      case _PokePhase.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMsg ?? '보내지 못했어요',
              textAlign: TextAlign.center,
              style: cpSans(size: 13, color: cpInkA(0.6)),
            ),
            const SizedBox(height: 14),
            CpPrimaryButton(label: '다시 시도', onTap: _sendPoke, filled: false),
          ],
        );
      case _PokePhase.sending:
        return _caption('보내는 중…');
      case _PokePhase.sent:
        return _caption('콕! 보냈어요 · 답을 기다리는 중');
      case _PokePhase.idle:
        return _caption('버튼을 눌러 콕 찔러보세요');
    }
  }

  Widget _caption(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: cpSans(size: 13, color: cpInkA(0.55), spacing: 0.3),
      );
}

// ---------------------------------------------------------------------------
// Ripple — a hairline concentric ring that expands out (sent) or draws in
// (poke-back), then fades. The single quiet flourish; nothing loud.
// ---------------------------------------------------------------------------

class _CpPokeRipplePainter extends CustomPainter {
  const _CpPokeRipplePainter({
    required this.progress,
    required this.inbound,
    required this.color,
  });

  final double progress; // 0..1
  final bool inbound;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    const minR = 62.0; // just outside the 116px button

    for (var i = 0; i < 2; i++) {
      final p = (progress - i * 0.16).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final eased = Curves.easeOut.transform(p);
      final t = inbound ? (1 - eased) : eased; // in: shrink toward the button
      final r = minR + (maxR - minR) * t;
      final opacity = (1 - p) * 0.5;
      if (opacity <= 0) continue;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..isAntiAlias = true
          ..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CpPokeRipplePainter old) =>
      old.progress != progress ||
      old.inbound != inbound ||
      old.color != color;
}
