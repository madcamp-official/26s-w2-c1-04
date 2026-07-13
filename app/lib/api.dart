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
    _fail(r);
  }

  Future<dynamic> _get(String p) async =>
      _ok(await http.get(Uri.parse('$_base$p'), headers: _h));

  Future<dynamic> _post(String p, [Object? body]) async => _ok(await http.post(
        Uri.parse('$_base$p'),
        headers: _h,
        body: body == null ? null : jsonEncode(body),
      ));

  // ---- 인증 · 온보딩 ----
  Future<void> register(String displayName, String deviceUid) async {
    final j = await _post('/auth/register',
        {'display_name': displayName, 'device_uid': deviceUid});
    token = j['token'] as String;
    myUserId = '${j['user']['id']}';
  }

  /// {user, group|null}
  Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from(await _get('/me') as Map);

  Future<Map<String, dynamic>> createGroup(String name, String petName) async =>
      Map<String, dynamic>.from(
          await _post('/groups', {'name': name, 'pet_name': petName}) as Map);

  Future<Map<String, dynamic>> joinGroup(String code) async =>
      Map<String, dynamic>.from(
          await _post('/groups/join', {'invite_code': code}) as Map);

  Future<void> updateMe(String displayName) async {
    await http.patch(Uri.parse('$_base/me'),
        headers: _h, body: jsonEncode({'display_name': displayName}));
  }

  Future<void> updateGroup(String gid, {String? name, String? bgColor}) async {
    await http.patch(Uri.parse('$_base/groups/$gid'),
        headers: _h,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (bgColor != null) 'background_color': bgColor,
        }));
  }

  Future<void> setNickname(String gid, String targetUserId, String nick) async {
    await http.patch(Uri.parse('$_base/groups/$gid/members/$targetUserId'),
        headers: _h, body: jsonEncode({'nickname': nick}));
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

  /// 가장 최근 달의 레포트. 없으면 null(신규 그룹).
  Future<Map<String, dynamic>?> latestReport(String gid) async {
    final j = await _get('/groups/$gid/reports') as Map;
    final items = (j['items'] as List? ?? const []);
    if (items.isEmpty) return null;
    final months = [for (final it in items) '${(it as Map)['report_month']}']
      ..sort();
    final month = months.last; // 최신 달
    return Map<String, dynamic>.from(
        await _get('/groups/$gid/reports/$month') as Map);
  }

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
      when: _rel(j['created_at'] as String?),
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
