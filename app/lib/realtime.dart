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
      'doodle:expired',
      'poke',
      'pet:activity',
      'pet:levelup',
      'diary:new',
    ]) {
      s.on(e, (data) {
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        onEvent?.call(e, map);
      });
    }
    s.connect();
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
