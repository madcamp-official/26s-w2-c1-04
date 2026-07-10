// Memory Pager — the real HTTP client.
//
// A [Repository] over the tunnel API (docs/API.md §0). This is for later — the
// app ships against [MockRepository] first — but it compiles now and implements
// the straightforward reads/writes so it can be swapped in without touching
// callers. Every request carries `Authorization: Bearer <token>` except
// register.
//
// Conventions honoured:
//   - Base URL ends in `/v1`; paths below are relative to it.
//   - IDs are strings; the models parse them.
//   - Errors arrive as `{ "error": { code, message } }` and become
//     [ApiException] with the HTTP status, so callers split 404 from 410.
//   - sendDoodle is `multipart/form-data`.
//   - PATCHes that return an aggregate re-GET it (the API doesn't guarantee a
//     response body on PATCH), which keeps this faithful to "REST가 진실이다".

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'repository.dart';

class RestRepository implements Repository {
  RestRepository({
    required String baseUrl,
    this.token,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// The bearer token. Set/replace it after `register` (or on restore).
  String? token;

  // ===========================================================================
  // Auth / onboarding
  // ===========================================================================

  @override
  Future<AuthResult> register(String displayName, String deviceUid) async {
    final json = await _send(
      'POST',
      '/auth/register',
      body: {'display_name': displayName, 'device_uid': deviceUid},
      auth: false,
    );
    final result = AuthResult.fromJson(json as Map<String, dynamic>);
    token = result.token; // adopt the freshly issued token
    return result;
  }

  @override
  Future<Me> getMe() async {
    final json = await _send('GET', '/me');
    return Me.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> updateMe(String displayName) async {
    await _send('PATCH', '/me', body: {'display_name': displayName});
  }

  // ===========================================================================
  // Groups
  // ===========================================================================

  @override
  Future<GroupPet> createGroup(String name, String petName) async {
    final json = await _send(
      'POST',
      '/groups',
      body: {'name': name, 'pet_name': petName},
    );
    return _groupPet(json as Map<String, dynamic>);
  }

  @override
  Future<GroupPet> joinGroup(String inviteCode) async {
    final json = await _send(
      'POST',
      '/groups/join',
      body: {'invite_code': inviteCode},
    );
    return _groupPet(json as Map<String, dynamic>);
  }

  @override
  Future<Group> getGroup(String id) async {
    final json = await _send('GET', '/groups/$id');
    return Group.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Group> updateGroup(String id, {String? name, String? backgroundColor}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (backgroundColor != null) body['background_color'] = backgroundColor;
    await _send('PATCH', '/groups/$id', body: body);
    return getGroup(id); // re-read the updated aggregate
  }

  @override
  Future<Group> setNickname(String groupId, String userId, String nickname) async {
    await _send(
      'PATCH',
      '/groups/$groupId/members/$userId',
      body: {'nickname': nickname},
    );
    return getGroup(groupId);
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
    final req = http.MultipartRequest('POST', _uri('/doodles'));
    req.headers.addAll(_authHeaders());

    req.fields['mode'] = mode.toJson();
    req.fields['content_type'] = contentType.toJson();
    if (parentId != null) req.fields['parent_id'] = parentId;
    if (textBody != null) req.fields['text_body'] = textBody;
    if (strokeData != null) {
      req.fields['stroke_data'] = jsonEncode(strokeData.toJson());
    }
    if (photoBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: 'photo.jpg',
      ));
    }
    if (drawingBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'drawing',
        drawingBytes,
        filename: 'drawing.png',
      ));
    }

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final json = _decode(res);
    return Doodle.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<DoodlePage> listDoodles(
    String groupId, {
    String? before,
    int? limit,
    ContentType? contentType,
    DateTime? date,
  }) async {
    final query = <String, String>{};
    if (before != null) query['before'] = before;
    if (limit != null) query['limit'] = '$limit';
    if (contentType != null) query['content_type'] = contentType.toJson();
    if (date != null) query['date'] = _fmtDate(date);

    final json = await _send('GET', '/groups/$groupId/doodles', query: query);
    return _doodlePage(json as Map<String, dynamic>);
  }

  @override
  Future<Doodle> getDoodle(String id) async {
    final json = await _send('GET', '/doodles/$id');
    return Doodle.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<DateTime?> viewDoodle(String id) async {
    final json = await _send('POST', '/doodles/$id/view');
    final map = json as Map<String, dynamic>;
    final v = map['expires_at'];
    return v == null ? null : DateTime.parse(v as String).toUtc();
  }

  @override
  Future<void> poke(String groupId, String toUserId) async {
    await _send('POST', '/groups/$groupId/pokes', body: {'to_user_id': toUserId});
  }

  // ===========================================================================
  // Pet
  // ===========================================================================

  @override
  Future<Pet> getPet(String groupId) async {
    final json = await _send('GET', '/groups/$groupId/pet');
    return Pet.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<PatResult> pat(String petId) async {
    final json = await _send('POST', '/pets/$petId/pat');
    return PatResult.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<DiaryPage> listDiaries(String petId, {String? before, int? limit}) async {
    final query = <String, String>{};
    if (before != null) query['before'] = before;
    if (limit != null) query['limit'] = '$limit';

    final json = await _send('GET', '/pets/$petId/diaries', query: query);
    final map = json as Map<String, dynamic>;
    final items = (map['items'] as List? ?? const [])
        .map((e) => Diary.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextBefore: map['next_before'] as String?);
  }

  @override
  Future<Diary> getDiary(String petId, DateTime entryDate) async {
    final json = await _send('GET', '/pets/$petId/diaries/${_fmtDate(entryDate)}');
    return Diary.fromJson(json as Map<String, dynamic>);
  }

  // ===========================================================================
  // Monthly report
  // ===========================================================================

  @override
  Future<List<ReportSummary>> listReports(String groupId) async {
    final json = await _send('GET', '/groups/$groupId/reports');
    final items = (json as Map<String, dynamic>)['items'] as List? ?? const [];
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return (
        month: m['report_month'] as String,
        generatedAt: DateTime.parse(m['generated_at'] as String).toUtc(),
      );
    }).toList();
  }

  @override
  Future<MonthlyReport> getReport(String groupId, String month) async {
    final json = await _send('GET', '/groups/$groupId/reports/$month');
    return MonthlyReport.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<MonthlyReport> generateReport(String groupId, String month) async {
    final json = await _send('POST', '/groups/$groupId/reports/$month/generate');
    return MonthlyReport.fromJson(json as Map<String, dynamic>);
  }

  // ===========================================================================
  // Widget
  // ===========================================================================

  @override
  Future<WidgetData?> getWidget(String groupId) async {
    final json = await _send('GET', '/widget/$groupId', allow404: true);
    if (json == null) return null;
    return WidgetData.fromJson(json as Map<String, dynamic>);
  }

  // ===========================================================================
  // Store / inventory
  // ===========================================================================

  @override
  Future<List<Item>> listItems({ItemCategory? category}) async {
    final query = <String, String>{};
    if (category != null) query['category'] = category.toJson();
    final json = await _send('GET', '/items', query: query);
    // Accept either a bare list or `{ items: [...] }`.
    final list = json is List
        ? json
        : ((json as Map<String, dynamic>)['items'] as List? ?? const []);
    return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> buyItem(String petId, String itemId) async {
    await _send('POST', '/pets/$petId/items', body: {'item_id': itemId});
  }

  @override
  Future<void> updatePetItem(
    String petId,
    String itemId, {
    bool? isEquipped,
    int? posX,
    int? posY,
  }) async {
    final body = <String, dynamic>{};
    if (isEquipped != null) body['is_equipped'] = isEquipped;
    if (posX != null) body['pos_x'] = posX;
    if (posY != null) body['pos_y'] = posY;
    await _send('PATCH', '/pets/$petId/items/$itemId', body: body);
  }

  // ===========================================================================
  // Explore
  // ===========================================================================

  @override
  Future<ExplorePage> explorePets({String? before, int? limit}) async {
    final query = <String, String>{};
    if (before != null) query['before'] = before;
    if (limit != null) query['limit'] = '$limit';
    final json = await _send('GET', '/pets/explore', query: query);
    final map = json as Map<String, dynamic>;
    final items = (map['items'] as List? ?? const [])
        .map((e) => ExplorePet.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextBefore: map['next_before'] as String?);
  }

  @override
  Future<ExplorePet> petByCode(String inviteCode) async {
    final json = await _send('GET', '/pets/by-code/$inviteCode');
    return ExplorePet.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> likePet(String petId) async {
    await _send('POST', '/pets/$petId/like');
  }

  @override
  Future<void> unlikePet(String petId) async {
    await _send('DELETE', '/pets/$petId/like');
  }

  // ===========================================================================
  // Transport
  // ===========================================================================

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: {...u.queryParameters, ...query});
  }

  Map<String, String> _authHeaders() =>
      token == null ? {} : {'Authorization': 'Bearer $token'};

  /// Send a JSON request. Returns the decoded body (`Map`/`List`), or `null`
  /// for 204 / (with [allow404]) 404. Throws [ApiException] on other errors.
  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
    bool allow404 = false,
  }) async {
    final headers = <String, String>{
      if (auth) ..._authHeaders(),
      if (body != null) 'Content-Type': 'application/json',
    };
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);

    final http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(uri, headers: headers);
      case 'POST':
        res = await _client.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        res = await _client.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        res = await _client.delete(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    if (allow404 && res.statusCode == 404) return null;
    return _decode(res);
  }

  /// Decode a response, throwing [ApiException] on non-2xx.
  Object? _decode(http.Response res) {
    if (res.statusCode == 204 || res.body.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
    }

    Object? parsed;
    try {
      parsed = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      parsed = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return parsed;

    // Error path — parse the `{ error: {...} }` envelope if present.
    if (parsed is Map<String, dynamic> && parsed['error'] is Map) {
      throw ApiException.fromEnvelope(res.statusCode, parsed);
    }
    throw ApiException(
      ApiError(code: 'http_${res.statusCode}', message: res.reasonPhrase ?? 'HTTP error'),
      res.statusCode,
    );
  }

  // -- parse helpers --------------------------------------------------------

  GroupPet _groupPet(Map<String, dynamic> json) => (
        group: Group.fromJson(json['group'] as Map<String, dynamic>),
        pet: Pet.fromJson(json['pet'] as Map<String, dynamic>),
      );

  DoodlePage _doodlePage(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((e) => Doodle.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextBefore: json['next_before'] as String?);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Release the underlying client.
  void close() => _client.close();
}
