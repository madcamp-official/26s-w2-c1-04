// Memory Pager — in-memory backend.
//
// A [Repository] that needs NO server: every endpoint runs against seeded,
// mutable Dart state. It reproduces the *behaviours* the app depends on —
// ephemeral self-destruct with a real 5s timer, reply_count from parent_id,
// cursor pagination, best-doodle selection, coin economy, equip-within-category
// — so the whole app (onboarding, home, sending, viewer, store, explore,
// reports) can be developed and demoed offline.
//
// Determinism (per the spec for this file):
//   - NO DateTime.now(), NO Random anywhere.
//   - "now" comes from an injectable [MockClock] seeded at 2026-07-10 09:00 UTC
//     that only advances when *you* tick it. Read/expose it via [clock].
//   - IDs come from a monotonic counter, invite codes from the same counter.
//   - The one real timer is the 5s ephemeral self-destruct: it uses
//     `Future.delayed` (a runtime timer, not a forbidden clock read); the
//     deleted_at it stamps is taken from [clock], never from the wall clock.
//
// Realtime hooks: assign [onNewDoodle] / [onExpired] to bridge into a realtime
// or state layer. [onNewDoodle] fires on every created doodle (mirrors the
// server broadcasting `doodle:new` to the room — dedupe by id, since the
// sender also gets its own doodle back from [sendDoodle]). [onExpired] fires
// when a viewed ephemeral doodle self-destructs.
//
// Renderable media: the wire model [Doodle] carries only URLs, but a mock has
// no files. So sent/seeded strokes and image bytes are kept in side maps and
// exposed via [strokeDataFor] / [photoBytesFor] / [drawingBytesFor], letting a
// drawing viewer paint real vectors offline.

import 'dart:typed_data';

import '../models.dart';
import 'repository.dart';

// ---------------------------------------------------------------------------
// Deterministic clock
// ---------------------------------------------------------------------------

/// A hand-cranked clock. Nothing in [MockRepository] reads the wall clock;
/// everything reads [now]. Advance it yourself with [tick] / [advance] / [set]
/// so timestamps and any time-dependent behaviour are fully reproducible.
class MockClock {
  MockClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 7, 10, 9);

  DateTime _now;

  /// Current mock time.
  DateTime now() => _now;

  /// Jump to an absolute instant.
  void jumpTo(DateTime value) => _now = value;

  /// Advance by [d].
  void advance(Duration d) => _now = _now.add(d);

  /// Advance by one step (default 1 minute) — the ergonomic "tick".
  void tick([Duration step = const Duration(minutes: 1)]) => advance(step);

  /// A plain `DateTime Function()` view, for code that wants just the closure.
  DateTime Function() get fn => now;
}

// ---------------------------------------------------------------------------
// Private mutable rows (the wire models are immutable, so we keep our own)
// ---------------------------------------------------------------------------

class _UserRow {
  _UserRow(this.id, this.displayName);
  final String id;
  String displayName;
}

class _MemberRow {
  _MemberRow(this.userId, this.role, [this.nickname]);
  final String userId;
  MemberRole role;
  String? nickname;
}

class _GroupRow {
  _GroupRow({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.backgroundColor,
    required this.petId,
    required this.members,
  });
  final String id;
  String name;
  String inviteCode;
  String backgroundColor;
  final String petId;
  final List<_MemberRow> members;
}

class _PetRow {
  _PetRow({
    required this.id,
    required this.name,
    required this.level,
    required this.exp,
    required this.coins,
    required this.isPublic,
    this.activity,
    this.activityStartedAt,
    this.utterance,
  });
  final String id;
  String name;
  int level;
  int exp;
  int coins;
  bool isPublic;
  PetActivityKind? activity;
  DateTime? activityStartedAt;
  String? utterance;
}

class _DoodleRow {
  _DoodleRow({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.mode,
    required this.contentType,
    required this.createdAt,
    this.parentId,
    this.photoUrl,
    this.drawingUrl,
    this.textBody,
    Set<String>? viewedBy,
  }) : viewedBy = viewedBy ?? <String>{};

  final String id;
  final String groupId;
  final String senderId;
  final String? parentId;
  final SendMode mode;
  final ContentType contentType;
  final DateTime createdAt;
  String? photoUrl;
  String? drawingUrl;
  String? textBody;

  /// User ids that have a view receipt (doodle_receipts).
  final Set<String> viewedBy;
  DateTime? expiresAt;
  DateTime? deletedAt;
}

class _PetItemRow {
  _PetItemRow(this.id, this.itemId, {this.isEquipped = false});
  final String id;
  final String itemId;
  bool isEquipped;
  int? posX;
  int? posY;
}

class _ExploreRow {
  _ExploreRow({
    required this.petId,
    required this.name,
    required this.level,
    required this.moodEmoji,
    required this.likeCount,
    required this.likedByMe,
    required this.inviteCode,
  });
  final String petId;
  String name;
  int level;
  String moodEmoji;
  int likeCount;
  bool likedByMe;
  final String inviteCode;
}

class _PokeRow {
  _PokeRow(this.groupId, this.fromUserId, this.toUserId, this.at);
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final DateTime at;
}

// ---------------------------------------------------------------------------
// MockRepository
// ---------------------------------------------------------------------------

class MockRepository implements Repository {
  MockRepository({MockClock? clock}) : clock = clock ?? MockClock() {
    _seed();
  }

  /// The deterministic clock. Call `repo.clock.tick()` / `.advance(...)` to
  /// move time; nothing here reads the wall clock.
  final MockClock clock;

  /// Fired for every created doodle (own sends and [pushIncomingDoodle]).
  /// Mirrors the server's `doodle:new` room broadcast — dedupe by id.
  void Function(Doodle doodle)? onNewDoodle;

  /// Fired when a viewed ephemeral doodle self-destructs (`doodle:expired`).
  void Function(String doodleId)? onExpired;

  /// Fired when the pet levels up (`pet:levelup`). Mirrors the server's growth
  /// rule (API.md §5): exchanging letters feeds the pet.
  void Function(String petId, int level)? onLevelUp;

  // The signed-in user ("me"). The demo is 종혁 (id '1').
  static const String _meId = '1';
  static const String _token = 'mp_demo_token_1';

  final Map<String, _UserRow> _users = {};
  final Map<String, _GroupRow> _groups = {};
  final Map<String, _PetRow> _pets = {};
  final Map<String, _DoodleRow> _doodles = {};
  final Map<String, List<Diary>> _diaries = {}; // petId -> diaries
  final Map<String, List<_PetItemRow>> _inventory = {}; // petId -> owned items
  final List<Item> _catalog = [];
  final Map<String, Item> _catalogById = {};
  final List<_ExploreRow> _explore = [];
  final List<_PokeRow> _pokes = [];
  final Map<String, MonthlyReport> _reports = {}; // month -> report
  final Map<String, DateTime> _reportGeneratedAt = {}; // month -> generated_at

  // Renderable side channels (mock has no real media files).
  final Map<String, StrokeData> _strokeData = {}; // doodleId -> strokes
  final Map<String, Uint8List> _photoBytes = {};
  final Map<String, Uint8List> _drawingBytes = {};

  String _currentGroupId = '7';
  String? _registeredDeviceUid;
  int _idCounter = 900; // stays clear of seeded ids (1,2,3,7,40s,80x)
  int _inviteCounter = 1;

  String _nextId() => (_idCounter++).toString();
  String _nextInviteCode() => 'INV${(_inviteCounter++).toString().padLeft(5, '0')}';

  DateTime _now() => clock.now();

  // -- Error helpers --------------------------------------------------------

  ApiException _err(int status, String code, String message) =>
      ApiException(ApiError(code: code, message: message), status);

  // ===========================================================================
  // Seed
  // ===========================================================================

  void _seed() {
    // Users.
    _users['1'] = _UserRow('1', '종혁');
    _users['2'] = _UserRow('2', '지민');

    // Group '우리집' (2 members, full). 지민's nickname (given by 종혁) is '토리'.
    _groups['7'] = _GroupRow(
      id: '7',
      name: '우리집',
      inviteCode: 'LOVE8213',
      backgroundColor: 'FFE4E1',
      petId: '3',
      members: [
        _MemberRow('1', MemberRole.owner),
        _MemberRow('2', MemberRole.member, '토리'),
      ],
    );

    // Pet '삐삐': level 4, exp 320, coins 150, currently sleeping.
    _pets['3'] = _PetRow(
      id: '3',
      name: '삐삐',
      level: 4,
      exp: 320,
      coins: 150,
      isPublic: true,
      activity: PetActivityKind.sleeping,
      activityStartedAt: DateTime.utc(2026, 7, 10, 8, 40),
      utterance: '방금 밥 먹고 졸려… 그림 잘 봤어!',
    );

    // Store catalog: hats / clothes / furniture / props.
    _addItem('11', ItemCategory.hat, '밀짚모자', 30);
    _addItem('12', ItemCategory.hat, '파티모자', 50);
    _addItem('21', ItemCategory.clothes, '노란 우비', 40);
    _addItem('22', ItemCategory.clothes, '줄무늬 티', 35);
    _addItem('31', ItemCategory.furniture, '아늑한 방석', 60);
    _addItem('32', ItemCategory.furniture, '미니 책상', 80);
    _addItem('41', ItemCategory.prop, '빨간 공', 20);
    _addItem('42', ItemCategory.prop, '나비넥타이', 25);

    // 삐삐 owns a couple of things but wears none — the pet greets you bare;
    // dressing up is the couple's choice, not a default costume.
    _inventory['3'] = [
      _PetItemRow(_nextId(), '12', isEquipped: false),
      _PetItemRow(_nextId(), '41', isEquipped: false),
    ];

    _seedDoodles();
    _seedDiaries();
    _seedExplore();
    _seedJuneReport();
  }

  void _addItem(String id, ItemCategory cat, String name, int price) {
    final assetKey = _assetKeyFor(cat);
    final item = Item(
      id: id,
      category: cat,
      name: name,
      priceCoins: price,
      assetUrl: '/media/items/${assetKey}_$id.png',
    );
    _catalog.add(item);
    _catalogById[id] = item;
  }

  String _assetKeyFor(ItemCategory c) {
    switch (c) {
      case ItemCategory.hat:
        return 'hat';
      case ItemCategory.clothes:
        return 'clothes';
      case ItemCategory.furniture:
        return 'furniture';
      case ItemCategory.accessory:
        return 'accessory';
      case ItemCategory.background:
        return 'background';
      case ItemCategory.prop:
        return 'prop';
    }
  }

  void _seedDoodles() {
    // ~8 doodles across types/dates. Some carry real StrokeData so the drawing
    // viewer can render vectors with no server. Replies set parent_id so
    // reply_count is computed, not stored.
    void add(_DoodleRow r, {StrokeData? strokes}) {
      _doodles[r.id] = r;
      if (strokes != null) _strokeData[r.id] = strokes;
    }

    add(_DoodleRow(
      id: '800',
      groupId: '7',
      senderId: '2',
      mode: SendMode.normal,
      contentType: ContentType.photo,
      createdAt: DateTime.utc(2026, 7, 8, 9, 10),
      photoUrl: '/media/g7/800_photo.jpg',
      viewedBy: {'1', '2'},
    ));

    add(
      _DoodleRow(
        id: '801',
        groupId: '7',
        senderId: '1',
        mode: SendMode.normal,
        contentType: ContentType.drawing,
        createdAt: DateTime.utc(2026, 7, 8, 12, 30),
        drawingUrl: '/media/g7/801_draw.png',
        viewedBy: {'1'},
      ),
      strokes: _heartStrokes(),
    );

    add(_DoodleRow(
      id: '802',
      groupId: '7',
      senderId: '2',
      mode: SendMode.normal,
      contentType: ContentType.text,
      createdAt: DateTime.utc(2026, 7, 8, 20, 0),
      textBody: '오늘 저녁 맛있었어!',
      viewedBy: {'1', '2'},
    ));

    add(
      _DoodleRow(
        id: '803',
        groupId: '7',
        senderId: '1',
        mode: SendMode.normal,
        contentType: ContentType.drawing,
        createdAt: DateTime.utc(2026, 7, 9, 8, 15),
        drawingUrl: '/media/g7/803_draw.png',
        viewedBy: {'1', '2'},
      ),
      strokes: _scribbleStrokes(),
    );

    // Reply to 803 -> gives 803 a reply_count of 1.
    add(_DoodleRow(
      id: '804',
      groupId: '7',
      senderId: '2',
      mode: SendMode.normal,
      contentType: ContentType.text,
      createdAt: DateTime.utc(2026, 7, 9, 8, 40),
      textBody: '그림 완전 귀엽다 ㅋㅋ',
      parentId: '803',
      viewedBy: {'1', '2'},
    ));

    // Unviewed ephemeral photo from 지민 — appears in the album until I view it,
    // then self-destructs 5s later.
    add(_DoodleRow(
      id: '805',
      groupId: '7',
      senderId: '2',
      mode: SendMode.ephemeral,
      contentType: ContentType.photo,
      createdAt: DateTime.utc(2026, 7, 9, 19, 5),
      photoUrl: '/media/g7/805_photo.jpg',
      viewedBy: {},
    ));

    // Biggest drawing (most strokes) — the best-doodle "most_strokes" fallback.
    add(
      _DoodleRow(
        id: '806',
        groupId: '7',
        senderId: '1',
        mode: SendMode.normal,
        contentType: ContentType.drawing,
        createdAt: DateTime.utc(2026, 7, 10, 8, 30),
        drawingUrl: '/media/g7/806_draw.png',
        viewedBy: {'1'},
      ),
      strokes: _bigStrokes(),
    );

    // Reply to 806.
    add(_DoodleRow(
      id: '807',
      groupId: '7',
      senderId: '2',
      mode: SendMode.normal,
      contentType: ContentType.text,
      createdAt: DateTime.utc(2026, 7, 10, 8, 50),
      textBody: '좋은 아침! 오늘도 삐삐 잘 부탁해',
      parentId: '806',
      viewedBy: {},
    ));
  }

  void _seedDiaries() {
    // Mix of default/learned to show the "우리 그림체를 배운 날" boundary:
    // default on 07-07/07-08, then learned from 07-09.
    _diaries['3'] = [
      Diary(
        id: '40',
        entryDate: DateTime(2026, 7, 7),
        imageUrl: '/media/g7/diary_40.png',
        caption: '오늘은 하루 종일 창밖만 바라봤다. 둘이 언제 그림 보내주나 기다렸다.',
        style: const DiaryStyle(kind: StyleKind.default_, version: 0),
        activities: const [PetActivityKind.waiting, PetActivityKind.eating],
      ),
      Diary(
        id: '41',
        entryDate: DateTime(2026, 7, 8),
        imageUrl: '/media/g7/diary_41.png',
        caption: '밥을 먹고 낮잠을 오래 잤다. 포근한 하루였다.',
        style: const DiaryStyle(kind: StyleKind.default_, version: 0),
        activities: const [PetActivityKind.eating, PetActivityKind.sleeping],
      ),
      Diary(
        id: '42',
        entryDate: DateTime(2026, 7, 9),
        imageUrl: '/media/g7/diary_42.png',
        caption: '둘이 보내준 그림을 보고 나도 그림을 그려봤다. 이제 너희 그림체를 조금 알 것 같아.',
        style: const DiaryStyle(kind: StyleKind.learned, version: 1),
        activities: const [
          PetActivityKind.sleeping,
          PetActivityKind.playing,
          PetActivityKind.drawing,
        ],
      ),
    ];
  }

  void _seedExplore() {
    _explore.addAll([
      _ExploreRow(
        petId: '101',
        name: '몽이',
        level: 6,
        moodEmoji: '',
        likeCount: 12,
        likedByMe: false,
        inviteCode: 'SUNNY777',
      ),
      _ExploreRow(
        petId: '102',
        name: '초코',
        level: 3,
        moodEmoji: '',
        likeCount: 5,
        likedByMe: false,
        inviteCode: 'CHOCO123',
      ),
      _ExploreRow(
        petId: '103',
        name: '흰둥',
        level: 8,
        moodEmoji: '',
        likeCount: 30,
        likedByMe: true,
        inviteCode: 'SNOW0001',
      ),
      _ExploreRow(
        petId: '104',
        name: '코코',
        level: 2,
        moodEmoji: '',
        likeCount: 2,
        likedByMe: false,
        inviteCode: 'COCO4444',
      ),
    ]);
  }

  void _seedJuneReport() {
    _reports['2026-06'] = MonthlyReport(
      reportMonth: '2026-06',
      photoCount: 21,
      drawingCount: 34,
      textCount: 5,
      pokeCount: 12,
      dominantType: ContentType.drawing,
      petLevelStart: 2,
      petLevelEnd: 4,
      bestDoodle: BestDoodle(
        id: '704',
        rule: BestDoodleRule.mostReplies,
        contentType: ContentType.drawing,
        thumbUrl: '/media/g7/704_thumb.png',
        drawingUrl: '/media/g7/704_draw.png',
        createdAt: DateTime.utc(2026, 6, 14, 21, 11),
      ),
    );
    _reportGeneratedAt['2026-06'] = DateTime.utc(2026, 7, 1, 0, 5);
  }

  // ===========================================================================
  // Auth / onboarding
  // ===========================================================================

  @override
  Future<AuthResult> register(String displayName, String deviceUid) async {
    // Idempotent per device_uid: returns the seeded user 종혁 and its token.
    // (The demo starts as a returning user already in a group.)
    _registeredDeviceUid ??= deviceUid;
    final u = _users[_meId]!;
    return AuthResult(
      token: _token,
      user: User(id: u.id, displayName: u.displayName),
    );
  }

  @override
  Future<Me> getMe() async {
    final u = _users[_meId]!;
    final g = _groupOf(_meId);
    return Me(
      user: User(id: u.id, displayName: u.displayName),
      group: g == null ? null : _toGroup(g),
    );
  }

  @override
  Future<void> updateMe(String displayName) async {
    _users[_meId]!.displayName = displayName;
  }

  // ===========================================================================
  // Groups
  // ===========================================================================

  @override
  Future<GroupPet> createGroup(String name, String petName) async {
    final groupId = _nextId();
    final petId = _nextId();

    // Side effect: pet + default style (style is implicit here; diaries render
    // from the default style until a learned one exists).
    _pets[petId] = _PetRow(
      id: petId,
      name: petName,
      level: 1,
      exp: 0,
      coins: 0,
      isPublic: true,
      activity: null,
      activityStartedAt: null,
      utterance: null,
    );

    _groups[groupId] = _GroupRow(
      id: groupId,
      name: name,
      inviteCode: _nextInviteCode(),
      backgroundColor: 'FFFFFF',
      petId: petId,
      members: [_MemberRow(_meId, MemberRole.owner)],
    );
    _currentGroupId = groupId;

    return (group: _toGroup(_groups[groupId]!), pet: _toPet(_pets[petId]!));
  }

  @override
  Future<GroupPet> joinGroup(String inviteCode) async {
    final g = _groups.values.firstWhere(
      (x) => x.inviteCode == inviteCode,
      orElse: () => throw _err(404, 'not_found', '초대 코드를 찾을 수 없습니다'),
    );
    if (g.members.any((m) => m.userId == _meId)) {
      throw _err(409, 'already_member', '이미 그 그룹의 멤버입니다');
    }
    if (g.members.length >= 2) {
      throw _err(409, 'group_full', '그룹 정원은 2명입니다');
    }
    g.members.add(_MemberRow(_meId, MemberRole.member));
    _currentGroupId = g.id;
    return (group: _toGroup(g), pet: _toPet(_pets[g.petId]!));
  }

  @override
  Future<Group> getGroup(String id) async {
    final g = _groups[id];
    if (g == null) throw _err(404, 'not_found', '그룹을 찾을 수 없습니다');
    return _toGroup(g);
  }

  @override
  Future<Group> updateGroup(String id, {String? name, String? backgroundColor}) async {
    final g = _groups[id];
    if (g == null) throw _err(404, 'not_found', '그룹을 찾을 수 없습니다');
    if (name != null) g.name = name;
    if (backgroundColor != null) g.backgroundColor = backgroundColor;
    return _toGroup(g);
  }

  @override
  Future<Group> setNickname(String groupId, String userId, String nickname) async {
    final g = _groups[groupId];
    if (g == null) throw _err(404, 'not_found', '그룹을 찾을 수 없습니다');
    if (userId == _meId) {
      throw _err(400, 'invalid_request', '자기 자신에게는 별명을 지을 수 없습니다');
    }
    final m = g.members.where((x) => x.userId == userId).firstOrNull;
    if (m == null) throw _err(404, 'not_found', '멤버를 찾을 수 없습니다');
    m.nickname = nickname;
    return _toGroup(g);
  }

  // ===========================================================================
  // Doodles
  // ===========================================================================

  @override
  Future<Doodle> sendDoodle({
    required SendMode mode,
    required ContentType contentType,
    String? parentId,
    String? textBody,
    Uint8List? photoBytes,
    Uint8List? drawingBytes,
    StrokeData? strokeData,
  }) async {
    final id = _nextId();
    final gid = _currentGroupId;
    final folder = 'g$gid';

    final hasPhoto = photoBytes != null || contentType == ContentType.photo;
    final hasDrawing = drawingBytes != null || contentType == ContentType.drawing;

    final row = _DoodleRow(
      id: id,
      groupId: gid,
      senderId: _meId,
      mode: mode,
      contentType: contentType,
      createdAt: _now(),
      parentId: parentId,
      textBody: textBody,
      photoUrl: hasPhoto ? '/media/$folder/${id}_photo.jpg' : null,
      drawingUrl: hasDrawing ? '/media/$folder/${id}_draw.png' : null,
      viewedBy: {_meId}, // sender has implicitly "viewed" it.
    );
    _doodles[id] = row;

    if (strokeData != null) _strokeData[id] = strokeData;
    if (photoBytes != null) _photoBytes[id] = photoBytes;
    if (drawingBytes != null) _drawingBytes[id] = drawingBytes;

    final doodle = _toDoodle(row);
    onNewDoodle?.call(doodle); // mirror server's doodle:new broadcast.

    // Exchange feeds the pet (server rule §5): a letter +10, a reply +5.
    final pet = _myPet;
    if (pet != null) _grantExp(pet, parentId == null ? 10 : 5);

    return doodle;
  }

  @override
  Future<DoodlePage> listDoodles(
    String groupId, {
    String? before,
    int? limit,
    ContentType? contentType,
    DateTime? date,
  }) async {
    final rows = _doodles.values.where((r) {
      if (r.groupId != groupId) return false;
      if (r.deletedAt != null) return false; // expired ones are gone
      if (contentType != null && r.contentType != contentType) return false;
      if (date != null && !_sameDate(r.createdAt, date)) return false;
      return true;
    }).toList()
      ..sort((a, b) => _idNum(b.id).compareTo(_idNum(a.id))); // newest first

    final beforeNum = before == null ? null : int.tryParse(before);
    final filtered = beforeNum == null
        ? rows
        : rows.where((r) => _idNum(r.id) < beforeNum).toList();

    final lim = (limit ?? 30).clamp(1, 100);
    final page = filtered.take(lim).toList();
    final nextBefore = filtered.length > lim ? page.last.id : null;

    return (
      items: page.map(_toDoodle).toList(),
      nextBefore: nextBefore,
    );
  }

  @override
  Future<Doodle> getDoodle(String id) async {
    final r = _doodles[id];
    if (r == null) throw _err(404, 'not_found', '낙서를 찾을 수 없습니다');
    if (r.deletedAt != null) {
      throw _err(410, 'doodle_expired', '사라진 낙서입니다');
    }
    return _toDoodle(r);
  }

  @override
  Future<DateTime?> viewDoodle(String id) async {
    final r = _doodles[id];
    if (r == null) throw _err(404, 'not_found', '낙서를 찾을 수 없습니다');
    if (r.deletedAt != null) {
      throw _err(410, 'doodle_expired', '사라진 낙서입니다');
    }

    r.viewedBy.add(_meId); // idempotent receipt (UNIQUE doodle_id,user_id).

    // Ephemeral + viewed by a non-sender -> arm the 5s self-destruct once.
    if (r.mode == SendMode.ephemeral &&
        r.senderId != _meId &&
        r.expiresAt == null) {
      r.expiresAt = _now().add(const Duration(seconds: 5));
      _armExpiry(r);
    }
    return r.expiresAt;
  }

  void _armExpiry(_DoodleRow r) {
    // Real runtime timer (allowed). deleted_at is stamped from the mock clock.
    Future.delayed(const Duration(seconds: 5), () {
      if (r.deletedAt != null) return;
      r.deletedAt = r.expiresAt ?? _now();
      onExpired?.call(r.id); // mirror server's doodle:expired broadcast.
    });
  }

  @override
  Future<void> poke(String groupId, String toUserId) async {
    _pokes.add(_PokeRow(groupId, _meId, toUserId, _now()));
    // A poke is a tiny exchange too — +2 exp (server rule §5).
    final pet = _myPet;
    if (pet != null) _grantExp(pet, 2);
  }

  // ===========================================================================
  // Pet
  // ===========================================================================

  @override
  Future<Pet> getPet(String groupId) async {
    final g = _groups[groupId];
    if (g == null) throw _err(404, 'not_found', '그룹을 찾을 수 없습니다');
    return _toPet(_pets[g.petId]!);
  }

  @override
  Future<PatResult> pat(String petId) async {
    final p = _pets[petId];
    if (p == null) throw _err(404, 'not_found', '펫을 찾을 수 없습니다');

    final activity = p.activity ?? PetActivityKind.waiting;
    // Never null: fall back to a default line if there's no cached utterance
    // (GPU down / no activity yet) — "GPU가 죽어도 펫은 말을 해야 한다".
    final line = (p.utterance != null && p.utterance!.isNotEmpty)
        ? p.utterance!
        : _defaultUtterance(activity);

    const gained = 1;
    _grantExp(p, gained);
    return PatResult(activity: activity, utterance: line, expGained: gained);
  }

  /// The server's growth rule (API.md §5): exp accrues from the couple's
  /// exchange (낙서 +10 · 답장 +5 · 찌르기 +2 · 쓰다듬기 +1),
  /// `level = exp ~/ 100 + 1`, and each level gained pays 50 coins.
  void _grantExp(_PetRow p, int amount) {
    p.exp += amount;
    final newLevel = p.exp ~/ 100 + 1;
    if (newLevel > p.level) {
      p.coins += 50 * (newLevel - p.level);
      p.level = newLevel;
      onLevelUp?.call(p.id, p.level);
    }
  }

  /// The current group's pet row (the growth target for exchange rewards).
  _PetRow? get _myPet {
    final g = _groups[_currentGroupId];
    return g == null ? null : _pets[g.petId];
  }

  @override
  Future<DiaryPage> listDiaries(String petId, {String? before, int? limit}) async {
    final all = List<Diary>.from(_diaries[petId] ?? const [])
      ..sort((a, b) => _idNum(b.id).compareTo(_idNum(a.id)));

    final beforeNum = before == null ? null : int.tryParse(before);
    final filtered = beforeNum == null
        ? all
        : all.where((d) => _idNum(d.id) < beforeNum).toList();

    final lim = (limit ?? 30).clamp(1, 100);
    final page = filtered.take(lim).toList();
    final nextBefore = filtered.length > lim ? page.last.id : null;

    return (items: page, nextBefore: nextBefore);
  }

  @override
  Future<Diary> getDiary(String petId, DateTime entryDate) async {
    final d = (_diaries[petId] ?? const [])
        .where((x) => _sameDate(x.entryDate, entryDate))
        .firstOrNull;
    if (d == null) throw _err(404, 'not_found', '해당 날짜의 일기가 없습니다');
    return d;
  }

  // ===========================================================================
  // Monthly report
  // ===========================================================================

  @override
  Future<List<ReportSummary>> listReports(String groupId) async {
    final months = _reports.keys.toList()..sort((a, b) => b.compareTo(a));
    return months
        .map((m) => (
              month: m,
              generatedAt: _reportGeneratedAt[m] ?? _now(),
            ))
        .toList();
  }

  @override
  Future<MonthlyReport> getReport(String groupId, String month) async {
    final r = _reports[month];
    if (r == null) throw _err(404, 'not_found', '해당 월의 레포트가 없습니다');
    return r;
  }

  @override
  Future<MonthlyReport> generateReport(String groupId, String month) async {
    final g = _groups[groupId];
    if (g == null) throw _err(404, 'not_found', '그룹을 찾을 수 없습니다');

    final inMonth = _doodles.values
        .where((r) => r.groupId == groupId && r.deletedAt == null && _monthOf(r.createdAt) == month)
        .toList();

    var photo = 0, drawing = 0, text = 0;
    for (final r in inMonth) {
      switch (r.contentType) {
        case ContentType.photo:
          photo++;
        case ContentType.drawing:
          drawing++;
        case ContentType.text:
          text++;
      }
    }

    final pokeCount =
        _pokes.where((p) => p.groupId == groupId && _monthOf(p.at) == month).length;

    final pet = _pets[g.petId]!;
    final levelEnd = pet.level;
    final levelStart = (levelEnd - 2) < 1 ? 1 : levelEnd - 2;

    final report = MonthlyReport(
      reportMonth: month,
      photoCount: photo,
      drawingCount: drawing,
      textCount: text,
      pokeCount: pokeCount,
      dominantType: _dominant(photo, drawing, text),
      petLevelStart: levelStart,
      petLevelEnd: levelEnd,
      bestDoodle: _bestDoodle(inMonth),
    );

    _reports[month] = report; // overwrite if present
    _reportGeneratedAt[month] = _now();
    return report;
  }

  BestDoodle? _bestDoodle(List<_DoodleRow> rows) {
    // Rule order: most_replies -> most_strokes -> latest. Ephemerals excluded.
    final cands = rows.where((r) => r.mode != SendMode.ephemeral).toList();
    if (cands.isEmpty) return null;

    _DoodleRow? pick;
    late BestDoodleRule rule;

    var bestReplies = 0;
    for (final r in cands) {
      final c = _replyCount(r.id);
      if (c > bestReplies) {
        bestReplies = c;
        pick = r;
      }
    }

    if (pick != null && bestReplies > 0) {
      rule = BestDoodleRule.mostReplies;
    } else {
      final withStrokes = cands.where((r) => _strokeData[r.id] != null).toList()
        ..sort((a, b) => _strokeCount(b.id).compareTo(_strokeCount(a.id)));
      if (withStrokes.isNotEmpty) {
        pick = withStrokes.first;
        rule = BestDoodleRule.mostStrokes;
      } else {
        cands.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        pick = cands.first;
        rule = BestDoodleRule.latest;
      }
    }

    final r = pick;
    return BestDoodle(
      id: r.id,
      rule: rule,
      // v0.2: winner can be photo/drawing/text — render by content_type, and
      // fill exactly the matching url/body (the others stay null).
      contentType: r.contentType,
      thumbUrl: _bestThumb(r),
      textBody: r.textBody,
      photoUrl: r.photoUrl,
      drawingUrl: r.drawingUrl,
      createdAt: r.createdAt,
    );
  }

  /// A BestDoodle always carries a renderable thumb (BestDoodleOut.thumb_url is
  /// non-null), regardless of content type. Photos reuse the photo->thumb
  /// rename; drawings and text get a synthesized thumb path in the same folder.
  String _bestThumb(_DoodleRow r) {
    final photo = r.photoUrl;
    if (photo != null) return _thumb(photo);
    return '/media/g${r.groupId}/${r.id}_thumb.png';
  }

  // ===========================================================================
  // Widget
  // ===========================================================================

  @override
  Future<WidgetData?> getWidget(String groupId) async {
    final rows = _doodles.values
        .where((r) => r.groupId == groupId && r.deletedAt == null)
        .toList()
      ..sort((a, b) => _idNum(b.id).compareTo(_idNum(a.id)));
    if (rows.isEmpty) return null;

    final r = rows.first;
    final isEph = r.mode == SendMode.ephemeral;
    return WidgetData(
      doodleId: r.id,
      // v0.2: carry the latest doodle's kind so the widget picks the right glyph
      // without fetching. This is metadata, not the content — safe for ephemeral.
      contentType: r.contentType,
      // Ephemeral: no thumbnail (showing it would count as a view).
      thumbUrl: isEph ? null : (r.photoUrl == null ? null : _thumb(r.photoUrl!)),
      senderNickname: _nicknameOf(r.senderId, groupId),
      createdAt: r.createdAt,
      isEphemeral: isEph,
    );
  }

  // ===========================================================================
  // Store / inventory
  // ===========================================================================

  @override
  Future<List<Item>> listItems({ItemCategory? category}) async {
    if (category == null) return List<Item>.from(_catalog);
    return _catalog.where((i) => i.category == category).toList();
  }

  @override
  Future<void> buyItem(String petId, String itemId) async {
    final p = _pets[petId];
    if (p == null) throw _err(404, 'not_found', '펫을 찾을 수 없습니다');
    final item = _catalogById[itemId];
    if (item == null) throw _err(404, 'not_found', '아이템을 찾을 수 없습니다');

    final inv = _inventory.putIfAbsent(petId, () => []);
    if (inv.any((it) => it.itemId == itemId)) return; // already owned

    if (p.coins < item.priceCoins) {
      throw _err(422, 'unprocessable', '코인이 부족합니다');
    }
    p.coins -= item.priceCoins;
    inv.add(_PetItemRow(_nextId(), itemId));
  }

  @override
  Future<void> updatePetItem(
    String petId,
    String itemId, {
    bool? isEquipped,
    int? posX,
    int? posY,
  }) async {
    final inv = _inventory[petId];
    final row = inv?.where((it) => it.itemId == itemId).firstOrNull;
    if (inv == null || row == null) {
      throw _err(404, 'not_found', '보유하지 않은 아이템입니다');
    }

    if (isEquipped != null) {
      if (isEquipped) {
        // Equip toggles within category: unequip siblings in the same category.
        final cat = _catalogById[itemId]?.category;
        for (final other in inv) {
          if (other.itemId != itemId && _catalogById[other.itemId]?.category == cat) {
            other.isEquipped = false;
          }
        }
      }
      row.isEquipped = isEquipped;
    }
    if (posX != null) row.posX = posX;
    if (posY != null) row.posY = posY;
  }

  // ===========================================================================
  // Explore
  // ===========================================================================

  @override
  Future<ExplorePage> explorePets({String? before, int? limit}) async {
    final all = List<_ExploreRow>.from(_explore)
      ..sort((a, b) => _idNum(b.petId).compareTo(_idNum(a.petId)));

    final beforeNum = before == null ? null : int.tryParse(before);
    final filtered = beforeNum == null
        ? all
        : all.where((r) => _idNum(r.petId) < beforeNum).toList();

    final lim = (limit ?? 30).clamp(1, 100);
    final page = filtered.take(lim).toList();
    final nextBefore = filtered.length > lim ? page.last.petId : null;

    return (items: page.map(_toExplorePet).toList(), nextBefore: nextBefore);
  }

  @override
  Future<ExplorePet> petByCode(String inviteCode) async {
    final e = _explore.where((r) => r.inviteCode == inviteCode).firstOrNull;
    if (e != null) return _toExplorePet(e);

    // Fall back to a real group's public pet reachable by its invite code.
    final g = _groups.values.where((x) => x.inviteCode == inviteCode).firstOrNull;
    if (g != null) {
      final p = _pets[g.petId]!;
      if (p.isPublic) {
        return ExplorePet(
          petId: p.id,
          name: p.name,
          level: p.level,
          moodEmoji: _moodFor(p.activity),
          likeCount: 0,
          likedByMe: false,
          inviteCode: g.inviteCode,
        );
      }
    }
    throw _err(404, 'not_found', '해당 코드의 펫을 찾을 수 없습니다');
  }

  @override
  Future<void> likePet(String petId) async {
    final e = _explore.where((r) => r.petId == petId).firstOrNull;
    if (e == null) throw _err(404, 'not_found', '펫을 찾을 수 없습니다');
    if (!e.likedByMe) {
      e.likedByMe = true;
      e.likeCount++;
    }
  }

  @override
  Future<void> unlikePet(String petId) async {
    final e = _explore.where((r) => r.petId == petId).firstOrNull;
    if (e == null) throw _err(404, 'not_found', '펫을 찾을 수 없습니다');
    if (e.likedByMe) {
      e.likedByMe = false;
      if (e.likeCount > 0) e.likeCount--;
    }
  }

  // ===========================================================================
  // Realtime / render side-channel helpers (mock-only, not on Repository)
  // ===========================================================================

  /// The stroke data for a drawing doodle, if any. The wire [Doodle] carries
  /// only a URL; this lets an offline drawing viewer paint real vectors.
  StrokeData? strokeDataFor(String doodleId) => _strokeData[doodleId];

  /// Raw photo bytes for a doodle sent through this session, if any.
  Uint8List? photoBytesFor(String doodleId) => _photoBytes[doodleId];

  /// Raw drawing-layer bytes for a doodle sent through this session, if any.
  Uint8List? drawingBytesFor(String doodleId) => _drawingBytes[doodleId];

  /// Simulate the partner sending a doodle (fires [onNewDoodle]) so the
  /// realtime/state wiring can be exercised offline. Returns the new doodle.
  Doodle pushIncomingDoodle({
    required String fromUserId,
    SendMode mode = SendMode.normal,
    ContentType contentType = ContentType.text,
    String? textBody,
    String? parentId,
    StrokeData? strokeData,
  }) {
    final id = _nextId();
    final gid = _currentGroupId;
    final folder = 'g$gid';
    final row = _DoodleRow(
      id: id,
      groupId: gid,
      senderId: fromUserId,
      mode: mode,
      contentType: contentType,
      createdAt: _now(),
      parentId: parentId,
      textBody: textBody,
      photoUrl: contentType == ContentType.photo ? '/media/$folder/${id}_photo.jpg' : null,
      drawingUrl: contentType == ContentType.drawing ? '/media/$folder/${id}_draw.png' : null,
      viewedBy: {}, // not yet viewed by me
    );
    _doodles[id] = row;
    if (strokeData != null) _strokeData[id] = strokeData;
    final doodle = _toDoodle(row);
    onNewDoodle?.call(doodle);
    return doodle;
  }

  // ===========================================================================
  // Builders (private mutable row -> immutable wire model)
  // ===========================================================================

  _GroupRow? _groupOf(String userId) {
    for (final g in _groups.values) {
      if (g.members.any((m) => m.userId == userId)) return g;
    }
    return null;
  }

  Group _toGroup(_GroupRow g) => Group(
        id: g.id,
        name: g.name,
        inviteCode: g.inviteCode,
        backgroundColor: g.backgroundColor,
        memberCount: g.members.length,
        members: g.members
            .map((m) => Member(
                  userId: m.userId,
                  displayName: _users[m.userId]?.displayName ?? '',
                  nickname: m.nickname,
                  role: m.role,
                ))
            .toList(),
      );

  Pet _toPet(_PetRow p) {
    final equipped = (_inventory[p.id] ?? const <_PetItemRow>[])
        .where((it) => it.isEquipped)
        .map((it) {
      final cat = _catalogById[it.itemId];
      return EquippedItem(
        itemId: it.itemId,
        category: cat?.category ?? ItemCategory.prop,
        assetUrl: cat?.assetUrl ?? '',
      );
    }).toList();

    return Pet(
      id: p.id,
      name: p.name,
      level: p.level,
      exp: p.exp,
      coins: p.coins,
      isPublic: p.isPublic,
      currentActivity: p.activity == null
          ? null
          : PetActivity(activity: p.activity!, startedAt: p.activityStartedAt!),
      equippedItems: equipped,
    );
  }

  Doodle _toDoodle(_DoodleRow r) => Doodle(
        id: r.id,
        groupId: r.groupId,
        senderId: r.senderId,
        parentId: r.parentId,
        mode: r.mode,
        contentType: r.contentType,
        photoUrl: r.photoUrl,
        drawingUrl: r.drawingUrl,
        textBody: r.textBody,
        replyCount: _replyCount(r.id),
        viewedByMe: r.viewedBy.contains(_meId),
        expiresAt: r.expiresAt,
        createdAt: r.createdAt,
        thumbUrl: r.photoUrl == null ? null : _thumb(r.photoUrl!),
      );

  ExplorePet _toExplorePet(_ExploreRow r) => ExplorePet(
        petId: r.petId,
        name: r.name,
        level: r.level,
        moodEmoji: r.moodEmoji,
        likeCount: r.likeCount,
        likedByMe: r.likedByMe,
        inviteCode: r.inviteCode,
      );

  // ===========================================================================
  // Small pure helpers
  // ===========================================================================

  int _replyCount(String parentId) =>
      _doodles.values.where((x) => x.parentId == parentId && x.deletedAt == null).length;

  int _strokeCount(String doodleId) => _strokeData[doodleId]?.strokes.length ?? 0;

  int _idNum(String id) => int.tryParse(id) ?? 0;

  String _thumb(String photoUrl) => photoUrl.contains('_photo')
      ? photoUrl.replaceAll('_photo', '_thumb')
      : photoUrl;

  String _nicknameOf(String userId, String groupId) {
    final g = _groups[groupId];
    final m = g?.members.where((x) => x.userId == userId).firstOrNull;
    return m?.nickname ?? _users[userId]?.displayName ?? '';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// v0.2: `dominant_type` is `str | None`. A month with no doodles at all has
  /// no dominant kind — return null (an empty state), never a fabricated type.
  ContentType? _dominant(int photo, int drawing, int text) {
    if (photo + drawing + text == 0) return null;
    if (drawing >= photo && drawing >= text) return ContentType.drawing;
    if (photo >= text) return ContentType.photo;
    return ContentType.text;
  }

  String _defaultUtterance(PetActivityKind a) {
    switch (a) {
      case PetActivityKind.eating:
        return '둘이 준 간식, 아껴 먹는 중이야.';
      case PetActivityKind.sleeping:
        return '편지 기다리다 깜빡 잠들었어…';
      case PetActivityKind.walking:
        return '산책하다가 둘 생각이 났어.';
      case PetActivityKind.playing:
        return '어제 온 그림 옆에서 놀고 있어.';
      case PetActivityKind.drawing:
        return '두 사람 그림체를 따라 그려보는 중.';
      case PetActivityKind.waiting:
        return '오늘의 편지를 기다리고 있어.';
    }
  }

  String _moodFor(PetActivityKind? a) {
    switch (a) {
      case PetActivityKind.eating:
        return '';
      case PetActivityKind.sleeping:
        return '';
      case PetActivityKind.walking:
        return '';
      case PetActivityKind.playing:
        return '';
      case PetActivityKind.drawing:
        return '';
      case PetActivityKind.waiting:
      case null:
        return '';
    }
  }

  // ===========================================================================
  // Seed stroke data (real vectors so drawings render offline)
  // ===========================================================================

  StrokeData _heartStrokes() => StrokeData(
        canvas: const CanvasSize(w: 1080, h: 1080),
        durationMs: 4200,
        strokes: [
          Stroke(
            pen: 'marker',
            color: 'FF5A5F',
            width: 14,
            points: const [
              StrokePoint(x: 540, y: 620, t: 0),
              StrokePoint(x: 420, y: 460, t: 180),
              StrokePoint(x: 480, y: 360, t: 360),
              StrokePoint(x: 540, y: 440, t: 520),
            ],
          ),
          Stroke(
            pen: 'marker',
            color: 'FF5A5F',
            width: 14,
            points: const [
              StrokePoint(x: 540, y: 440, t: 600),
              StrokePoint(x: 600, y: 360, t: 760),
              StrokePoint(x: 660, y: 460, t: 940),
              StrokePoint(x: 540, y: 620, t: 1120),
            ],
          ),
        ],
      );

  StrokeData _scribbleStrokes() => StrokeData(
        canvas: const CanvasSize(w: 1080, h: 1080),
        durationMs: 6800,
        strokes: [
          Stroke(
            pen: 'pen',
            color: '2D9CDB',
            width: 8,
            points: const [
              StrokePoint(x: 200, y: 300, t: 0),
              StrokePoint(x: 320, y: 420, t: 160),
              StrokePoint(x: 460, y: 300, t: 320),
              StrokePoint(x: 600, y: 420, t: 480),
              StrokePoint(x: 740, y: 300, t: 640),
            ],
          ),
        ],
      );

  StrokeData _bigStrokes() => StrokeData(
        canvas: const CanvasSize(w: 1080, h: 1080),
        durationMs: 15200,
        strokes: [
          Stroke(
            pen: 'brush',
            color: '111111',
            width: 10,
            points: const [
              StrokePoint(x: 300, y: 300, t: 0),
              StrokePoint(x: 780, y: 300, t: 240),
              StrokePoint(x: 780, y: 780, t: 480),
              StrokePoint(x: 300, y: 780, t: 720),
              StrokePoint(x: 300, y: 300, t: 960),
            ],
          ),
          Stroke(
            pen: 'brush',
            color: 'F2C94C',
            width: 22,
            points: const [
              StrokePoint(x: 400, y: 500, t: 1100),
              StrokePoint(x: 540, y: 640, t: 1320),
              StrokePoint(x: 680, y: 500, t: 1540),
            ],
          ),
          Stroke(
            pen: 'marker',
            color: 'EB5757',
            width: 12,
            points: const [
              StrokePoint(x: 460, y: 420, t: 1700),
              StrokePoint(x: 500, y: 420, t: 1760),
            ],
          ),
          Stroke(
            pen: 'marker',
            color: 'EB5757',
            width: 12,
            points: const [
              StrokePoint(x: 600, y: 420, t: 1820),
              StrokePoint(x: 640, y: 420, t: 1880),
            ],
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Local `firstOrNull` (avoids a package:collection dependency)
// ---------------------------------------------------------------------------

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
