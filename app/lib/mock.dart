// 데모 상태 — 디자인의 샘플 세계(지우·나무늘보·모리)를 그대로 담는다.
// 전역 싱글턴 [mock] 하나. 화면들은 이걸 읽고 쓴 뒤 notifyListeners 로 갱신된다.

import 'package:flutter/material.dart';

import 'api.dart';
import 'realtime.dart';
import 'theme.dart';

enum DoodleType { photo, text, drawing }

class Doodle {
  Doodle({
    required this.id,
    required this.fromMe,
    required this.type,
    this.asset,
    this.imageUrl,
    this.thumbUrl,
    this.text,
    this.caption,
    required this.when,
    this.ephemeral = false,
    this.viewed = true,
    this.replies = 0,
  });

  final String id;
  final bool fromMe; // true = 나, false = 상대
  final DoodleType type;
  final String? asset; // 데모: assets/photos/...
  final String? imageUrl; // 실서버: photo_url/drawing_url 에 호스트 붙인 절대 URL
  final String? thumbUrl; // 실서버: thumb_url 절대 URL
  final String? text; // 텍스트 낙서 본문
  final String? caption; // 데모: 사진/그림 위 손글씨 오버레이
  final String when; // '방금 전' '5분 전' '어제' ...
  final bool ephemeral;
  bool viewed;
  final int replies;

  /// 네트워크 이미지가 있으면 실서버 낙서. 화면 렌더가 이걸로 asset↔network 를 고른다.
  bool get isRemote => imageUrl != null;
}

class DiaryEntry {
  const DiaryEntry({
    required this.dateLabel,
    required this.caption,
    this.isNew = false,
    this.scene = 0, // 0: 손잡은 우리, 1: 떡볶이
  });

  final String dateLabel; // '7월 13일 맑음'
  final String caption;
  final bool isNew;
  final int scene;
}

class StoreItem {
  StoreItem(this.name, this.price, {this.wearing = false});

  final String name;
  final int price;
  bool wearing;
}

class AppMock extends ChangeNotifier {
  // ---- 사람 · 그룹 (디자인 샘플)
  String myName = '지우';
  String partnerName = '나무';
  String partnerNick = '나무늘보';
  String groupName = '지우 ♥ 나무';
  String inviteCode = 'PAGER-0713';
  int dDay = 412;
  bool onboarded = true; // 데모는 온보딩 완료 상태로 부팅. 설정의 로그아웃으로 리셋.

  // ---- 펫
  String petName = '모리';
  int petLevel = 3;
  int coins = 1240;
  double get growthPct => (petLevel * 20).clamp(0, 100) / 100;
  String get levelLabel => 'Lv.$petLevel';
  double get petSize => 96 + petLevel * 12; // 디자인 props: 96+level*12

  // ---- roomColor (설정 4g 스와치)
  Color roomColor = roomColors[0];

  // ---- 상호작용
  int pokesToday = 3;
  String petBubble = '오늘도 낙서 기다리는 중… 삐삐!';

  // ---- 오늘의 질문 (1c)
  String question = '서로 처음 만난 날, 가장 기억에 남는 순간은?';
  bool partnerAnswered = true;
  String? myAnswer;

  // ---- 낙서들 (디자인 샘플 콘텐츠)
  final List<Doodle> doodles = [
    Doodle(
      id: 'd1',
      fromMe: false,
      type: DoodleType.photo,
      asset: 'assets/photos/photo_field.png',
      caption: '오늘 억새밭!!',
      when: '방금 전',
      viewed: false,
      replies: 2,
    ),
    Doodle(
      id: 'd2',
      fromMe: true,
      type: DoodleType.text,
      text: '퇴근하고 떡볶이 ㄱ? ♥',
      when: '어제',
    ),
    Doodle(
      id: 'd3',
      fromMe: false,
      type: DoodleType.photo,
      asset: 'assets/photos/photo_sky.png',
      caption: '오늘 하늘 예쁘다 ♥',
      when: '7월 11일',
    ),
    Doodle(
      id: 'd4',
      fromMe: true,
      type: DoodleType.text,
      text: '배고파 ♥',
      when: '7월 10일',
    ),
  ];

  Doodle? get latestFromPartner {
    for (final d in doodles) {
      if (!d.fromMe) return d;
    }
    return null;
  }

  // ---- 그림 일기장 (4f)
  final List<DiaryEntry> diary = const [
    DiaryEntry(
      dateLabel: '7월 13일 맑음',
      caption: '오늘은 둘이 억새밭 얘기를 했다. 나도 데려가 줬으면…',
      isNew: true,
      scene: 0,
    ),
    DiaryEntry(
      dateLabel: '7월 11일 흐림',
      caption: '떡볶이가 뭐길래 이렇게 자주 나올까. 나도 먹어보고 싶다.',
      scene: 1,
    ),
  ];

  // ---- 스토어 (1g 모자 탭)
  final List<StoreItem> hats = [
    StoreItem('중절모', 0, wearing: true),
    StoreItem('밀짚모자', 300),
    StoreItem('딸기베레모', 450),
    StoreItem('비니', 280),
    StoreItem('새싹핀', 150),
    StoreItem('리본', 200),
  ];

  // ---- 월간 레포트 (1f)
  final int reportPhotos = 12, reportDrawings = 8, reportTexts = 5;
  final int reportPokes = 47, reportDoodles = 25, reportAnswers = 30;

  // ==== 실서버 모드 (api != null 이면 실물, null 이면 데모) ====
  Api? api;
  Rt? rt;
  String? groupId;
  String? petId;
  String? partnerUserId;
  String? bootstrapError;
  bool get real => api != null;

  /// API_BASE 가 주어지면 실서버로 부팅한다. register → /me → (그룹 있으면 로드).
  Future<void> bootstrapReal(String base, String deviceUid, String name) async {
    final a = Api(base);
    api = a;
    myName = name;
    try {
      await a.register(name, deviceUid);
      final m = await a.me();
      final u = m['user'] as Map?;
      if (u != null) myName = '${u['display_name']}';
      final g = m['group'];
      if (g != null) {
        groupId = '${(g as Map)['id']}';
        onboarded = true;
        await _loadAll();
      } else {
        onboarded = false; // 온보딩으로
      }
    } catch (e) {
      bootstrapError = '$e';
      onboarded = false;
    }
    notifyListeners();
  }

  void _applyGroup(Map g) {
    groupId = '${g['id']}';
    groupName = '${g['name']}';
    inviteCode = '${g['invite_code']}';
    final bg = '${g['background_color']}';
    roomColor = _hexRoom(bg);
    final members = (g['members'] as List? ?? const []);
    for (final mm in members) {
      final m = mm as Map;
      if ('${m['user_id']}' != api?.myUserId) {
        partnerUserId = '${m['user_id']}';
        partnerName = '${m['display_name']}';
        partnerNick = m['nickname'] != null ? '${m['nickname']}' : '${m['display_name']}';
      }
    }
    final created = g['created_at'];
    if (created != null) {
      final c = DateTime.tryParse('$created');
      if (c != null) dDay = DateTime.now().toUtc().difference(c).inDays;
    }
  }

  Future<void> _loadAll() async {
    final a = api!;
    final gid = groupId!;
    final p = await a.pet(gid);
    petId = '${p['id']}';
    petName = '${p['name']}';
    petLevel = (p['level'] as num).toInt();
    coins = (p['coins'] as num).toInt();
    doodles
      ..clear()
      ..addAll(await a.doodles(gid));
    final q = await a.question(gid);
    question = '${q['text']}';
    myAnswer = q['my_answer'] as String?;
    partnerAnswered = q['partner_answered'] == true;
    // 실시간 연결
    rt = Rt(a.host, a.token!)..onEvent = _onRtEvent;
    await rt!.connect();
    notifyListeners();
  }

  Future<void> _onRtEvent(String event, Map data) async {
    switch (event) {
      case 'doodle:new':
        if (real && groupId != null) {
          doodles
            ..clear()
            ..addAll(await api!.doodles(groupId!));
          notifyListeners();
        }
      case 'doodle:expired':
        doodles.removeWhere((d) => d.id == '${data['doodle_id']}');
        notifyListeners();
      case 'poke':
        // 상대가 나를 찔렀다 — 알림 뱃지용(간단 처리).
        notifyListeners();
      case 'pet:activity':
        petBubble = '${data['utterance']}';
        notifyListeners();
      case 'pet:levelup':
        petLevel = (data['level'] as num?)?.toInt() ?? petLevel;
        notifyListeners();
    }
  }

  static Color _hexRoom(String hex6) {
    final v = int.tryParse(hex6, radix: 16);
    return v == null ? roomColors[0] : Color(0xFF000000 | v);
  }

  // ---- 행동 (dual-mode) ----
  Future<void> poke() async {
    pokesToday += 1;
    notifyListeners();
    if (real && groupId != null && partnerUserId != null) {
      try {
        await api!.poke(groupId!, partnerUserId!);
      } catch (_) {}
    }
  }

  Future<void> pat() async {
    if (real && petId != null) {
      try {
        final r = await api!.pat(petId!);
        petBubble = '${r['utterance']}';
        notifyListeners();
        return;
      } catch (_) {}
    }
    petBubble = [
      '삐삐! 나 여기 있어',
      '쓰다듬 최고야…',
      '오늘도 낙서 기다리는 중… 삐삐!',
      '억새밭 얘기 또 해줘!',
    ][DateTime.now().second % 4];
    notifyListeners();
  }

  Future<void> answer(String v) async {
    myAnswer = v;
    notifyListeners();
    if (real && groupId != null) {
      try {
        final r = await api!.answer(groupId!, v);
        myAnswer = r['my_answer'] as String?;
        partnerAnswered = r['partner_answered'] == true;
        notifyListeners();
      } catch (_) {}
    }
  }

  void setRoomColor(Color c) {
    roomColor = c;
    notifyListeners();
    if (real && groupId != null) {
      final hex = c.toARGB32().toRadixString(16).substring(2).toUpperCase();
      api!.updateGroup(groupId!, bgColor: hex).catchError((_) {});
    }
  }

  /// 텍스트/그림 전송. 실서버면 서버에 올리고 목록을 앞에 추가한다.
  Future<void> sendText(String text, {bool ephemeral = false}) async {
    if (real && groupId != null) {
      try {
        final d = await api!.sendText(text, ephemeral: ephemeral);
        doodles.insert(0, d);
        notifyListeners();
        return;
      } catch (_) {}
    }
    doodles.insert(0,
        Doodle(id: 'local-${doodles.length}', fromMe: true, type: DoodleType.text, text: text, when: '방금 전', ephemeral: ephemeral));
    notifyListeners();
  }

  Future<void> sendDrawing(List<int> png, String strokeJson, {bool ephemeral = false}) async {
    if (real && groupId != null) {
      try {
        final d = await api!.sendDrawing(png, strokeJson, ephemeral: ephemeral);
        doodles.insert(0, d);
        notifyListeners();
        return;
      } catch (_) {}
    }
    doodles.insert(0,
        Doodle(id: 'local-${doodles.length}', fromMe: true, type: DoodleType.drawing, when: '방금 전', ephemeral: ephemeral));
    notifyListeners();
  }

  Future<void> markViewed(Doodle d) async {
    d.viewed = true;
    notifyListeners();
    if (real) {
      try {
        await api!.view(d.id);
      } catch (_) {}
    }
  }

  /// 화면이 상태를 직접 바꾼 뒤 갱신을 트리거할 때(데모 전송 등).
  void refresh() => notifyListeners();

  void wear(StoreItem item) {
    for (final h in hats) {
      h.wearing = false;
    }
    item.wearing = true;
    notifyListeners();
  }

  void rename(String v) {
    if (v.isNotEmpty) myName = v;
    notifyListeners();
  }

  void setPartnerNick(String v) {
    if (v.isNotEmpty) partnerNick = v;
    notifyListeners();
    if (real && groupId != null && partnerUserId != null) {
      api!.setNickname(groupId!, partnerUserId!, v).catchError((_) {});
    }
  }

  void setGroupName(String v) {
    if (v.isNotEmpty) groupName = v;
    notifyListeners();
    if (real && groupId != null) {
      api!.updateGroup(groupId!, name: v).catchError((_) {});
    }
  }

  void resetToOnboarding() {
    onboarded = false;
    notifyListeners();
  }

  /// 온보딩 완료. 실서버면 그룹 생성 또는 참여를 서버에 반영한다.
  Future<void> completeOnboarding({String? name, String? joinCode}) async {
    if (name != null && name.isNotEmpty) myName = name;
    if (real) {
      try {
        if (name != null && name.isNotEmpty) await api!.updateMe(name);
        final Map res = joinCode != null && joinCode.isNotEmpty
            ? await api!.joinGroup(joinCode)
            : await api!.createGroup(groupName, petName);
        _applyGroup(res['group'] as Map);
        onboarded = true;
        await _loadAll();
        return;
      } catch (e) {
        bootstrapError = '$e';
        notifyListeners();
        return;
      }
    }
    onboarded = true;
    notifyListeners();
  }
}

final AppMock mock = AppMock();

/// 낙서 이미지 렌더 — 실서버(network) ↔ 데모(asset) 자동 선택.
Widget doodleImage(Doodle d, {BoxFit fit = BoxFit.cover}) {
  final url = d.imageUrl;
  if (url != null) {
    return Image.network(url, fit: fit,
        errorBuilder: (ctx, err, st) => Container(color: paperCard),
        loadingBuilder: (ctx, child, p) =>
            p == null ? child : Container(color: paperCard));
  }
  if (d.asset != null) return Image.asset(d.asset!, fit: fit);
  return Container(color: paperCard);
}
