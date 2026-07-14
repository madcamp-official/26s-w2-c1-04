// 실시간 계층 — Socket.IO /rt (과제 주 옵션). 계약은 ../docs/FRONTEND.md.
// 네임스페이스 /rt, auth {token}, transports websocket 고정.
// 서버→클라: doodle:new · doodle:expired · poke · pet:activity · pet:levelup · diary:new.

import 'package:socket_io_client/socket_io_client.dart' as io;

typedef RtHandler = Future<void> Function(String event, Map data);

class Rt {
  Rt(this.host, this.token);

  final String host; // https://anjonghwa.madcamp-kaist.org
  final String token;
  io.Socket? _s;
  RtHandler? onEvent;

  Future<void> connect() async {
    final s = io.io(
      '$host/rt',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .enableForceNew()
          .build(),
    );
    _s = s;
    for (final e in const [
      'doodle:new',
      'doodle:updated', // 캡션 등 갱신 — 목록 재수신
      'doodle:expired',
      'poke',
      'pet:activity',
      'pet:levelup',
      'diary:new',
      'member:left', // 상대 이탈(#24) → 온보딩 복귀
      'question:answered', // 오늘의 질문 상대 답변(#6) → 질문 재수신
    ]) {
      s.on(e, (data) {
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        onEvent?.call(e, map);
      });
    }
    // 백그라운드 복귀 등으로 끊겼다가 다시 붙으면(#2), 놓친 이벤트를 메우도록 알린다.
    s.onReconnect((_) => onEvent?.call('__reconnect', <String, dynamic>{}));
    s.connect();
  }

  /// 현재 소켓이 연결돼 있는지. 앱 포그라운드 복귀 시 재연결 판단에 쓴다(#2).
  bool get connected => _s?.connected ?? false;

  /// 끊겨 있으면 다시 연결을 시도한다(포그라운드 복귀 재동기화).
  void ensureConnected() {
    final s = _s;
    if (s != null && !s.connected) s.connect();
  }

  /// 사라지기 확인의 빠른 길(REST 와 동등). ack 로 결과.
  void doodleViewed(String doodleId) =>
      _s?.emitWithAck('doodle:viewed', {'doodle_id': doodleId}, ack: (_) {});

  void pokeSend(String toUserId) =>
      _s?.emitWithAck('poke:send', {'to_user_id': toUserId}, ack: (_) {});

  void dispose() {
    _s?.dispose();
    _s = null;
  }
}
