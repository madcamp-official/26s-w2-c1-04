// Memory Pager — the repository contract.
//
// One typed async method per endpoint in docs/API.md (v0.1). This is the seam
// the app talks to; two implementations back it:
//   - [MockRepository]  — a fully in-memory backend (no server needed).
//   - [RestRepository]  — the real HTTP client (package:http).
//
// Realtime (Socket.IO doodle:new / doodle:expired / poke / pet:activity …) is
// deliberately NOT modelled here. It is a separate concern; a realtime layer
// wires it and pushes results into app state. The mock exposes callback hooks
// (onNewDoodle / onExpired) so that layer can be exercised offline.
//
// Return-type conventions:
//   - Reads return the parsed model.
//   - List reads return a named record `(items, nextBefore)` cursor page.
//   - Creates that spawn side effects return a tuple (e.g. group+pet).
//   - Mutations that change a *displayed* aggregate return that aggregate
//     (updateGroup/setNickname -> Group). Pure signals return void
//     (poke / like / unlike / updateMe / buyItem / updatePetItem); callers
//     re-read the aggregate — "REST가 진실의 원본이다" (API.md §9).
//
// Only dart core libs, package:http (impl only), and models.dart are used.

import 'dart:typed_data';

import '../models.dart';

// ---------------------------------------------------------------------------
// Record aliases (Dart 3 records — no new model classes needed)
// ---------------------------------------------------------------------------

/// `POST /groups` and `POST /groups/join` create a group *and* its pet.
typedef GroupPet = ({Group group, Pet pet});

/// A cursor page of doodles: `{ items, next_before }` (API.md §4).
typedef DoodlePage = ({List<Doodle> items, String? nextBefore});

/// A cursor page of diaries (API.md §5).
typedef DiaryPage = ({List<Diary> items, String? nextBefore});

/// A cursor page of explore pets (API.md §8, P2).
typedef ExplorePage = ({List<ExplorePet> items, String? nextBefore});

/// One row of `GET /groups/{id}/reports` — the lightweight list form
/// `{ report_month, generated_at }` (API.md §6). No full-report model needed.
typedef ReportSummary = ({String month, DateTime generatedAt});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// The app<->backend contract. Every method maps 1:1 to an endpoint in
/// docs/API.md. Failures surface as [ApiException] carrying the HTTP status
/// and error `code` so callers can split e.g. 404 from 410.
abstract class Repository {
  // -- Auth / onboarding (API.md §2) ----------------------------------------

  /// `POST /auth/register`. Idempotent per `device_uid`.
  Future<AuthResult> register(String displayName, String deviceUid);

  /// `GET /me`. [Me.group] is null before onboarding completes.
  Future<Me> getMe();

  /// `PATCH /me`. Renames the current user (ON-1, ST-1).
  Future<void> updateMe(String displayName);

  // -- Groups (API.md §3) ---------------------------------------------------

  /// `POST /groups` (ON-2). Side effect: also creates the pet and a
  /// `default` style so diaries can render from day one.
  Future<GroupPet> createGroup(String name, String petName);

  /// `POST /groups/join` (ON-3). 409 `group_full` / `already_member`.
  Future<GroupPet> joinGroup(String inviteCode);

  /// `GET /groups/{id}`.
  Future<Group> getGroup(String id);

  /// `PATCH /groups/{id}` (GR-1 name, GR-2 background_color). Returns the
  /// updated group.
  Future<Group> updateGroup(String id, {String? name, String? backgroundColor});

  /// `PATCH /groups/{id}/members/{userId}` (ON-4). Nicknames the *other*
  /// member. Nicknaming yourself is 400. Returns the updated group.
  Future<Group> setNickname(String groupId, String userId, String nickname);

  // -- Doodles (API.md §4, ) -----------------------------------------------

  /// `POST /doodles` (multipart). The app decides [contentType]; the server
  /// does not recompute it. [parentId] carries a reply (RV-1).
  Future<Doodle> sendDoodle({
    required SendMode mode,
    required ContentType contentType,
    String? parentId,
    String? textBody,
    Uint8List? photoBytes,
    Uint8List? drawingBytes,
    StrokeData? strokeData,
  });

  /// `GET /groups/{groupId}/doodles` (RV-2/3/4). Newest first. Deleted
  /// (expired) doodles are excluded; unviewed ephemerals still appear.
  Future<DoodlePage> listDoodles(
    String groupId, {
    String? before,
    int? limit,
    ContentType? contentType,
    DateTime? date,
  });

  /// `GET /doodles/{id}` (RV-4). Throws [ApiException] 410 `doodle_expired`
  /// if it was destroyed by ephemeral mode, 404 if it never existed.
  Future<Doodle> getDoodle(String id);

  /// `POST /doodles/{id}/view` (SD-6, ). Idempotent receipt. If the doodle
  /// is ephemeral and *not* sent by me, arms the 5s self-destruct and returns
  /// the `expires_at`; otherwise returns null.
  Future<DateTime?> viewDoodle(String id);

  /// `POST /groups/{groupId}/pokes` (SD-7, ).
  Future<void> poke(String groupId, String toUserId);

  // -- Pet (API.md §5, ) ---------------------------------------------------

  /// `GET /groups/{groupId}/pet`. The home screen.
  Future<Pet> getPet(String groupId);

  /// `POST /pets/{petId}/pat` (PT-1, ). Echoes the cached activity
  /// utterance — never null, falls back to a default line if the pet has no
  /// activity yet. Does not call the LLM.
  Future<PatResult> pat(String petId);

  /// `GET /pets/{petId}/diaries` (PT-6a). Newest first.
  Future<DiaryPage> listDiaries(String petId, {String? before, int? limit});

  /// `GET /pets/{petId}/diaries/{entryDate}`. 404 if none for that day.
  Future<Diary> getDiary(String petId, DateTime entryDate);

  // -- Monthly report (API.md §6, MR-*) -------------------------------------

  /// `GET /groups/{groupId}/reports`. Lightweight list.
  Future<List<ReportSummary>> listReports(String groupId);

  /// `GET /groups/{groupId}/reports/{month}` where month is `YYYY-MM`.
  Future<MonthlyReport> getReport(String groupId, String month);

  /// `POST /groups/{groupId}/reports/{month}/generate`. Manual demo trigger;
  /// overwrites if present. Best doodle rule: most_replies -> most_strokes ->
  /// latest (ephemerals excluded).
  Future<MonthlyReport> generateReport(String groupId, String month);

  // -- Widget (API.md §7, RV-5 ) -------------------------------------------

  /// `GET /widget/{groupId}`. Null when the group has no doodle yet.
  Future<WidgetData?> getWidget(String groupId);

  // -- Store / inventory (API.md §8, P2) ------------------------------------

  /// `GET /items`. Optional [category] filter.
  Future<List<Item>> listItems({ItemCategory? category});

  /// `POST /pets/{petId}/items`. Buys an item. 422 `unprocessable` when
  /// coins are short. Idempotent if already owned.
  Future<void> buyItem(String petId, String itemId);

  /// `PATCH /pets/{petId}/items/{itemId}`. Equip/unequip (toggles within the
  /// item's category) and/or place it (pos_x/pos_y).
  Future<void> updatePetItem(
    String petId,
    String itemId, {
    bool? isEquipped,
    int? posX,
    int? posY,
  });

  // -- Explore (API.md §8, P2, EX-*) ----------------------------------------

  /// `GET /pets/explore` (EX-3). Public pets, newest first.
  Future<ExplorePage> explorePets({String? before, int? limit});

  /// `GET /pets/by-code/{inviteCode}` (EX-2). 404 if unknown.
  Future<ExplorePet> petByCode(String inviteCode);

  /// `POST /pets/{petId}/like` (EX-1). Idempotent.
  Future<void> likePet(String petId);

  /// `DELETE /pets/{petId}/like`. Idempotent.
  Future<void> unlikePet(String petId);
}
