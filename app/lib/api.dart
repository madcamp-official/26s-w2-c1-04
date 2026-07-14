// 실서버 REST 클라이언트. 계약은 ../docs/API.md.
// 응답을 앱의 기존 타입(mock.dart 의 Doodle 등)으로 매핑해, 화면은 그대로 두고
// 데이터 소스만 바꾼다. 미디어 상대경로(/media/...)엔 호스트를 붙인다.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mock.dart';

class ApiException implements Exception {
  ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  bool get gone => status == 410 || code == 'doodle_expired';
  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// 서버가 내려준 그룹 스냅샷 (온보딩·설정용).
class GroupSnapshot {
  GroupSnapshot({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.backgroundColor,
    required this.members,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String inviteCode;
  final String backgroundColor;
  final List<Map<String, dynamic>> members; // {user_id, display_name, nickname, role}
  final DateTime? createdAt;
}

class Api {
  Api(String apiBase)
      : host = _stripV1(apiBase),
        _base = '${_stripV1(apiBase)}/v1';

  final String host; // https://.../  (미디어·소켓용)
  final String _base;
  String? token;
  String? myUserId;
  String? deviceUid; // 401 복구 시 기기 uid 로 재등록(#15)
  void Function()? onAuthLost; // 토큰 무효(401) 감지 콜백 — 세션이 서버에서 사라졌을 때

  static String _stripV1(String s) {
    var o = s;
    while (o.endsWith('/')) {
      o = o.substring(0, o.length - 1);
    }
    if (o.endsWith('/v1')) o = o.substring(0, o.length - 3);
    return o;
  }

  String media(String? path) =>
      (path == null || path.isEmpty) ? '' : '$host$path';

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Never _fail(http.Response r) {
    String code = 'error', msg = 'HTTP ${r.statusCode}';
    try {
      final e = (jsonDecode(r.body) as Map)['error'] as Map?;
      if (e != null) {
        code = '${e['code']}';
        msg = '${e['message']}';
      }
    } catch (_) {}
    throw ApiException(r.statusCode, code, msg);
  }

  dynamic _ok(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    }
    // 토큰이 무효(401) — 서버에서 세션이 사라졌다(데이터 리셋 등). 복구를 알린다(#15).
    // 이 처리가 없으면 매 요청이 조용히 실패해 '전송 실패' 팝업만 반복된다.
    if (r.statusCode == 401 && token != null) onAuthLost?.call();
    _fail(r);
  }

  Future<dynamic> _get(String p) async =>
      _ok(await http.get(Uri.parse('$_base$p'), headers: _h));

  Future<dynamic> _post(String p, [Object? body]) async => _ok(await http.post(
        Uri.parse('$_base$p'),
        headers: _h,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> _patch(String p, [Object? body]) async => _ok(await http.patch(
        Uri.parse('$_base$p'),
        headers: _h,
        body: body == null ? null : jsonEncode(body),
      ));

  // ---- 인증 · 온보딩 ----
  Future<void> register(String displayName, String deviceUid) async {
    this.deviceUid = deviceUid;
    final j = await _post('/auth/register',
        {'display_name': displayName, 'device_uid': deviceUid});
    token = j['token'] as String;
    myUserId = '${j['user']['id']}';
  }

  /// {user, group|null}
  Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from(await _get('/me') as Map);

  /// 그룹 상세(name·invite_code·members·created_at·background_color). /me 는 {id,name}만 준다.
  Future<Map<String, dynamic>> group(String gid) async =>
      Map<String, dynamic>.from(await _get('/groups/$gid') as Map);

  Future<Map<String, dynamic>> createGroup(String name, String petName) async =>
      Map<String, dynamic>.from(
          await _post('/groups', {'name': name, 'pet_name': petName}) as Map);

  Future<Map<String, dynamic>> joinGroup(String code) async =>
      Map<String, dynamic>.from(
          await _post('/groups/join', {'invite_code': code}) as Map);

  /// 그룹 나가기(커플 연결 끊기). 204 No Content 라 _post(JSON 파싱) 대신 직접 호출.
  Future<void> leaveGroup(String gid) async {
    final r =
        await http.post(Uri.parse('$_base/groups/$gid/leave'), headers: _h);
    if (r.statusCode >= 400) _fail(r);
  }

  /// FCM 토큰 등록(멱등). 204 라 파싱하지 않는다.
  Future<void> registerDevice(String fcmToken, {String? appVersion}) async {
    await _post('/devices', {'fcm_token': fcmToken, 'app_version': ?appVersion});
  }

  // PATCH 들은 상태코드를 검사한다(_patch → _ok). 실패 시 예외를 던져 호출측이 되돌린다.
  Future<void> updateMe(String displayName) async {
    await _patch('/me', {'display_name': displayName});
  }

  Future<void> updateGroup(String gid, {String? name, String? bgColor}) async {
    await _patch('/groups/$gid', {'name': ?name, 'background_color': ?bgColor});
  }

  Future<void> setNickname(String gid, String targetUserId, String nick) async {
    await _patch('/groups/$gid/members/$targetUserId', {'nickname': nick});
  }

  // ---- 펫 ----
  Future<Map<String, dynamic>> pet(String gid) async =>
      Map<String, dynamic>.from(await _get('/groups/$gid/pet') as Map);

  /// {activity, utterance, exp_gained}
  Future<Map<String, dynamic>> pat(String petId) async =>
      Map<String, dynamic>.from(await _post('/pets/$petId/pat') as Map);

  // ---- 낙서 ----
  Future<List<Doodle>> doodles(String gid, {int limit = 40}) async {
    final j = await _get('/groups/$gid/doodles?limit=$limit') as Map;
    final items = (j['items'] as List? ?? const []);
    return [for (final it in items) doodleFrom(it as Map)];
  }

  // ---- 그림 일기 · 월간 레포트 ----
  Future<List<Map<String, dynamic>>> diaries(String petId,
      {int limit = 20}) async {
    final j = await _get('/pets/$petId/diaries?limit=$limit') as Map;
    final items = (j['items'] as List? ?? const []);
    return [for (final it in items) Map<String, dynamic>.from(it as Map)];
  }

  /// 레포트가 있는 달 목록('YYYY-MM' 오름차순). 없으면 빈 리스트(신규 그룹).
  Future<List<String>> reportMonths(String gid) async {
    final j = await _get('/groups/$gid/reports') as Map;
    final items = (j['items'] as List? ?? const []);
    return [for (final it in items) '${(it as Map)['report_month']}']..sort();
  }

  /// 특정 달의 레포트 상세.
  Future<Map<String, dynamic>> report(String gid, String month) async =>
      Map<String, dynamic>.from(
          await _get('/groups/$gid/reports/$month') as Map);

  Future<Doodle> getDoodle(String id) async =>
      doodleFrom(await _get('/doodles/$id') as Map);

  /// 텍스트 낙서 전송.
  Future<Doodle> sendText(String text, {bool ephemeral = false, String? parentId}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/doodles'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['mode'] = ephemeral ? 'ephemeral' : 'normal'
      ..fields['content_type'] = 'text'
      ..fields['text_body'] = text;
    if (parentId != null) req.fields['parent_id'] = parentId;
    final resp = await http.Response.fromStream(await req.send());
    return doodleFrom(_ok(resp) as Map);
  }

  /// 손그림 전송: PNG 바이트 + stroke_data JSON.
  Future<Doodle> sendDrawing(List<int> png, String strokeJson,
      {bool ephemeral = false, String? parentId}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_base/doodles'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['mode'] = ephemeral ? 'ephemeral' : 'normal'
      ..fields['content_type'] = 'drawing'
      ..fields['stroke_data'] = strokeJson
      ..files.add(http.MultipartFile.fromBytes('drawing', png, filename: 'd.png'));
    if (parentId != null) req.fields['parent_id'] = parentId;
    final resp = await http.Response.fromStream(await req.send());
    return doodleFrom(_ok(resp) as Map);
  }

  /// 확인 → {expires_at}
  Future<DateTime?> view(String doodleId) async {
    final j = await _post('/doodles/$doodleId/view') as Map;
    final e = j['expires_at'];
    return e == null ? null : DateTime.tryParse(e as String);
  }

  // ---- 찌르기 ----
  Future<void> poke(String gid, String toUserId) async {
    await _post('/groups/$gid/pokes', {'to_user_id': toUserId});
  }

  // ---- 스토어 (#13) ----
  Future<Map<String, dynamic>> store(String gid) async =>
      Map<String, dynamic>.from(await _get('/groups/$gid/store') as Map);

  /// 구매 → 구매 후 잔액 코인.
  Future<int> buyItem(String gid, String itemId) async {
    final j = await _post('/groups/$gid/store/$itemId/buy') as Map;
    return (j['coins'] as num).toInt();
  }

  Future<void> equipItem(String gid, String itemId, bool equipped) async {
    await _post('/groups/$gid/store/$itemId/equip', {'equipped': equipped});
  }

  // ---- 사진첩 AI 큐레이션 (#6) ----
  Future<List<Map<String, dynamic>>> albums(String gid) async {
    final j = await _get('/groups/$gid/albums') as Map;
    final items = (j['albums'] as List? ?? const []);
    return [for (final a in items) Map<String, dynamic>.from(a as Map)];
  }

  // ---- 이웃집 (#15) ----
  Future<Map<String, dynamic>?> randomNeighbor() async {
    final j = await _get('/neighbors/random') as Map;
    final n = j['neighbor'];
    return n == null ? null : Map<String, dynamic>.from(n as Map);
  }

  Future<Map<String, dynamic>?> neighborByCode(String code) async {
    final j = await _get('/neighbors/by-code/$code') as Map;
    final n = j['neighbor'];
    return n == null ? null : Map<String, dynamic>.from(n as Map);
  }

  /// 이웃 펫 좋아요 → 갱신된 좋아요 수.
  Future<int> likeNeighbor(String petId) async {
    final j = await _post('/neighbors/$petId/like') as Map;
    return (j['likes'] as num).toInt();
  }

  // ---- 오늘의 질문 (E-1) ----
  Future<Map<String, dynamic>> question(String gid) async =>
      Map<String, dynamic>.from(await _get('/groups/$gid/question/today') as Map);

  Future<Map<String, dynamic>> answer(String gid, String text) async =>
      Map<String, dynamic>.from(
          await _post('/groups/$gid/question/today', {'answer': text}) as Map);

  // ---- 매핑: 서버 DoodleOut → 앱 Doodle ----
  Doodle doodleFrom(Map j) {
    final ct = '${j['content_type']}';
    final type = ct == 'photo'
        ? DoodleType.photo
        : ct == 'drawing'
            ? DoodleType.drawing
            : DoodleType.text;
    final photo = j['photo_url'] as String?;
    final drawing = j['drawing_url'] as String?;
    final img = photo ?? drawing;
    return Doodle(
      id: '${j['id']}',
      fromMe: '${j['sender_id']}' == myUserId,
      type: type,
      imageUrl: img == null ? null : media(img),
      thumbUrl: j['thumb_url'] == null ? null : media(j['thumb_url'] as String),
      text: j['text_body'] as String?,
      caption: j['caption'] as String?,
      when: _rel(j['created_at'] as String?),
      at: DateTime.tryParse('${j['created_at']}')?.toLocal(),
      ephemeral: '${j['mode']}' == 'ephemeral',
      viewed: j['viewed_by_me'] == true,
      replies: (j['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}

String _rel(String? iso) {
  if (iso == null) return '';
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return '방금 전';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays == 1) return '어제';
  return '${t.month}월 ${t.day}일';
}
