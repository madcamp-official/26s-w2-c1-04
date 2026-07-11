// Memory Pager — the app's single source of UI state.
//
// [AppState] is the one [ChangeNotifier] the whole app watches. It owns the
// session (token / me / group / pet), the doodle album (with cursor paging),
// the pet's *live* activity, and a transient banner queue (incoming pokes and
// new doodles). It talks to a [Repository] for durable reads/writes and listens
// to a [Realtime] channel for live pushes — reconciling the two under the API's
// rule that REST is the source of truth and the socket is the fast path.
//
// Every action delegates to the repository, then updates local state and calls
// notifyListeners. Aggregates that a mutation changes are re-read from the repo
// rather than guessed (e.g. buy/equip -> refreshPet), keeping "REST가 진실이다".
//
// The demo boots *already onboarded*: [AppState.mock] wires a [MockRepository]
// + [MockRealtime], registers the seeded returning user (종혁), loads their group
// (우리집) and pet (삐삐), fills the album, and connects the live simulation — so
// the app opens straight onto the pet home. A ready-made global [appState] does
// exactly this. Determinism is inherited from the mock: no DateTime.now(), no
// Random anywhere in this layer.

import 'dart:async';

import 'package:flutter/foundation.dart'; // also re-exports Uint8List

import '../charlab/roster.dart';
import 'api/mock_repository.dart';
import 'api/repository.dart';
import 'models.dart';
import 'realtime.dart';

// ---------------------------------------------------------------------------
// Transient notifications (banners)
// ---------------------------------------------------------------------------

/// What a banner is about.
enum NotificationKind { doodleNew, pokeReceived }

/// A transient banner item — an incoming poke or a partner's new doodle. Not
/// persisted; lives only in [AppState.notifications] until dismissed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.text,
    required this.at,
    this.doodleId,
    this.fromUserId,
  });

  /// Session-local unique id (monotonic, deterministic).
  final String id;
  final NotificationKind kind;
  final String text;
  final DateTime at;

  /// Set for [NotificationKind.doodleNew] — the doodle to open on tap.
  final String? doodleId;

  /// Set for [NotificationKind.pokeReceived] — who poked.
  final String? fromUserId;
}

// ---------------------------------------------------------------------------
// AppState
// ---------------------------------------------------------------------------

class AppState extends ChangeNotifier {
  AppState({required this.repo, required this.rt}) {
    _sub = rt.events.listen(_onEvent);
  }

  /// Build the fully-seeded offline demo: MockRepository + MockRealtime, an
  /// already-onboarded returning user, album loaded, live simulation running.
  factory AppState.mock() {
    final repo = MockRepository();
    final rt = MockRealtime(repo);
    final state = AppState(repo: repo, rt: rt);
    state.bootstrapFuture = state._bootstrapMock();
    return state;
  }

  final Repository repo;
  final Realtime rt;

  late final StreamSubscription<RealtimeEvent> _sub;

  /// Completes when [AppState.mock]'s initial load has finished (null on a
  /// hand-built AppState). UI may await it before first paint.
  Future<void>? bootstrapFuture;

  // -- Session --------------------------------------------------------------

  String? token;
  User? me;
  Group? group;
  Pet? pet;

  // -- Album (cursor-paged) -------------------------------------------------

  final List<Doodle> album = <Doodle>[];
  String? _albumBefore;
  bool albumHasMore = true;
  bool albumLoading = false;

  /// doodleId -> expires_at for ephemeral doodles currently counting down. The
  /// entry is removed when the [DoodleExpired] event lands (the doodle is also
  /// dropped from [album] then).
  final Map<String, DateTime> ephemeralExpiry = <String, DateTime>{};

  // -- Live pet activity (socket fast-path) ---------------------------------

  PetActivityKind? currentActivity;
  String? currentUtterance;

  // -- Pet species (which drawn character renders as the pet) ---------------
  //
  // The couple picks their pet's look from the roster. The backend `Pet` has no
  // species column yet (ERD/API), so this is an honest CLIENT-LOCAL preference
  // for now — it changes the drawing, never any server-owned data. When the
  // backend adds a species field this reads through to it unchanged.

  String petSpecies = kDefaultSpecies;

  void setPetSpecies(String id) {
    petSpecies = id;
    notifyListeners();
  }

  // -- Transient banners ----------------------------------------------------

  final List<AppNotification> notifications = <AppNotification>[];
  int _notifSeq = 0;

  // -- Diaries / store / reports / widget / explore -------------------------

  final List<Diary> diaries = <Diary>[];
  String? _diariesBefore;
  bool diariesHasMore = true;

  List<Item> items = <Item>[];

  List<ReportSummary> reports = <ReportSummary>[];
  MonthlyReport? report;

  WidgetData? widgetData;

  final List<ExplorePet> explorePets = <ExplorePet>[];
  String? _exploreBefore;
  bool exploreHasMore = true;

  // ===========================================================================
  // Bootstrap
  // ===========================================================================

  Future<void> _bootstrapMock() async {
    // Returning, already-onboarded user (idempotent register returns 종혁).
    final auth = await repo.register('종혁', 'demo-device-jonghyeok');
    token = auth.token;

    final m = await repo.getMe();
    me = m.user;
    group = m.group; // non-null in the seeded demo -> straight to pet home

    final g = group;
    if (g != null) {
      final p = await repo.getPet(g.id);
      pet = p;
      currentActivity = p.currentActivity?.activity;
      await loadAlbum(reset: true);
      await loadWidget();
      rt.connect(token!); // start the live simulation
    }
    notifyListeners();
  }

  // ===========================================================================
  // Auth / onboarding
  // ===========================================================================

  Future<void> register(String displayName, String deviceUid) async {
    final res = await repo.register(displayName, deviceUid);
    token = res.token;
    me = res.user;
    notifyListeners();
  }

  Future<void> updateMe(String displayName) async {
    await repo.updateMe(displayName);
    final m = me;
    if (m != null) me = User(id: m.id, displayName: displayName);
    notifyListeners();
  }

  Future<void> createGroup(String name, String petName) async {
    final gp = await repo.createGroup(name, petName);
    group = gp.group;
    pet = gp.pet;
    currentActivity = gp.pet.currentActivity?.activity;
    notifyListeners();
  }

  Future<void> joinGroup(String inviteCode) async {
    final gp = await repo.joinGroup(inviteCode);
    group = gp.group;
    pet = gp.pet;
    currentActivity = gp.pet.currentActivity?.activity;
    notifyListeners();
  }

  Future<void> setNickname(String userId, String nickname) async {
    final g = group;
    if (g == null) return;
    group = await repo.setNickname(g.id, userId, nickname);
    notifyListeners();
  }

  Future<void> updateGroup({String? name, String? backgroundColor}) async {
    final g = group;
    if (g == null) return;
    group = await repo.updateGroup(g.id, name: name, backgroundColor: backgroundColor);
    notifyListeners();
  }

  // ===========================================================================
  // Pet
  // ===========================================================================

  Future<void> refreshPet() async {
    final g = group;
    if (g == null) return;
    final p = await repo.getPet(g.id);
    pet = p;
    // Keep the live activity if the socket knows a fresher one; otherwise adopt
    // the REST snapshot.
    currentActivity = currentActivity ?? p.currentActivity?.activity;
    notifyListeners();
  }

  Future<PatResult> pat() async {
    final p = pet;
    if (p == null) throw StateError('펫이 없습니다');
    final r = await repo.pat(p.id);
    currentActivity = r.activity;
    currentUtterance = r.utterance;
    pet = _petWith(p, exp: p.exp + r.expGained);
    notifyListeners();
    return r;
  }

  // ===========================================================================
  // Doodles
  // ===========================================================================

  Future<Doodle> sendDoodle({
    required SendMode mode,
    required ContentType contentType,
    String? parentId,
    String? textBody,
    Uint8List? photoBytes,
    Uint8List? drawingBytes,
    StrokeData? strokeData,
  }) async {
    final d = await repo.sendDoodle(
      mode: mode,
      contentType: contentType,
      parentId: parentId,
      textBody: textBody,
      photoBytes: photoBytes,
      drawingBytes: drawingBytes,
      strokeData: strokeData,
    );
    // Insert immediately; the echoed `doodle:new` will dedupe by id.
    if (!album.any((x) => x.id == d.id)) album.insert(0, d);
    notifyListeners();
    return d;
  }

  Future<void> loadAlbum({
    bool reset = false,
    ContentType? contentType,
    DateTime? date,
  }) async {
    final g = group;
    if (g == null || albumLoading) return;

    albumLoading = true;
    if (reset) {
      album.clear();
      _albumBefore = null;
      albumHasMore = true;
    }
    notifyListeners();

    try {
      final page = await repo.listDoodles(
        g.id,
        before: _albumBefore,
        limit: 30,
        contentType: contentType,
        date: date,
      );
      for (final d in page.items) {
        if (!album.any((x) => x.id == d.id)) album.add(d);
      }
      _albumBefore = page.nextBefore;
      albumHasMore = page.nextBefore != null;
    } finally {
      albumLoading = false;
      notifyListeners();
    }
  }

  /// Open a doodle: register the view (REST, idempotent), and — if it was an
  /// ephemeral not sent by me — arm the visible countdown. The doodle is
  /// removed from [album] when its [DoodleExpired] event lands.
  Future<void> openDoodle(String id) async {
    final expiresAt = await repo.viewDoodle(id);
    final idx = album.indexWhere((d) => d.id == id);
    if (idx >= 0) album[idx] = _withViewed(album[idx], expiresAt);
    if (expiresAt != null) ephemeralExpiry[id] = expiresAt;
    notifyListeners();
  }

  Future<void> poke(String toUserId) async {
    final g = group;
    if (g == null) return;
    await repo.poke(g.id, toUserId); // REST (always works)
    rt.emitPokeSend(toUserId); // socket-fast twin; mock schedules the poke-back
    notifyListeners();
  }

  // ===========================================================================
  // Store / inventory
  // ===========================================================================

  Future<void> loadItems({ItemCategory? category}) async {
    items = await repo.listItems(category: category);
    notifyListeners();
  }

  Future<void> buyItem(String itemId) async {
    final p = pet;
    if (p == null) return;
    await repo.buyItem(p.id, itemId);
    await refreshPet(); // coins + inventory changed
  }

  Future<void> equipItem(String itemId, {bool equip = true}) async {
    final p = pet;
    if (p == null) return;
    await repo.updatePetItem(p.id, itemId, isEquipped: equip);
    await refreshPet();
  }

  // ===========================================================================
  // Diaries / report / widget
  // ===========================================================================

  Future<void> loadDiaries({bool reset = false}) async {
    final p = pet;
    if (p == null) return;
    if (reset) {
      diaries.clear();
      _diariesBefore = null;
      diariesHasMore = true;
    }
    final page = await repo.listDiaries(p.id, before: _diariesBefore, limit: 30);
    for (final d in page.items) {
      if (!diaries.any((x) => x.id == d.id)) diaries.add(d);
    }
    _diariesBefore = page.nextBefore;
    diariesHasMore = page.nextBefore != null;
    notifyListeners();
  }

  Future<void> loadReports() async {
    final g = group;
    if (g == null) return;
    reports = await repo.listReports(g.id);
    notifyListeners();
  }

  Future<MonthlyReport?> loadReport(String month) async {
    final g = group;
    if (g == null) return null;
    try {
      report = await repo.getReport(g.id, month);
    } on ApiException catch (e) {
      if (e.status == 404) {
        report = null; // honest empty state, not a fabricated report
      } else {
        rethrow;
      }
    }
    notifyListeners();
    return report;
  }

  Future<MonthlyReport> generateReport(String month) async {
    final g = group;
    if (g == null) throw StateError('그룹이 없습니다');
    report = await repo.generateReport(g.id, month);
    notifyListeners();
    return report!;
  }

  Future<WidgetData?> loadWidget() async {
    final g = group;
    if (g == null) return null;
    widgetData = await repo.getWidget(g.id);
    notifyListeners();
    return widgetData;
  }

  // ===========================================================================
  // Explore
  // ===========================================================================

  Future<void> explore({bool reset = false}) async {
    if (reset) {
      explorePets.clear();
      _exploreBefore = null;
      exploreHasMore = true;
    }
    final page = await repo.explorePets(before: _exploreBefore, limit: 30);
    for (final p in page.items) {
      if (!explorePets.any((x) => x.petId == p.petId)) explorePets.add(p);
    }
    _exploreBefore = page.nextBefore;
    exploreHasMore = page.nextBefore != null;
    notifyListeners();
  }

  Future<void> like(String petId, {required bool liked}) async {
    if (liked) {
      await repo.likePet(petId);
    } else {
      await repo.unlikePet(petId);
    }
    final idx = explorePets.indexWhere((p) => p.petId == petId);
    if (idx >= 0) {
      final p = explorePets[idx];
      final changed = liked != p.likedByMe;
      final nextCount = !changed
          ? p.likeCount
          : (liked ? p.likeCount + 1 : (p.likeCount > 0 ? p.likeCount - 1 : 0));
      explorePets[idx] = ExplorePet(
        petId: p.petId,
        name: p.name,
        level: p.level,
        moodEmoji: p.moodEmoji,
        likeCount: nextCount,
        likedByMe: liked,
        inviteCode: p.inviteCode,
      );
    }
    notifyListeners();
  }

  // ===========================================================================
  // Notifications (banners)
  // ===========================================================================

  void dismissNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  // ===========================================================================
  // Realtime event handling
  // ===========================================================================

  void _onEvent(RealtimeEvent e) {
    switch (e) {
      case final DoodleNew ev:
        _onDoodleNew(ev);
      case final DoodleExpired ev:
        _removeDoodle(ev.doodleId);
      case final PokeReceived ev:
        _pushNotification(
          kind: NotificationKind.pokeReceived,
          text: '${_nameFor(ev.fromUserId)}님이 콕 찔렀어요 ',
          fromUserId: ev.fromUserId,
          at: ev.at,
        );
      case final PetActivityChanged ev:
        if (pet == null || ev.petId == pet!.id) {
          currentActivity = ev.activity;
          currentUtterance = ev.utterance;
        }
      case final PetLevelUp ev:
        final p = pet;
        if (p != null && ev.petId == p.id) pet = _petWith(p, level: ev.level);
      case DiaryNew():
        // Only id/date/style arrive; REST is truth, so re-read the list.
        if (pet != null) unawaited(loadDiaries(reset: true));
    }
    notifyListeners();
  }

  void _onDoodleNew(DoodleNew e) {
    final d = e.doodle;
    final already = album.any((x) => x.id == e.doodleId);

    if (d != null && !already) {
      if (group == null || d.groupId == group!.id) album.insert(0, d);
    } else if (d == null && !already && group != null) {
      // Socket path: no row inline — backfill from REST (source of truth).
      unawaited(loadAlbum(reset: true));
    }

    // Banner only for the partner's doodles, never my own echo.
    if (me == null || e.senderId != me!.id) {
      _pushNotification(
        kind: NotificationKind.doodleNew,
        text: '${_nameFor(e.senderId)}님이 새 낙서를 보냈어요',
        doodleId: e.doodleId,
        fromUserId: e.senderId,
        at: e.createdAt,
      );
    }
  }

  void _removeDoodle(String id) {
    album.removeWhere((d) => d.id == id);
    ephemeralExpiry.remove(id);
  }

  void _pushNotification({
    required NotificationKind kind,
    required String text,
    required DateTime at,
    String? doodleId,
    String? fromUserId,
  }) {
    notifications.insert(
      0,
      AppNotification(
        id: 'n${_notifSeq++}',
        kind: kind,
        text: text,
        at: at,
        doodleId: doodleId,
        fromUserId: fromUserId,
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Display name for a user id, preferring the partner-given nickname.
  String _nameFor(String userId) {
    final g = group;
    if (g != null) {
      for (final m in g.members) {
        if (m.userId == userId) return m.nickname ?? m.displayName;
      }
    }
    if (me != null && me!.id == userId) return me!.displayName;
    return '상대';
  }

  Doodle _withViewed(Doodle d, DateTime? expiresAt) => Doodle(
        id: d.id,
        groupId: d.groupId,
        senderId: d.senderId,
        parentId: d.parentId,
        mode: d.mode,
        contentType: d.contentType,
        photoUrl: d.photoUrl,
        drawingUrl: d.drawingUrl,
        textBody: d.textBody,
        replyCount: d.replyCount,
        viewedByMe: true,
        expiresAt: expiresAt ?? d.expiresAt,
        createdAt: d.createdAt,
        thumbUrl: d.thumbUrl,
      );

  Pet _petWith(Pet p, {int? level, int? exp}) => Pet(
        id: p.id,
        name: p.name,
        level: level ?? p.level,
        exp: exp ?? p.exp,
        coins: p.coins,
        isPublic: p.isPublic,
        currentActivity: p.currentActivity,
        equippedItems: p.equippedItems,
      );

  @override
  void dispose() {
    _sub.cancel();
    rt.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Global — the seeded demo state (opens straight onto the pet home).
// ---------------------------------------------------------------------------

final AppState appState = AppState.mock();
