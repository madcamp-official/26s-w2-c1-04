// Memory Pager — domain models.
//
// Mirrors the app<->server contract in docs/API.md (v0.2) and docs/ERD.md (v0.3).
// This file is the single Dart source of truth for API response shapes.
//
// Conventions (API.md §0):
//   - IDs are 64-bit ints serialized as JSON *strings*  -> Dart `String`.
//   - Colors are 6-digit uppercase hex, no leading '#'  -> Dart `String` (+ `Color` helpers).
//   - Datetimes are UTC ISO-8601                        -> `DateTime` (parsed with `.toUtc()`).
//   - Dates are `YYYY-MM-DD`                            -> `DateTime` (date-only).
//   - Months are `YYYY-MM`                              -> Dart `String`.
//   - `stroke_data.strokes[].points` are `[x, y, t]` arrays, not objects.
//
// Enums tolerate unknown wire values by falling back to a safe member instead of
// throwing (API.md: "모르는 값 만나도 안 죽기"). Each fallback is documented at its enum.
//
// Only `dart:core` (implicit) and `package:flutter/painting` (Color helpers) are used.

import 'package:flutter/painting.dart' show Color;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Send mode of a doodle. Unknown -> [normal] (safest: never auto-expires).
enum SendMode {
  normal('normal'),
  ephemeral('ephemeral');

  const SendMode(this.wire);
  final String wire;

  static SendMode fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return SendMode.normal;
  }

  String toJson() => wire;
}

/// What a doodle carries. Unknown -> [text] (makes no media assumption).
enum ContentType {
  photo('photo'),
  drawing('drawing'),
  text('text');

  const ContentType(this.wire);
  final String wire;

  static ContentType fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return ContentType.text;
  }

  /// Nullable parse: preserves a genuine `null` (empty month's `dominant_type`,
  /// or a widget with no content_type) instead of coercing it to [text].
  /// Used wherever the wire field is `str | None`.
  static ContentType? fromJsonOrNull(Object? v) =>
      v == null ? null : ContentType.fromJson(v);

  String toJson() => wire;
}

/// What the pet is doing. Unknown -> [waiting] (neutral idle state).
enum PetActivityKind {
  eating('eating'),
  sleeping('sleeping'),
  walking('walking'),
  playing('playing'),
  drawing('drawing'),
  waiting('waiting');

  const PetActivityKind(this.wire);
  final String wire;

  static PetActivityKind fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return PetActivityKind.waiting;
  }

  String toJson() => wire;
}

/// Store/inventory item category. Unknown -> [prop] (generic bucket).
enum ItemCategory {
  clothes('clothes'),
  hat('hat'),
  accessory('accessory'),
  furniture('furniture'),
  background('background'),
  prop('prop');

  const ItemCategory(this.wire);
  final String wire;

  static ItemCategory fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return ItemCategory.prop;
  }

  String toJson() => wire;
}

/// Diary drawing style. Wire value for [default_] is `"default"`.
/// Unknown -> [default_] (never falsely claims the pet "learned" our style).
enum StyleKind {
  default_('default'),
  learned('learned');

  const StyleKind(this.wire);
  final String wire;

  static StyleKind fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return StyleKind.default_;
  }

  String toJson() => wire;
}

/// Membership role. Unknown -> [member] (never falsely grants owner rights).
enum MemberRole {
  owner('owner'),
  member('member');

  const MemberRole(this.wire);
  final String wire;

  static MemberRole fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return MemberRole.member;
  }

  String toJson() => wire;
}

/// How "best doodle of the month" was chosen (API.md §6). The rule set grows
/// once vision lands, so an explicit [unknown] absorbs future values.
enum BestDoodleRule {
  mostReplies('most_replies'),
  mostStrokes('most_strokes'),
  latest('latest'),
  unknown('unknown');

  const BestDoodleRule(this.wire);
  final String wire;

  static BestDoodleRule fromJson(Object? v) {
    final s = v?.toString();
    for (final e in values) {
      if (e.wire == s) return e;
    }
    return BestDoodleRule.unknown;
  }

  String toJson() => wire;
}

// ---------------------------------------------------------------------------
// Parsing helpers (private)
// ---------------------------------------------------------------------------

String _str(Object? v) => v is String ? v : v.toString();

String? _strOrNull(Object? v) =>
    v == null ? null : (v is String ? v : v.toString());

int _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.parse(v.toString()));

int? _intOrNull(Object? v) => v == null ? null : _int(v);

double _double(Object? v) =>
    v is double ? v : (v is num ? v.toDouble() : double.parse(v.toString()));

bool _bool(Object? v) =>
    v is bool ? v : (v == 'true' || v == 1 || v == '1');

/// Parse a UTC ISO-8601 timestamp, normalizing to UTC.
DateTime _utc(Object? v) => DateTime.parse(v as String).toUtc();

DateTime? _utcOrNull(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();

/// ISO-8601 UTC string for the wire (`...Z`).
String _isoUtc(DateTime d) => d.toUtc().toIso8601String();

/// Parse a `YYYY-MM-DD` date into a timezone-free date-only [DateTime].
DateTime _date(Object? v) {
  final parts = (v as String).split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Format a [DateTime] back to `YYYY-MM-DD`.
String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

List<T> _list<T>(Object? v, T Function(dynamic) f) =>
    v == null ? <T>[] : (v as List).map(f).toList();

/// Convert a 6-hex color string (no `#`, per §0) into a fully-opaque [Color].
/// Tolerates a leading `#` and an 8-hex (AARRGGBB) form defensively.
Color hexToColor(String hex) {
  var h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

// ---------------------------------------------------------------------------
// Auth / user / group
// ---------------------------------------------------------------------------

/// `POST /auth/register` result.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: _str(json['token']),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

class User {
  const User({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: _str(json['id']),
        displayName: _str(json['display_name']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'display_name': displayName};
}

/// `GET /me`. [group] is null before onboarding completes. Note the `/me`
/// group object is a lightweight `{id, name}` reference — see [Group].
class Me {
  const Me({required this.user, this.group});

  final User user;
  final Group? group;

  factory Me.fromJson(Map<String, dynamic> json) => Me(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        group: json['group'] == null
            ? null
            : Group.fromJson(json['group'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'group': group?.toJson(),
      };
}

/// A group (2-person max). The full object comes from `POST /groups`,
/// `POST /groups/join`, and `GET /groups/{id}`. `GET /me` returns only
/// `{id, name}`, so [fromJson] tolerates the other fields being absent with
/// layout-stable defaults (invite `''`, color `FFFFFF`, count `0`, no members).
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.backgroundColor,
    required this.memberCount,
    required this.members,
  });

  final String id;
  final String name;
  final String inviteCode;

  /// 6-hex uppercase, no `#`.
  final String backgroundColor;
  final int memberCount;
  final List<Member> members;

  Color get backgroundColorValue => hexToColor(backgroundColor);

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: _str(json['id']),
        name: _str(json['name']),
        inviteCode: _strOrNull(json['invite_code']) ?? '',
        backgroundColor: _strOrNull(json['background_color']) ?? 'FFFFFF',
        memberCount: _intOrNull(json['member_count']) ?? 0,
        members: _list(
            json['members'], (e) => Member.fromJson(e as Map<String, dynamic>)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'invite_code': inviteCode,
        'background_color': backgroundColor,
        'member_count': memberCount,
        'members': members.map((m) => m.toJson()).toList(),
      };
}

class Member {
  const Member({
    required this.userId,
    required this.displayName,
    this.nickname,
    required this.role,
  });

  final String userId;
  final String displayName;

  /// Nickname the partner gave this member; null until set.
  final String? nickname;
  final MemberRole role;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        userId: _str(json['user_id']),
        displayName: _str(json['display_name']),
        nickname: _strOrNull(json['nickname']),
        role: MemberRole.fromJson(json['role']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'nickname': nickname,
        'role': role.toJson(),
      };
}

// ---------------------------------------------------------------------------
// Pet
// ---------------------------------------------------------------------------

/// The group's pet. Full form comes from `GET /groups/{id}/pet`. `POST /groups`
/// returns a trimmed pet (`id, name, level, exp, coins`), so [fromJson]
/// tolerates the extra fields being absent.
class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.level,
    required this.exp,
    required this.coins,
    required this.isPublic,
    this.currentActivity,
    required this.equippedItems,
  });

  final String id;
  final String name;
  final int level;
  final int exp;
  final int coins;
  final bool isPublic;

  /// The `ended_at IS NULL` activity; null if the pet has none yet.
  final PetActivity? currentActivity;
  final List<EquippedItem> equippedItems;

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: _str(json['id']),
        name: _str(json['name']),
        level: _int(json['level']),
        exp: _int(json['exp']),
        coins: _int(json['coins']),
        isPublic: _bool(json['is_public']),
        currentActivity: json['current_activity'] == null
            ? null
            : PetActivity.fromJson(
                json['current_activity'] as Map<String, dynamic>),
        equippedItems: _list(json['equipped_items'],
            (e) => EquippedItem.fromJson(e as Map<String, dynamic>)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'exp': exp,
        'coins': coins,
        'is_public': isPublic,
        'current_activity': currentActivity?.toJson(),
        'equipped_items': equippedItems.map((e) => e.toJson()).toList(),
      };
}

class PetActivity {
  const PetActivity({required this.activity, required this.startedAt});

  final PetActivityKind activity;
  final DateTime startedAt;

  factory PetActivity.fromJson(Map<String, dynamic> json) => PetActivity(
        activity: PetActivityKind.fromJson(json['activity']),
        startedAt: _utc(json['started_at']),
      );

  Map<String, dynamic> toJson() => {
        'activity': activity.toJson(),
        'started_at': _isoUtc(startedAt),
      };
}

class EquippedItem {
  const EquippedItem({
    required this.itemId,
    required this.category,
    required this.assetUrl,
  });

  final String itemId;
  final ItemCategory category;
  final String assetUrl;

  factory EquippedItem.fromJson(Map<String, dynamic> json) => EquippedItem(
        itemId: _str(json['item_id']),
        category: ItemCategory.fromJson(json['category']),
        assetUrl: _str(json['asset_url']),
      );

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'category': category.toJson(),
        'asset_url': assetUrl,
      };
}

/// `POST /pets/{id}/pat` result (echoes the cached activity utterance).
class PatResult {
  const PatResult({
    required this.activity,
    required this.utterance,
    required this.expGained,
  });

  final PetActivityKind activity;
  final String utterance;
  final int expGained;

  factory PatResult.fromJson(Map<String, dynamic> json) => PatResult(
        activity: PetActivityKind.fromJson(json['activity']),
        utterance: _str(json['utterance']),
        expGained: _int(json['exp_gained']),
      );

  Map<String, dynamic> toJson() => {
        'activity': activity.toJson(),
        'utterance': utterance,
        'exp_gained': expGained,
      };
}

// ---------------------------------------------------------------------------
// Doodles
// ---------------------------------------------------------------------------

/// A doodle. `reply_count`, `viewed_by_me`, and `thumb_url` are server-computed
/// (not DB columns). [expiresAt] is set only for ephemeral doodles once viewed;
/// [thumbUrl] is not present on the `POST /doodles` response.
class Doodle {
  const Doodle({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.parentId,
    required this.mode,
    required this.contentType,
    this.photoUrl,
    this.drawingUrl,
    this.textBody,
    required this.replyCount,
    required this.viewedByMe,
    this.expiresAt,
    required this.createdAt,
    this.thumbUrl,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String? parentId;
  final SendMode mode;
  final ContentType contentType;
  final String? photoUrl;
  final String? drawingUrl;
  final String? textBody;
  final int replyCount;
  final bool viewedByMe;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? thumbUrl;

  factory Doodle.fromJson(Map<String, dynamic> json) => Doodle(
        id: _str(json['id']),
        groupId: _str(json['group_id']),
        senderId: _str(json['sender_id']),
        parentId: _strOrNull(json['parent_id']),
        mode: SendMode.fromJson(json['mode']),
        contentType: ContentType.fromJson(json['content_type']),
        photoUrl: _strOrNull(json['photo_url']),
        drawingUrl: _strOrNull(json['drawing_url']),
        textBody: _strOrNull(json['text_body']),
        replyCount: _intOrNull(json['reply_count']) ?? 0,
        viewedByMe: _bool(json['viewed_by_me']),
        expiresAt: _utcOrNull(json['expires_at']),
        createdAt: _utc(json['created_at']),
        thumbUrl: _strOrNull(json['thumb_url']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'sender_id': senderId,
        'parent_id': parentId,
        'mode': mode.toJson(),
        'content_type': contentType.toJson(),
        'photo_url': photoUrl,
        'drawing_url': drawingUrl,
        'text_body': textBody,
        'reply_count': replyCount,
        'viewed_by_me': viewedByMe,
        'expires_at': expiresAt == null ? null : _isoUtc(expiresAt!),
        'created_at': _isoUtc(createdAt),
        'thumb_url': thumbUrl,
      };
}

/// The `stroke_data` JSON attached to a drawing doodle (API.md §4).
class StrokeData {
  const StrokeData({
    required this.canvas,
    required this.durationMs,
    required this.strokes,
  });

  final CanvasSize canvas;
  final int durationMs;
  final List<Stroke> strokes;

  factory StrokeData.fromJson(Map<String, dynamic> json) => StrokeData(
        canvas: CanvasSize.fromJson(json['canvas'] as Map<String, dynamic>),
        durationMs: _int(json['duration_ms']),
        strokes:
            _list(json['strokes'], (e) => Stroke.fromJson(e as Map<String, dynamic>)),
      );

  Map<String, dynamic> toJson() => {
        'canvas': canvas.toJson(),
        'duration_ms': durationMs,
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };
}

class CanvasSize {
  const CanvasSize({required this.w, required this.h});

  final int w;
  final int h;

  factory CanvasSize.fromJson(Map<String, dynamic> json) =>
      CanvasSize(w: _int(json['w']), h: _int(json['h']));

  Map<String, dynamic> toJson() => {'w': w, 'h': h};
}

class Stroke {
  const Stroke({
    required this.pen,
    required this.color,
    required this.width,
    required this.points,
  });

  final String pen;

  /// 6-hex uppercase, no `#`.
  final String color;
  final double width;
  final List<StrokePoint> points;

  Color get colorValue => hexToColor(color);

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        pen: _str(json['pen']),
        color: _str(json['color']),
        width: _double(json['width']),
        points: _list(json['points'], (e) => StrokePoint.fromJson(e as List)),
      );

  Map<String, dynamic> toJson() => {
        'pen': pen,
        'color': color,
        'width': width,
        'points': points.map((p) => p.toJson()).toList(),
      };
}

/// A single sampled point. Serialized as an `[x, y, t]` array (API.md §4),
/// where `t` is milliseconds elapsed from the start of its stroke.
class StrokePoint {
  const StrokePoint({required this.x, required this.y, required this.t});

  final double x;
  final double y;
  final int t;

  factory StrokePoint.fromJson(List<dynamic> json) => StrokePoint(
        x: _double(json[0]),
        y: _double(json[1]),
        t: _int(json[2]),
      );

  /// Note: returns a `List`, not a `Map` — points are arrays on the wire.
  List<dynamic> toJson() => [x, y, t];
}

// ---------------------------------------------------------------------------
// Diary
// ---------------------------------------------------------------------------

class Diary {
  const Diary({
    required this.id,
    required this.entryDate,
    required this.imageUrl,
    required this.caption,
    required this.style,
    required this.activities,
  });

  final String id;

  /// Date-only (`YYYY-MM-DD`), timezone-free.
  final DateTime entryDate;
  final String imageUrl;
  final String caption;
  final DiaryStyle style;
  final List<PetActivityKind> activities;

  factory Diary.fromJson(Map<String, dynamic> json) => Diary(
        id: _str(json['id']),
        entryDate: _date(json['entry_date']),
        imageUrl: _str(json['image_url']),
        caption: _str(json['caption']),
        style: DiaryStyle.fromJson(json['style'] as Map<String, dynamic>),
        activities:
            _list(json['activities'], (e) => PetActivityKind.fromJson(e)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entry_date': _fmtDate(entryDate),
        'image_url': imageUrl,
        'caption': caption,
        'style': style.toJson(),
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

/// The drawing style a diary was rendered in. [kind] flipping from `default_`
/// to `learned` marks the day the pet learned the group's style.
class DiaryStyle {
  const DiaryStyle({required this.kind, required this.version});

  final StyleKind kind;
  final int version;

  factory DiaryStyle.fromJson(Map<String, dynamic> json) => DiaryStyle(
        kind: StyleKind.fromJson(json['kind']),
        version: _int(json['version']),
      );

  Map<String, dynamic> toJson() => {'kind': kind.toJson(), 'version': version};
}

// ---------------------------------------------------------------------------
// Monthly report
// ---------------------------------------------------------------------------

class MonthlyReport {
  const MonthlyReport({
    required this.reportMonth,
    required this.photoCount,
    required this.drawingCount,
    required this.textCount,
    required this.pokeCount,
    required this.dominantType,
    required this.petLevelStart,
    required this.petLevelEnd,
    this.bestDoodle,
  });

  /// `YYYY-MM`.
  final String reportMonth;
  final int photoCount;
  final int drawingCount;
  final int textCount;
  final int pokeCount;

  /// The month's most-common doodle kind, or `null` for a month with no
  /// doodles at all (v0.2: `dominant_type: str | None`). Null means "no data",
  /// not [ContentType.text] — callers must show an empty state, not a fake type.
  final ContentType? dominantType;
  final int petLevelStart;
  final int petLevelEnd;
  final BestDoodle? bestDoodle;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        reportMonth: _str(json['report_month']),
        photoCount: _int(json['photo_count']),
        drawingCount: _int(json['drawing_count']),
        textCount: _int(json['text_count']),
        pokeCount: _int(json['poke_count']),
        dominantType: ContentType.fromJsonOrNull(json['dominant_type']),
        petLevelStart: _int(json['pet_level_start']),
        petLevelEnd: _int(json['pet_level_end']),
        bestDoodle: json['best_doodle'] == null
            ? null
            : BestDoodle.fromJson(json['best_doodle'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'report_month': reportMonth,
        'photo_count': photoCount,
        'drawing_count': drawingCount,
        'text_count': textCount,
        'poke_count': pokeCount,
        'dominant_type': dominantType?.toJson(),
        'pet_level_start': petLevelStart,
        'pet_level_end': petLevelEnd,
        'best_doodle': bestDoodle?.toJson(),
      };
}

/// The month's winning doodle (`best_doodle` in ReportOut, shape [BestDoodleOut]).
/// v0.2 widened this beyond drawings: the winner can be a photo, drawing, or
/// text, so the app branches on [contentType] to render it. [thumbUrl] is always
/// present; exactly one of [textBody]/[photoUrl]/[drawingUrl] is filled to match
/// [contentType].
class BestDoodle {
  const BestDoodle({
    required this.id,
    required this.rule,
    required this.contentType,
    required this.thumbUrl,
    this.textBody,
    this.photoUrl,
    this.drawingUrl,
    required this.createdAt,
  });

  final String id;
  final BestDoodleRule rule;

  /// The winner's kind — render by this, not by assuming a drawing.
  final ContentType contentType;

  /// Non-null in [BestDoodleOut] (`thumb_url: str`); always renderable.
  final String thumbUrl;
  final String? textBody;
  final String? photoUrl;
  final String? drawingUrl;
  final DateTime createdAt;

  factory BestDoodle.fromJson(Map<String, dynamic> json) => BestDoodle(
        id: _str(json['id']),
        rule: BestDoodleRule.fromJson(json['rule']),
        contentType: ContentType.fromJson(json['content_type']),
        thumbUrl: _str(json['thumb_url']),
        textBody: _strOrNull(json['text_body']),
        photoUrl: _strOrNull(json['photo_url']),
        drawingUrl: _strOrNull(json['drawing_url']),
        createdAt: _utc(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rule': rule.toJson(),
        'content_type': contentType.toJson(),
        'thumb_url': thumbUrl,
        'text_body': textBody,
        'photo_url': photoUrl,
        'drawing_url': drawingUrl,
        'created_at': _isoUtc(createdAt),
      };
}

// ---------------------------------------------------------------------------
// Store / inventory (P2)
// ---------------------------------------------------------------------------

/// Store catalog entry (`GET /items`).
class Item {
  const Item({
    required this.id,
    required this.category,
    required this.name,
    required this.priceCoins,
    required this.assetUrl,
  });

  final String id;
  final ItemCategory category;
  final String name;
  final int priceCoins;
  final String assetUrl;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: _str(json['id']),
        category: ItemCategory.fromJson(json['category']),
        name: _str(json['name']),
        priceCoins: _int(json['price_coins']),
        assetUrl: _str(json['asset_url']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.toJson(),
        'name': name,
        'price_coins': priceCoins,
        'asset_url': assetUrl,
      };
}

/// An item a pet owns (`POST/PATCH /pets/{id}/items`). [posX]/[posY] are the
/// home-decoration placement, null when the item isn't placed.
class PetItem {
  const PetItem({
    required this.id,
    required this.itemId,
    required this.isEquipped,
    this.posX,
    this.posY,
  });

  final String id;
  final String itemId;
  final bool isEquipped;
  final int? posX;
  final int? posY;

  factory PetItem.fromJson(Map<String, dynamic> json) => PetItem(
        id: _str(json['id']),
        itemId: _str(json['item_id']),
        isEquipped: _bool(json['is_equipped']),
        posX: _intOrNull(json['pos_x']),
        posY: _intOrNull(json['pos_y']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'is_equipped': isEquipped,
        'pos_x': posX,
        'pos_y': posY,
      };
}

// ---------------------------------------------------------------------------
// Explore (P2)
// ---------------------------------------------------------------------------

/// A public pet in the explore feed (`GET /pets/explore`, `/pets/by-code/{code}`).
class ExplorePet {
  const ExplorePet({
    required this.petId,
    required this.name,
    required this.level,
    required this.moodEmoji,
    required this.likeCount,
    required this.likedByMe,
    required this.inviteCode,
  });

  final String petId;
  final String name;
  final int level;
  final String moodEmoji;
  final int likeCount;
  final bool likedByMe;
  final String inviteCode;

  factory ExplorePet.fromJson(Map<String, dynamic> json) => ExplorePet(
        petId: _str(json['pet_id']),
        name: _str(json['name']),
        level: _int(json['level']),
        moodEmoji: _str(json['mood_emoji']),
        likeCount: _int(json['like_count']),
        likedByMe: _bool(json['liked_by_me']),
        inviteCode: _str(json['invite_code']),
      );

  Map<String, dynamic> toJson() => {
        'pet_id': petId,
        'name': name,
        'level': level,
        'mood_emoji': moodEmoji,
        'like_count': likeCount,
        'liked_by_me': likedByMe,
        'invite_code': inviteCode,
      };
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Home-screen widget payload (`GET /widget/{group_id}`, shape [WidgetOut]).
/// Kept deliberately light — the widget runs under battery limits.
///
/// Every field except [isEphemeral] is nullable per WidgetOut (`... | None`),
/// so a group with no latest doodle degrades to an empty widget instead of
/// fabricating one. When [isEphemeral] is true the widget must not show
/// [thumbUrl] (showing it would count as a view). [contentType] was added in
/// v0.2 so the widget can pick the right glyph without fetching the doodle.
class WidgetData {
  const WidgetData({
    this.doodleId,
    this.contentType,
    this.thumbUrl,
    this.senderNickname,
    this.createdAt,
    required this.isEphemeral,
  });

  final String? doodleId;
  final ContentType? contentType;
  final String? thumbUrl;
  final String? senderNickname;
  final DateTime? createdAt;
  final bool isEphemeral;

  factory WidgetData.fromJson(Map<String, dynamic> json) => WidgetData(
        doodleId: _strOrNull(json['doodle_id']),
        contentType: ContentType.fromJsonOrNull(json['content_type']),
        thumbUrl: _strOrNull(json['thumb_url']),
        senderNickname: _strOrNull(json['sender_nickname']),
        createdAt: _utcOrNull(json['created_at']),
        isEphemeral: _bool(json['is_ephemeral']),
      );

  Map<String, dynamic> toJson() => {
        'doodle_id': doodleId,
        'content_type': contentType?.toJson(),
        'thumb_url': thumbUrl,
        'sender_nickname': senderNickname,
        'created_at': createdAt == null ? null : _isoUtc(createdAt!),
        'is_ephemeral': isEphemeral,
      };
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

/// The `error` object inside an error envelope (API.md §0):
/// `{ "error": { "code": "...", "message": "..." } }`.
class ApiError {
  const ApiError({required this.code, required this.message});

  final String code;
  final String message;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: _str(json['code']),
        message: _str(json['message']),
      );

  /// Parse from the full `{ "error": {...} }` envelope.
  factory ApiError.fromEnvelope(Map<String, dynamic> json) =>
      ApiError.fromJson(json['error'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}

/// Thrown by the API client when a request fails. Carries the parsed [error]
/// and the HTTP [status] so callers can split e.g. 404 (not_found) from
/// 410 (doodle_expired).
class ApiException implements Exception {
  ApiException(this.error, this.status);

  /// Build from an HTTP status and a decoded `{ "error": {...} }` body.
  factory ApiException.fromEnvelope(int status, Map<String, dynamic> body) =>
      ApiException(ApiError.fromEnvelope(body), status);

  final ApiError error;
  final int status;

  String get code => error.code;
  String get message => error.message;

  @override
  String toString() => 'ApiException($status ${error.code}: ${error.message})';
}
