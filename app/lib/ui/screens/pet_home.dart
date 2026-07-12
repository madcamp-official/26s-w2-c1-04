// Memory Pager — Home (tab 0 · '홈').
//
// The couple's desk, not a nursery: ONE no-scroll screen where the RECEIVED
// LETTER is the hero object and the pet is a small companion beside it.
//
//   top bar     coins · serif wordmark · bell · poke
//   couple      상대 ♥ 나 (serif, small — no D-day per frontend.md D2)
//   LETTER      the partner's newest doodle, shown BIG like a letter/polaroid
//               (real strokes/photo/text; sealed face for unopened ephemeral;
//               an honest quiet placeholder when nothing has arrived)
//   turn line   내가 보낼 차례 / 답장을 기다리는 중 — derived from the album
//   pet         small hand-drawn companion (tap to pat, handwriting bubble)
//   CTA         "○○에게 마음 그리기"
//
// Renders inside the app shell's IndexedStack — no bottom nav here. State is
// the global [appState]; REST stays the truth. No emoji anywhere.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../charlab/toolkit.dart';
import '../../core/api/mock_repository.dart';
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
// Body — pat interaction, poke, and the no-scroll letter-first layout
// ===========================================================================

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  int _patSeq = 0;
  bool _pressed = false;

  Future<void> _pat() async {
    if (appState.pet == null) return;
    try {
      await appState.pat();
      if (!mounted) return;
      setState(() => _patSeq++);
    } on ApiException catch (_) {
      // Contract edge: stay quiet, invent no reply.
    } on StateError catch (_) {
      // Pet vanished between guard and call — no-op.
    }
  }

  Future<void> _poke(Member partner) async {
    try {
      await appState.poke(partner.userId);
      if (!mounted) return;
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
              '콕, 마음을 보냈어요',
              textAlign: TextAlign.center,
              style: cpSans(size: 13, weight: FontWeight.w500),
            ),
          ),
        );
    } catch (_) {
      // Best-effort; a failure just skips the confirmation.
    }
  }

  Member? _partnerOf(Group? g, User? me) {
    if (g == null || me == null) return null;
    for (final m in g.members) {
      if (m.userId != me.id) return m;
    }
    return null;
  }

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
        final partnerName =
            partner == null ? null : (partner.nickname ?? partner.displayName);
        final myName = me?.displayName ?? '나';

        final activity =
            appState.currentActivity ?? pet.currentActivity?.activity;
        final utterance = appState.currentUtterance;

        // Newest doodle the partner sent (album is newest-first). Honestly
        // null when nothing has arrived — never a stand-in.
        Doodle? received;
        for (final d in appState.album) {
          if (me == null || d.senderId != me.id) {
            received = d;
            break;
          }
        }

        final p = partner;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                coins: pet.coins,
                onPoke: p == null ? null : () => _poke(p),
              ),
              const SizedBox(height: 14),
              _CoupleLine(partnerName: partnerName, myName: myName),
              const SizedBox(height: 16),
              // ---- the hero: the received letter --------------------------
              Expanded(
                child: _LetterHero(
                  received: received,
                  senderName: partnerName ?? '상대',
                ),
              ),
              const SizedBox(height: 12),
              _TurnLine(myId: me?.id, partnerName: partnerName),
              const SizedBox(height: 14),
              // ---- the small companion ------------------------------------
              _PetCompanion(
                speciesId: appState.petSpecies,
                expression: expressionForActivity(activity),
                equippedItemIds: [
                  for (final e in pet.equippedItems) e.itemId,
                ],
                utterance: utterance,
                seq: _patSeq,
                pressed: _pressed,
                onPat: _pat,
                onPressChanged: (v) => setState(() => _pressed = v),
              ),
              const SizedBox(height: 14),
              CpPrimaryButton(
                label: partnerName == null
                    ? '마음 그리기'
                    : '$partnerName에게 마음 그리기',
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
// Top bar — coins · wordmark · bell · poke
// ===========================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({required this.coins, required this.onPoke});

  final int coins;
  final VoidCallback? onPoke;

  @override
  Widget build(BuildContext context) {
    final hasNotif = appState.notifications.isNotEmpty;
    final pokeEnabled = onPoke != null;
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The serif wordmark, centered like Sumone's.
          Text('Memory Pager', style: cpSerif(size: 19, color: cpInkA(0.85))),
          Row(
            children: [
              CpCoins(coins),
              const Spacer(),
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
              const SizedBox(width: 8),
              Opacity(
                opacity: pokeEnabled ? 1 : 0.4,
                child: CpIconButton(
                  icon: Icons.touch_app_outlined,
                  onTap: onPoke ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Couple line — 상대 ♥ 나, in a quiet serif (no D-day)
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
        style: cpSans(size: 13, color: cpInkA(0.5)),
      );
    }
    final nameStyle =
        cpSerif(size: 15, style: FontStyle.normal, weight: FontWeight.w600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            partnerName!,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Icon(Icons.favorite, size: 11, color: cpEucA(0.85)),
        ),
        Flexible(
          child: Text(myName, overflow: TextOverflow.ellipsis, style: nameStyle),
        ),
      ],
    );
  }
}

// ===========================================================================
// Letter hero — the partner's newest doodle, big, like a kept letter
// ===========================================================================

class _LetterHero extends StatelessWidget {
  const _LetterHero({required this.received, required this.senderName});

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
    if (d == null) return const _NoLetterYet();

    final sealed = d.mode == SendMode.ephemeral && !d.viewedByMe;
    final unread = !d.viewedByMe;

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openViewer(context, d),
        // The letter leans a hair, like something pinned to a desk.
        child: Transform.rotate(
          angle: -0.012,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: cpPrint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cpInkA(0.08)),
              boxShadow: [
                BoxShadow(
                  color: cpInkA(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: sealed ? const _SealedFace() : _LetterFace(d: d),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sealed
                            ? '$senderName의 사라지는 편지'
                            : '$senderName의 편지',
                        overflow: TextOverflow.ellipsis,
                        style: cpHand(size: 18, color: cpInkA(0.8)),
                      ),
                    ),
                    Text(
                      _stamp(d.createdAt),
                      style: cpSans(size: 10.5, color: cpInkA(0.4)),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      const _Dot(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The letter's face — the doodle's REAL content (strokes / photo / text).
class _LetterFace extends StatelessWidget {
  const _LetterFace({required this.d});

  final Doodle d;

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final StrokeData? strokes =
        repo is MockRepository ? repo.strokeDataFor(d.id) : null;
    final Uint8List? photo =
        repo is MockRepository ? repo.photoBytesFor(d.id) : null;

    final layers = <Widget>[Container(color: cpMist)];
    if (photo != null) {
      layers.add(Positioned.fill(child: Image.memory(photo, fit: BoxFit.cover)));
    }
    if (strokes != null && strokes.strokes.isNotEmpty) {
      layers.add(Positioned.fill(
        child: CustomPaint(painter: CpDoodlePainter(strokes)),
      ));
    }
    if (photo == null && (strokes == null || strokes.strokes.isEmpty)) {
      // Text letter — the words, in handwriting, centered on paper.
      layers.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              (d.textBody ?? '').isEmpty ? '···' : d.textBody!,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: cpHand(size: 24, color: cpInkA(0.85)),
            ),
          ),
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: layers);
  }
}

/// An unopened ephemeral letter — sealed; opening it starts the 5s fuse.
class _SealedFace extends StatelessWidget {
  const _SealedFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cpDim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_lock_outlined, size: 30, color: cpInkA(0.5)),
            const SizedBox(height: 8),
            Text(
              '열어보면 5초 뒤 사라져요',
              style: cpHand(size: 17, color: cpInkA(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Honest empty state — a quiet paper card, never a faked letter.
class _NoLetterYet extends StatelessWidget {
  const _NoLetterYet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: BoxDecoration(
          color: cpPrint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cpInkA(0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 26, color: cpInkA(0.35)),
            const SizedBox(height: 10),
            Text(
              '아직 도착한 편지가 없어요',
              style: cpHand(size: 18, color: cpInkA(0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Turn line — whose move it is, read honestly off the album
// ===========================================================================

class _TurnLine extends StatelessWidget {
  const _TurnLine({required this.myId, required this.partnerName});

  final String? myId;
  final String? partnerName;

  @override
  Widget build(BuildContext context) {
    final album = appState.album;
    final String text;
    if (partnerName == null) {
      text = '초대 코드를 보내 상대를 기다려요';
    } else if (album.isEmpty) {
      text = '먼저 마음을 그려 보내볼까요?';
    } else if (myId != null && album.first.senderId == myId) {
      text = '$partnerName의 답장을 기다리는 중이에요';
    } else {
      text = '내가 답장할 차례예요';
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: cpSans(size: 12.5, color: cpInkA(0.48)),
    );
  }
}

// ===========================================================================
// Pet companion — small, beside its handwriting bubble (tap to pat)
// ===========================================================================

class _PetCompanion extends StatelessWidget {
  const _PetCompanion({
    required this.speciesId,
    required this.expression,
    required this.equippedItemIds,
    required this.utterance,
    required this.seq,
    required this.pressed,
    required this.onPat,
    required this.onPressChanged,
  });

  final String speciesId;
  final PetExpression expression;
  final List<String> equippedItemIds;
  final String? utterance;
  final int seq;
  final bool pressed;
  final Future<void> Function() onPat;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    final bubble = (utterance != null && utterance!.isNotEmpty)
        ? Container(
            key: ValueKey('u/$seq/$utterance'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: cpPrint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cpEucA(0.35)),
            ),
            child: Text(
              utterance!,
              style: cpHand(size: 17, color: cpInkA(0.8)),
            ),
          )
        : Text(
            key: const ValueKey('prompt'),
            '쓰다듬으면 인사해요',
            style: cpHand(size: 16, color: cpInkA(0.4)),
          );

    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPat,
          onTapDown: (_) => onPressChanged(true),
          onTapUp: (_) => onPressChanged(false),
          onTapCancel: () => onPressChanged(false),
          child: AnimatedScale(
            scale: pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PetView(
                  speciesId: speciesId,
                  size: 104,
                  expression: expression,
                  equippedItemIds: equippedItemIds,
                ),
                // A single soft ground shadow — the whole "room".
                Container(
                  width: 56,
                  height: 6,
                  decoration: BoxDecoration(
                    color: cpInkA(0.06),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: bubble,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Small primitives / helpers
// ===========================================================================

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

String _two(int n) => n < 10 ? '0$n' : '$n';

String _stamp(DateTime utc) {
  final t = utc.toLocal();
  return '${t.month}/${t.day} ${_two(t.hour)}:${_two(t.minute)}';
}
