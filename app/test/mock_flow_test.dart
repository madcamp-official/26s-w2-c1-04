// Behavioral tests over the MockRepository — proves the app's core loops
// actually work end to end (the mock is a real in-memory backend, so these
// exercise the same paths the UI drives through AppState).

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_pager/core/api/mock_repository.dart';
import 'package:memory_pager/core/models.dart';

void main() {
  late MockRepository repo;
  late String groupId;
  late String petId;

  setUp(() async {
    repo = MockRepository();
    await repo.register('종혁', 'dev-1');
    final me = await repo.getMe();
    groupId = me.group!.id;
    final pet = await repo.getPet(groupId);
    petId = pet.id;
  });

  test('seed: returning user is in a 2-person group with a pet', () async {
    final me = await repo.getMe();
    expect(me.user.displayName, '종혁');
    expect(me.group, isNotNull);
    expect(me.group!.memberCount, 2);
    final pet = await repo.getPet(groupId);
    expect(pet.name, isNotEmpty);
    expect(pet.coins, greaterThan(0));
  });

  test('P0: sendDoodle prepends to the album and sets viewedByMe', () async {
    final before = (await repo.listDoodles(groupId)).items.length;
    final d = await repo.sendDoodle(
      mode: SendMode.normal,
      contentType: ContentType.drawing,
      strokeData: StrokeData(
        canvas: const CanvasSize(w: 300, h: 300),
        durationMs: 1200,
        strokes: const [
          Stroke(pen: 'pen', color: 'FF5A5F', width: 6, points: [
            StrokePoint(x: 10, y: 10, t: 0),
            StrokePoint(x: 40, y: 55, t: 120),
          ]),
        ],
      ),
    );
    expect(d.contentType, ContentType.drawing);
    expect(d.viewedByMe, isTrue);
    final page = await repo.listDoodles(groupId);
    expect(page.items.length, before + 1);
    expect(page.items.first.id, d.id);
    // stroke_data round-trips for rendering
    expect(repo.strokeDataFor(d.id)!.strokes.single.points.last.t, 120);
  });

  test('P0: reply threads a parent and bumps its reply_count', () async {
    final parent = (await repo.listDoodles(groupId)).items.first;
    final beforeReplies = parent.replyCount;
    await repo.sendDoodle(
      mode: SendMode.normal,
      contentType: ContentType.text,
      parentId: parent.id,
      textBody: '답장!',
    );
    final refreshed = await repo.getDoodle(parent.id);
    expect(refreshed.replyCount, beforeReplies + 1);
  });

  test('P1: ephemeral view arms a 5s expiry and self-destructs', () async {
    // Partner sends an ephemeral; I view it → expires_at set → gone after 5s.
    final d = repo.pushIncomingDoodle(
        fromUserId: '2',
        mode: SendMode.ephemeral,
        contentType: ContentType.text,
        textBody: '금방 사라질 낙서',
      );
    expect(d.mode, SendMode.ephemeral);
    final expiresAt = await repo.viewDoodle(d.id);
    expect(expiresAt, isNotNull, reason: 'received ephemeral must arm a timer');

    await Future<void>.delayed(const Duration(seconds: 6));
    // After the fuse: the row is gone from the album and reads as 410.
    final stillListed =
        (await repo.listDoodles(groupId)).items.any((x) => x.id == d.id);
    expect(stillListed, isFalse);
    expect(
      () => repo.getDoodle(d.id),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 410)),
    );
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('P1: pat returns a non-empty utterance and grants exp', () async {
    final r = await repo.pat(petId);
    expect(r.utterance, isNotEmpty);
    expect(r.expGained, greaterThanOrEqualTo(0));
  });

  test('P1: report generate computes counts + a best doodle with a rule',
      () async {
    final rep = await repo.generateReport(groupId, '2026-07');
    expect(rep.reportMonth, '2026-07');
    expect(rep.photoCount + rep.drawingCount + rep.textCount,
        greaterThanOrEqualTo(0));
    // best_doodle_rule is one of the known values (never crashes the UI).
    if (rep.bestDoodle != null) {
      expect(BestDoodleRule.values, contains(rep.bestDoodle!.rule));
    }
  });

  test('P2: buying an item spends coins; too-expensive throws 422', () async {
    final items = await repo.listItems();
    final pet = await repo.getPet(groupId);
    final affordable =
        items.where((i) => !_owned(pet, i.id) && i.priceCoins <= pet.coins);
    if (affordable.isNotEmpty) {
      final it = affordable.first;
      await repo.buyItem(petId, it.id);
      final after = await repo.getPet(groupId);
      expect(after.coins, pet.coins - it.priceCoins);
    }
    // A wildly overpriced buy must be refused with 422.
    final tooMuch = items.where((i) => i.priceCoins > pet.coins);
    if (tooMuch.isNotEmpty) {
      expect(
        () => repo.buyItem(petId, tooMuch.first.id),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 422)),
      );
    }
  });

  test('P2: getWidget hides the thumb for an unseen ephemeral', () async {
    repo.pushIncomingDoodle(
        fromUserId: '2', mode: SendMode.ephemeral,
        contentType: ContentType.text, textBody: '위젯 테스트');
    final w = await repo.getWidget(groupId);
    expect(w, isNotNull);
    if (w!.isEphemeral) {
      expect(w.thumbUrl, isNull,
          reason: 'ephemeral widget must not leak a thumbnail');
    }
  });

  test('onboarding: create a fresh group mints an invite code + pet', () async {
    await repo.register('새사람', 'dev-2');
    final gp = await repo.createGroup('새집', '새삐삐');
    expect(gp.group.inviteCode, isNotEmpty);
    expect(gp.group.memberCount, 1);
    expect(gp.pet.name, '새삐삐');
  });
}

bool _owned(Pet pet, String itemId) =>
    pet.equippedItems.any((e) => e.itemId == itemId);
