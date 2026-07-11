// Memory Pager — Home (tab 0 · '홈').
//
// The Sumone home: ONE no-scroll screen where the grim-editing loop lives up
// front and the pet is the calm companion at its center. Top→bottom: a quiet
// top bar (coins · bell · poke), the couple line "상대  나" (no D-day), a
// 받은 편지 indicator, the pet sitting inside a soft hand-drawn room (E4's
// house-behind-pet, tap to pat), and a prominent "…와 함께 그림 그리기" CTA.
//
// Renders inside the app shell's IndexedStack — it owns NO bottom nav and NO
// back affordance (the shell provides both). State comes from the global
// [appState]; every mutation goes through an [appState] action and REST stays
// the truth. No emoji: chrome is Material outlined line icons, the pet is the
// hand-drawn [PetView], the room is painted with tokens.

import 'package:flutter/material.dart';

import '../../charlab/toolkit.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../pet_view.dart';
import '../theme.dart';
import 'draw_send.dart';
import 'viewer.dart';

class PetHomeScreen extends StatelessWidget {
  const PetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CpScaffold(body: _HomeBody());
  }
}

// ===========================================================================
// Body — pat interaction, poke, and the no-scroll layout
// ===========================================================================

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  /// Bumped on every pat so the speech slip re-fades even when the pet repeats
  /// the same cached line.
  int _patSeq = 0;

  /// Quiet press feedback on the pet.
  bool _pressed = false;

  Future<void> _pat() async {
    if (appState.pet == null) return;
    try {
      await appState.pat(); // currentUtterance + exp already reflected in state
      if (!mounted) return;
      setState(() => _patSeq++);
    } on ApiException catch (_) {
      // Contract edge (e.g. 404 not_found): stay quiet, invent no reply.
    } on StateError catch (_) {
      // Pet vanished between guard and call — no-op.
    }
  }

  Future<void> _poke(Member partner) async {
    try {
      await appState.poke(partner.userId);
      if (!mounted) return;
      // The partner's poke-back arrives as the shell banner; confirm my own
      // signal quietly here.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: cpPrint,
            elevation: 4,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cpRadiusPill),
              side: BorderSide(color: cpEucA(0.4)),
            ),
            content: Text(
              '콕! 신호를 보냈어요',
              textAlign: TextAlign.center,
              style: cpSans(size: 13, weight: FontWeight.w500),
            ),
          ),
        );
    } catch (_) {
      // REST poke is best-effort; a failure just skips the confirmation.
    }
  }

  Member? _partnerOf(Group? g, User? me) {
    if (g == null || me == null) return null;
    for (final m in g.members) {
      if (m.userId != me.id) return m;
    }
    return null;
  }

  String _display(Member m) => m.nickname ?? m.displayName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pet = appState.pet;
        if (pet == null) {
          return const Center(
            child: CpEmptyState(
              icon: Icons.pets_outlined,
              text: '펫을 불러오는 중이에요',
            ),
          );
        }

        final me = appState.me;
        final group = appState.group;
        final partner = _partnerOf(group, me);
        final partnerName = partner == null ? null : _display(partner);
        final myName = me?.displayName ?? '나';

        // Prefer the socket fast-path activity; fall back to the REST snapshot.
        final activity =
            appState.currentActivity ?? pet.currentActivity?.activity;
        final utterance = appState.currentUtterance;

        // Newest doodle the partner sent (album is newest-first). Honestly null
        // when nothing has arrived — never a stand-in.
        Doodle? received;
        for (final d in appState.album) {
          if (me == null || d.senderId != me.id) {
            received = d;
            break;
          }
        }

        final p = partner;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                coins: pet.coins,
                onPoke: p == null ? null : () => _poke(p),
              ),
              const SizedBox(height: 18),
              _CoupleLine(partnerName: partnerName, myName: myName),
              const SizedBox(height: 18),
              _ReceivedLetter(
                received: received,
                senderName: partnerName ?? '상대',
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SpeechArea(utterance: utterance, seq: _patSeq),
                        const SizedBox(height: 10),
                        _HouseScene(
                          speciesId: appState.petSpecies,
                          expression: expressionForActivity(activity),
                          equippedItemIds: [
                            for (final e in pet.equippedItems) e.itemId,
                          ],
                          pressed: _pressed,
                          onPat: _pat,
                          onPressChanged: (v) => setState(() => _pressed = v),
                        ),
                        const SizedBox(height: 10),
                        CpEyebrow('탭하여 쓰다듬기', size: 10),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CpPrimaryButton(
                label: partnerName == null
                    ? '그림 그리기'
                    : '$partnerName${_particleWa(partnerName)} 함께 그림 그리기',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DrawSendScreen(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Top bar — coins · bell · poke
// ===========================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.coins, required this.onPoke});

  final int coins;
  final VoidCallback? onPoke;

  @override
  Widget build(BuildContext context) {
    final hasNotif = appState.notifications.isNotEmpty;
    final pokeEnabled = onPoke != null;
    return Row(
      children: [
        CpCoins(coins),
        const Spacer(),
        // Bell — a dot appears while banners are pending; tapping clears them.
        Stack(
          clipBehavior: Clip.none,
          children: [
            CpIconButton(
              icon: Icons.notifications_none,
              onTap: () {
                if (hasNotif) appState.clearNotifications();
              },
            ),
            if (hasNotif)
              const Positioned(right: 3, top: 3, child: _Dot()),
          ],
        ),
        const SizedBox(width: 10),
        // Poke — disabled (dimmed) when there is no partner to reach.
        Opacity(
          opacity: pokeEnabled ? 1 : 0.4,
          child: CpIconButton(
            icon: Icons.touch_app_outlined,
            onTap: onPoke ?? () {},
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Couple line — 상대  나 (no D-day)
// ===========================================================================

class _CoupleLine extends StatelessWidget {
  const _CoupleLine({required this.partnerName, required this.myName});

  final String? partnerName;
  final String myName;

  @override
  Widget build(BuildContext context) {
    if (partnerName == null) {
      return Text(
        '$myName님, 상대를 기다리는 중이에요',
        textAlign: TextAlign.center,
        style: cpSans(size: 14, color: cpInkA(0.5)),
      );
    }
    final nameStyle = cpSans(size: 16, weight: FontWeight.w600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            partnerName!,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: nameStyle,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.favorite, size: 14, color: cpEuc),
        ),
        Flexible(
          child: Text(
            myName,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: nameStyle,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Received letter — the partner's newest doodle, or a calm empty line
// ===========================================================================

class _ReceivedLetter extends StatelessWidget {
  const _ReceivedLetter({required this.received, required this.senderName});

  final Doodle? received;
  final String senderName;

  void _openViewer(BuildContext context, Doodle d) {
    final idx = appState.album.indexWhere((x) => x.id == d.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewerScreen(initialIndex: idx < 0 ? 0 : idx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = received;
    if (d == null) {
      // Honest empty state — a quiet line, never a faked letter.
      return Text(
        '아직 받은 편지가 없어요',
        textAlign: TextAlign.center,
        style: cpSans(size: 12.5, color: cpInkA(0.42)),
      );
    }
    final unread = !d.viewedByMe;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openViewer(context, d),
      child: CpMatted(
        mat: 14,
        matColor: cpEucA(0.10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cpPrint,
                shape: BoxShape.circle,
                border: Border.all(color: cpEucA(0.3)),
              ),
              child: const Icon(Icons.mail_outline, size: 20, color: cpEuc),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$senderName에게서 편지가 왔어요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 13.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    unread ? '아직 확인하지 않았어요' : '편지를 확인했어요',
                    style: cpSans(size: 11.5, color: cpInkA(0.5)),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              const _Dot(),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cpEucA(0.6)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Speech — the pat utterance, faded via an AnimatedSwitcher
// ===========================================================================

class _SpeechArea extends StatelessWidget {
  const _SpeechArea({required this.utterance, required this.seq});

  /// The pet's current line (from a pat or a socket activity change). Null until
  /// the pet has spoken — then we honestly show a prompt, not a fake line.
  final String? utterance;
  final int seq;

  @override
  Widget build(BuildContext context) {
    final Widget child = (utterance != null && utterance!.isNotEmpty)
        ? CpSpeechSlip(utterance!, key: ValueKey('slip/$seq/$utterance'))
        : Padding(
            key: const ValueKey('prompt'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '펫을 쓰다듬어 인사를 나눠보세요',
              textAlign: TextAlign.center,
              style: cpSans(size: 13, color: cpInkA(0.4)),
            ),
          );

    return SizedBox(
      height: 56,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        ),
      ),
    );
  }
}

// ===========================================================================
// House scene — the pet sitting inside a soft hand-drawn room (E4)
// ===========================================================================

class _HouseScene extends StatelessWidget {
  const _HouseScene({
    required this.speciesId,
    required this.expression,
    required this.equippedItemIds,
    required this.pressed,
    required this.onPat,
    required this.onPressChanged,
  });

  final String speciesId;
  final PetExpression expression;
  final List<String> equippedItemIds;
  final bool pressed;
  final Future<void> Function() onPat;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPat,
      onTapDown: (_) => onPressChanged(true),
      onTapUp: (_) => onPressChanged(false),
      onTapCancel: () => onPressChanged(false),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 300,
          height: 250,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _RoomPainter()),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 34),
                child: PetView(
                  speciesId: speciesId,
                  size: 168,
                  expression: expression,
                  equippedItemIds: equippedItemIds,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a cozy warm room behind the pet: a soft rounded back wall, a warmer
/// floor band with a hairline, a simple window, and a gentle rug under the pet.
/// All warm tokens, no emoji — this is E4's house-behind-pet.
class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final room = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.10, w * 0.88, h * 0.82),
      const Radius.circular(28),
    );

    // Back wall.
    canvas.drawRRect(
      room,
      Paint()
        ..color = cpDim
        ..isAntiAlias = true,
    );

    // Floor band (clipped to the room), a hair warmer than the wall.
    canvas.save();
    canvas.clipRRect(room);
    final floorTop = h * 0.70;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, h),
      Paint()..color = Color.alphaBlend(cpPeach.withValues(alpha: 0.45), cpDim),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, w, 1.5),
      Paint()..color = cpInkA(0.06),
    );
    canvas.restore();

    // A simple window on the wall.
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.155, h * 0.24, w * 0.21, h * 0.24),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      window,
      Paint()..color = cpPrint.withValues(alpha: 0.6),
    );
    final line = Paint()
      ..color = cpInkA(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawRRect(window, line);
    final wc = window.outerRect.center;
    canvas.drawLine(
      Offset(wc.dx, window.top + 6),
      Offset(wc.dx, window.bottom - 6),
      line,
    );
    canvas.drawLine(
      Offset(window.left + 6, wc.dy),
      Offset(window.right - 6, wc.dy),
      line,
    );

    // A soft rug under the pet's feet.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.82),
        width: w * 0.5,
        height: h * 0.12,
      ),
      Paint()
        ..color = cpEucA(0.08)
        ..isAntiAlias = true,
    );

    // Quiet wall border.
    canvas.drawRRect(
      room,
      Paint()
        ..color = cpInkA(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => false;
}

// ===========================================================================
// Small primitives / helpers
// ===========================================================================

/// A small accent dot — the unread/pending marker (bell badge, unread letter).
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: cpEuc,
        shape: BoxShape.circle,
        border: Border.all(color: cpMist, width: 1.5),
      ),
    );
  }
}

/// The Korean subject-ish particle 와/과 for a name, by its final jamo. Keeps
/// the "…와 함께 그림 그리기" CTA reading naturally for either ending.
String _particleWa(String name) {
  if (name.isEmpty) return '와';
  final code = name.codeUnitAt(name.length - 1);
  if (code >= 0xAC00 && code <= 0xD7A3) {
    return ((code - 0xAC00) % 28 == 0) ? '와' : '과';
  }
  return '와';
}
