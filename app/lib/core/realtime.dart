// Memory Pager — the realtime layer.
//
// Socket.IO is the *fast path*; REST is the source of truth (API.md §9:
// "소켓 이벤트는 유실될 수 있고, REST가 진실의 원본이다"). This file models the
// documented server→client events as a small sealed [RealtimeEvent] hierarchy
// and exposes them on one broadcast [Realtime.events] stream. State (AppState)
// listens once and reconciles; on reconnect it re-reads doodles over REST.
//
// Two implementations back the [Realtime] seam:
//   - [MockRealtime]  — drives a *live* partner + pet entirely offline: a
//     periodic timer rotates the pet's activity, occasionally has the partner
//     (지민, user '2') send a doodle, relays the mock's ephemeral self-destruct,
//     and — when the app pokes — has the partner poke back ~2s later.
//   - [SocketRealtime] — the real socket_io_client transport. Not used in the
//     offline demo, but it COMPILES and maps every documented event, ready to
//     swap in.
//
// Determinism (matches MockRepository's rule): NO DateTime.now(), NO Random.
// Timestamps come from the injected mock clock (`repo.clock.now()`); the
// activity/doodle rotations are index-driven, not random. The periodic timer
// itself is a runtime timer (allowed — like MockRepository's Future.delayed),
// not a wall-clock read.
//
// Payloads are exactly API.md §9's server→client table:
//   doodle:new   {doodle_id, sender_id, mode, content_type, thumb_url, created_at}
//   doodle:expired {doodle_id}
//   poke         {from_user_id, at}
//   pet:activity {pet_id, activity, utterance}
//   pet:levelup  {pet_id, level}
//   diary:new    {diary_id, entry_date, style_kind}
// and the client→server emits:
//   doodle:viewed {doodle_id}   ·   poke:send {to_user_id}

import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as sio;

import 'api/mock_repository.dart';
import 'models.dart';

// ---------------------------------------------------------------------------
// Events (sealed) — one class per documented server→client event.
// ---------------------------------------------------------------------------

/// Base type for everything pushed over the realtime channel. Sealed so state
/// code can switch exhaustively.
sealed class RealtimeEvent {
  const RealtimeEvent();
}

/// `doodle:new` — a doodle landed in the room (mine echoed back, or the
/// partner's). The socket payload only carries the summary fields; the mock
/// additionally attaches the fully-parsed [doodle] so state can insert it
/// without a re-fetch (over the real socket [doodle] is null and state re-reads
/// via REST).
final class DoodleNew extends RealtimeEvent {
  const DoodleNew({
    required this.doodleId,
    required this.senderId,
    required this.mode,
    required this.contentType,
    this.thumbUrl,
    required this.createdAt,
    this.doodle,
  });

  final String doodleId;
  final String senderId;
  final SendMode mode;
  final ContentType contentType;
  final String? thumbUrl;
  final DateTime createdAt;

  /// Present only on the mock path (full row available in-process).
  final Doodle? doodle;

  factory DoodleNew.fromDoodle(Doodle d) => DoodleNew(
        doodleId: d.id,
        senderId: d.senderId,
        mode: d.mode,
        contentType: d.contentType,
        thumbUrl: d.thumbUrl,
        createdAt: d.createdAt,
        doodle: d,
      );
}

/// `doodle:expired` — a viewed ephemeral doodle self-destructed.
final class DoodleExpired extends RealtimeEvent {
  const DoodleExpired(this.doodleId);
  final String doodleId;
}

/// `poke` — the partner poked me (SD-7).
final class PokeReceived extends RealtimeEvent {
  const PokeReceived({required this.fromUserId, required this.at});
  final String fromUserId;
  final DateTime at;
}

/// `pet:activity` — the pet's activity changed (PT-1). Carries the fresh
/// utterance so the home screen can update its speech bubble without a pat.
final class PetActivityChanged extends RealtimeEvent {
  const PetActivityChanged({
    required this.petId,
    required this.activity,
    required this.utterance,
  });
  final String petId;
  final PetActivityKind activity;
  final String utterance;
}

/// `pet:levelup` — the pet leveled up.
final class PetLevelUp extends RealtimeEvent {
  const PetLevelUp({required this.petId, required this.level});
  final String petId;
  final int level;
}

/// `diary:new` — a new diary entry was rendered (PT-6a, midnight batch).
final class DiaryNew extends RealtimeEvent {
  const DiaryNew({
    required this.diaryId,
    required this.entryDate,
    required this.styleKind,
  });
  final String diaryId;

  /// Date-only (`YYYY-MM-DD`).
  final DateTime entryDate;
  final StyleKind styleKind;
}

// ---------------------------------------------------------------------------
// Realtime seam
// ---------------------------------------------------------------------------

/// The realtime channel. State subscribes to [events] once; UI never touches
/// this directly. [connect] opens the channel (mock: starts the simulation;
/// socket: opens the WebSocket). The two [emit] methods are the client→server
/// fast-path equivalents of `POST /doodles/{id}/view` and `POST .../pokes`.
abstract class Realtime {
  /// Broadcast stream of inbound events. Broadcast so multiple listeners (and
  /// late listeners) are allowed; events fired before anyone listens are dropped
  /// (REST backfills — see re-read on reconnect).
  Stream<RealtimeEvent> get events;

  /// Open the channel with the auth [token].
  void connect(String token);

  /// `doodle:viewed {doodle_id}` — socket-fast equivalent of `POST /view`.
  void emitDoodleViewed(String doodleId);

  /// `poke:send {to_user_id}` — socket-fast equivalent of `POST .../pokes`.
  void emitPokeSend(String toUserId);

  /// Tear down the channel and close the stream.
  void dispose();
}

// ---------------------------------------------------------------------------
// MockRealtime — an offline live partner + pet.
// ---------------------------------------------------------------------------

/// Drives a believable live world against a [MockRepository]:
///   - every [_activityInterval] the pet rotates to the next activity and
///     "speaks" a fresh utterance (PetActivityChanged),
///   - every 3rd tick the partner (지민, '2') sends a doodle — done by calling
///     [MockRepository.pushIncomingDoodle], whose `onNewDoodle` hook this class
///     relays as [DoodleNew],
///   - the mock's ephemeral self-destruct (`onExpired`) is relayed as
///     [DoodleExpired],
///   - when the app pokes ([emitPokeSend]) the partner pokes back ~2s later
///     ([PokeReceived]).
///
/// Everything time-stamped reads `repo.clock.now()`; rotations are index-driven.
class MockRealtime implements Realtime {
  MockRealtime(this._repo) {
    // Bridge the repository's realtime hooks onto our event stream. These fire
    // for BOTH my own sends and the partner's pushes; state dedupes by id.
    _repo.onNewDoodle = (Doodle d) => _add(DoodleNew.fromDoodle(d));
    _repo.onExpired = (String id) => _add(DoodleExpired(id));
  }

  final MockRepository _repo;

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  static const Duration _activityInterval = Duration(seconds: 5);

  // The seeded demo world: pet '3' (삐삐), partner '2' (지민).
  static const String _petId = '3';
  static const String _partnerId = '2';

  Timer? _activityTimer;
  int _activityStep = 0;
  int _doodleStep = 0;
  bool _disposed = false;

  // Deterministic activity rotation (kind + fresh utterance).
  static const List<(PetActivityKind, String)> _activities = [
    (PetActivityKind.eating, '냠냠 맛있다! 오늘 낙서도 그려줄 거지?'),
    (PetActivityKind.playing, '심심해서 공 굴리는 중! 같이 놀자 '),
    (PetActivityKind.drawing, '너희 그림체 따라서 슥슥 그려보는 중이야'),
    (PetActivityKind.walking, '창밖 산책하면서 둘 생각했어'),
    (PetActivityKind.sleeping, '졸려어… 잠깐만 눈 붙일게 zzz'),
    (PetActivityKind.waiting, '언제 낙서 보내주려나~ 기다리는 중'),
  ];

  // Deterministic partner-doodle rotation (text bodies from 지민).
  static const List<String> _partnerLines = [
    '지금 뭐해? 삐삐가 심심해한다 ㅋㅋ',
    '이거 봐봐, 방금 그린 거!',
    '오늘 하루도 화이팅 ',
    '보고싶다 ️',
  ];

  @override
  Stream<RealtimeEvent> get events => _controller.stream;

  @override
  void connect(String token) {
    // token is accepted for parity with the socket transport; the mock needs
    // no handshake. Start (or restart) the live simulation.
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(_activityInterval, (_) => _tick());
  }

  void _tick() {
    if (_disposed) return;

    final entry = _activities[_activityStep % _activities.length];
    _add(PetActivityChanged(
      petId: _petId,
      activity: entry.$1,
      utterance: entry.$2,
    ));

    // Every 3rd tick, the partner sends a doodle. pushIncomingDoodle fires the
    // repo's onNewDoodle hook, which we relay as DoodleNew — so we do NOT add a
    // DoodleNew here ourselves (that would double-emit).
    if (_activityStep % 3 == 2) {
      final line = _partnerLines[_doodleStep % _partnerLines.length];
      _doodleStep++;
      _repo.pushIncomingDoodle(
        fromUserId: _partnerId,
        contentType: ContentType.text,
        textBody: line,
      );
    }

    _activityStep++;
  }

  @override
  void emitDoodleViewed(String doodleId) {
    // No-op in the mock: state opens doodles through the REST path
    // (`repo.viewDoodle`), which arms the 5s self-destruct and — via onExpired —
    // feeds DoodleExpired back onto this stream. Kept for interface parity.
  }

  @override
  void emitPokeSend(String toUserId) {
    // Simulate the partner poking back shortly after I poke them.
    if (_disposed) return;
    Timer(const Duration(seconds: 2), () {
      if (_disposed) return;
      _add(PokeReceived(fromUserId: toUserId, at: _repo.clock.now()));
    });
  }

  void _add(RealtimeEvent e) {
    if (_disposed || _controller.isClosed) return;
    _controller.add(e);
  }

  @override
  void dispose() {
    _disposed = true;
    _activityTimer?.cancel();
    _activityTimer = null;
    // Release the repo hooks we own.
    _repo.onNewDoodle = null;
    _repo.onExpired = null;
    _controller.close();
  }
}

// ---------------------------------------------------------------------------
// SocketRealtime — the real socket_io_client transport (compiles; used later).
// ---------------------------------------------------------------------------

/// The production realtime channel over Socket.IO. [url] is the API *origin*
/// (e.g. `https://api.example.com`, the same base REST uses); [connect] joins
/// the `/rt` namespace at that origin (API.md §9) over the default `/socket.io`
/// engine path. WebSocket transport is forced because native dart:io cannot do
/// polling. Auth is sent as `auth: { token }`; the server resolves the token to
/// a user and auto-joins their `group:{group_id}` room.
///
/// Maps every documented server→client event to a [RealtimeEvent] and the two
/// client→server emits. This is not exercised by the offline demo but is kept
/// compiling so it can be swapped in without touching state code.
class SocketRealtime implements Realtime {
  SocketRealtime(this.url, this.token);

  /// The API origin. The `/rt` namespace endpoint is derived from it in
  /// [connect] (see [_rtEndpoint]).
  final String url;
  String token;

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  sio.Socket? _socket;

  @override
  Stream<RealtimeEvent> get events => _controller.stream;

  @override
  void connect(String token) {
    this.token = token;

    // A prior socket (e.g. a manual reconnect) must be torn down first so we
    // don't leak the old engine + its listeners.
    _socket?.dispose();

    final socket = sio.io(
      _rtEndpoint(url), // '<origin>/rt' — the /rt namespace at the API origin.
      sio.OptionBuilder()
          .setPath('/socket.io') // engine mount path (API.md §9 default).
          .setTransports(['websocket']) // dart:io has no polling — required.
          .setAuth({'token': token}) // server joins us to our group room.
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.on('doodle:new', (data) {
      final m = _map(data);
      final mode = SendMode.fromJson(m['mode']);
      _add(DoodleNew(
        doodleId: _s(m['doodle_id']),
        senderId: _s(m['sender_id']),
        mode: mode,
        contentType: ContentType.fromJson(m['content_type']),
        // Ephemeral doodles must not leak a preview before they're opened, so
        // the thumbnail is honored only for normal-mode sends (API.md §9).
        thumbUrl: mode == SendMode.normal ? m['thumb_url'] as String? : null,
        createdAt: _utc(m['created_at']),
      ));
    });

    socket.on('doodle:expired', (data) {
      final m = _map(data);
      _add(DoodleExpired(_s(m['doodle_id'])));
    });

    socket.on('poke', (data) {
      final m = _map(data);
      _add(PokeReceived(fromUserId: _s(m['from_user_id']), at: _utc(m['at'])));
    });

    socket.on('pet:activity', (data) {
      final m = _map(data);
      _add(PetActivityChanged(
        petId: _s(m['pet_id']),
        activity: PetActivityKind.fromJson(m['activity']),
        utterance: _s(m['utterance']),
      ));
    });

    socket.on('pet:levelup', (data) {
      final m = _map(data);
      _add(PetLevelUp(petId: _s(m['pet_id']), level: _i(m['level'])));
    });

    socket.on('diary:new', (data) {
      final m = _map(data);
      _add(DiaryNew(
        diaryId: _s(m['diary_id']),
        entryDate: _date(m['entry_date']),
        styleKind: StyleKind.fromJson(m['style_kind']),
      ));
    });

    socket.connect();
  }

  @override
  void emitDoodleViewed(String doodleId) =>
      _socket?.emit('doodle:viewed', {'doodle_id': doodleId});

  @override
  void emitPokeSend(String toUserId) =>
      _socket?.emit('poke:send', {'to_user_id': toUserId});

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _controller.close();
  }

  void _add(RealtimeEvent e) {
    if (_controller.isClosed) return;
    _controller.add(e);
  }

  // -- endpoint + wire parsing helpers ---------------------------------------

  /// Resolve the `/rt` namespace URL from the API [origin]. Idempotent: an
  /// origin that already ends in `/rt` is returned as-is (minus any trailing
  /// slash), so passing either `<origin>` or `<origin>/rt` both connect to the
  /// documented namespace.
  static String _rtEndpoint(String origin) {
    var o = origin;
    while (o.endsWith('/')) {
      o = o.substring(0, o.length - 1);
    }
    return o.endsWith('/rt') ? o : '$o/rt';
  }

  Map<String, dynamic> _map(dynamic d) =>
      d is Map ? d.cast<String, dynamic>() : <String, dynamic>{};

  String _s(Object? v) => v is String ? v : v.toString();

  int _i(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

  DateTime _utc(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  DateTime _date(Object? v) {
    if (v is! String) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final p = v.split('-');
    if (p.length < 3) return DateTime.parse(v);
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}
