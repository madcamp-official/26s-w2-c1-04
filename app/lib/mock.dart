// 데모 상태 — 디자인의 샘플 세계(지우·나무늘보·모리)를 그대로 담는다.
// 전역 싱글턴 [mock] 하나. 화면들은 이걸 읽고 쓴 뒤 notifyListeners 로 갱신된다.

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

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
    this.imageUrl, // 실서버 생성 이미지(있으면 scene 대신 이걸 렌더)
  });

  final String dateLabel; // '7월 13일 맑음'
  final String caption;
  final bool isNew;
  final int scene;
  final String? imageUrl;

  bool get isRemote => imageUrl != null && imageUrl!.isNotEmpty;
}

class StoreItem {
  StoreItem(this.name, this.price, {this.wearing = false, bool? owned})
      : owned = owned ?? (price == 0); // 무료(중절모)는 기본 보유

  final String name;
  final int price;
  bool wearing;
  bool owned; // 구매했는지(세션 로컬 — 서버 구매 API 없음)
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
      if (!d.fromMe && !d.viewed) return d; // 이미 본 낙서는 "새 낙서"가 아니다
    }
    return null;
  }

  // ---- 그림 일기장 (4f) — 실서버 모드에선 _loadAll 에서 교체된다.
  final List<DiaryEntry> diary = [
    const DiaryEntry(
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

  // ---- 월간 레포트 (1f) — 실서버 모드에선 _loadAll 에서 최신 달 값으로 교체.
  int reportPhotos = 12, reportDrawings = 8, reportTexts = 5;
  int reportPokes = 47, reportDoodles = 25, reportAnswers = 30;
  List<String> reportMonths = const []; // 'YYYY-MM' 오름차순(실서버)
  int _reportIdx = -1; // reportMonths 내 현재 위치(-1=데모/없음)

  String get reportMonthLabel {
    if (_reportIdx < 0 || _reportIdx >= reportMonths.length) {
      return real ? '—' : '6월'; // 실서버·리포트 없음이면 가짜 달을 안 보여준다
    }
    final p = reportMonths[_reportIdx].split('-');
    return p.length == 2 ? '${int.parse(p[1])}월' : reportMonths[_reportIdx];
  }

  bool get canPrevReport => _reportIdx > 0;
  bool get canNextReport =>
      _reportIdx >= 0 && _reportIdx < reportMonths.length - 1;

  Future<void> shiftReportMonth(int delta) async {
    if (!real) return;
    final ni = _reportIdx + delta;
    if (ni < 0 || ni >= reportMonths.length) return;
    _reportIdx = ni;
    try {
      await _loadReportMonth(reportMonths[ni]);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadReportMonth(String month) async {
    final rep = await api!.report(groupId!, month);
    reportPhotos = (rep['photo_count'] as num?)?.toInt() ?? 0;
    reportDrawings = (rep['drawing_count'] as num?)?.toInt() ?? 0;
    reportTexts = (rep['text_count'] as num?)?.toInt() ?? 0;
    reportPokes = (rep['poke_count'] as num?)?.toInt() ?? 0;
    reportDoodles = reportPhotos + reportDrawings + reportTexts;
    reportAnswers = 0; // 레포트엔 질문 답변 집계 없음(백엔드 미제공)
  }

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
        final gid = '${(g as Map)['id']}';
        groupId = gid;
        onboarded = true;
        // /me 의 group 은 {id,name}뿐이라 상세(초대코드·상대·D-day)를 따로 복원한다.
        _applyGroup(await a.group(gid));
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

  /// FCM 토큰을 서버에 등록한다(push.dart 의 initPush 콜백). 실서버 모드에서만.
  Future<void> registerPushToken(String token) async {
    final a = api;
    if (a == null) return;
    try {
      await a.registerDevice(token);
    } catch (_) {
      // 푸시 등록 실패는 앱 사용을 막지 않는다(보조 전달 경로).
    }
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
    // 활동 표정: 서버의 current_activity 를 말풍선에 반영(없으면 기본 유지)
    final act = p['current_activity'];
    if (act is Map && act['activity'] != null) {
      petBubble = _activityUtterance('${act['activity']}');
    }
    // 착용 아이템: hat 카테고리가 걸려 있으면 모자를 씌운다(실서버 상태 반영)
    final items = (p['equipped_items'] as List?) ?? const [];
    final wearingHat =
        items.any((it) => it is Map && it['category'] == 'hat');
    for (final h in hats) {
      h.wearing = false;
    }
    if (wearingHat && hats.isNotEmpty) hats.first.wearing = true;
    doodles
      ..clear()
      ..addAll(await a.doodles(gid));
    // 그림 일기 (서버 생성 이미지). 신규 그룹은 빈 리스트가 정상.
    await _reloadDiaries();
    // 월간 레포트 — 있는 달 목록을 받아 최신 달을 로드(월 이동은 shiftReportMonth).
    reportMonths = await a.reportMonths(gid);
    if (reportMonths.isNotEmpty) {
      _reportIdx = reportMonths.length - 1;
      await _loadReportMonth(reportMonths[_reportIdx]);
    } else {
      _reportIdx = -1;
      reportPhotos = reportDrawings = reportTexts = 0;
      reportPokes = reportDoodles = reportAnswers = 0;
    }
    final q = await a.question(gid);
    question = '${q['text']}';
    myAnswer = q['my_answer'] as String?;
    partnerAnswered = q['partner_answered'] == true;
    // 실시간 연결
    rt = Rt(a.host, a.token!)..onEvent = _onRtEvent;
    await rt!.connect();
    _syncWidget(); // 홈 위젯 갱신(펫 이름·레벨·말풍선)
    notifyListeners();
  }

  // 서버 활동 키 → 말풍선. 백엔드 ACTIVITIES(eating/sleeping/…) 와 값이 같아야 한다.
  static const _activityText = {
    'eating': '밥 먹는 중! 오늘 뭐 했어?',
    'sleeping': '방금 밥 먹고 졸려…',
    'walking': '산책 나왔어. 날씨 좋다!',
    'playing': '심심해서 혼자 놀고 있었어.',
    'drawing': '너희 그림 따라 그려보는 중이야.',
    'waiting': '언제 오나 기다리고 있었어.',
  };
  String _activityUtterance(String key) => _activityText[key] ?? petBubble;

  // 서버 image_url 을 절대 URL 로. 이미 http면 그대로, 상대경로면 호스트를 붙인다.
  String _mediaUrl(String p) {
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    return api?.media(p) ?? p;
  }

  // '2026-07-13' → '7월 13일'. 파싱 실패하면 원문.
  String _diaryDateLabel(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : '${d.month}월 ${d.day}일';
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
        _syncWidget();
        notifyListeners();
      case 'pet:levelup':
        petLevel = (data['level'] as num?)?.toInt() ?? petLevel;
        _syncWidget();
        notifyListeners();
      case 'diary:new':
        // 펫이 새 그림 일기를 그렸다 — 일기 목록을 다시 불러온다.
        if (real && petId != null) {
          try {
            await _reloadDiaries();
            notifyListeners();
          } catch (_) {}
        }
    }
  }

  /// 홈 화면 위젯에 펫 상태를 밀어넣는다(Android). 다른 플랫폼/데모는 조용히 무시.
  Future<void> _syncWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('pet_name', petName);
      await HomeWidget.saveWidgetData<String>('pet_level', levelLabel);
      await HomeWidget.saveWidgetData<String>('pet_bubble', petBubble);
      await HomeWidget.updateWidget(androidName: 'PagerWidgetProvider');
    } catch (_) {
      // 위젯 미지원 플랫폼(웹/데스크톱/테스트)에서는 조용히 넘어간다.
    }
  }

  /// 서버에서 그림 일기를 받아 diary 리스트를 교체한다. (_loadAll · diary:new 공용)
  Future<void> _reloadDiaries() async {
    final ds = await api!.diaries(petId!);
    diary
      ..clear()
      ..addAll([
        for (var i = 0; i < ds.length; i++)
          DiaryEntry(
            dateLabel: _diaryDateLabel('${ds[i]['entry_date'] ?? ''}'),
            caption: '${ds[i]['caption'] ?? ''}',
            isNew: i == 0,
            imageUrl: _mediaUrl('${ds[i]['image_url'] ?? ''}'),
          ),
      ]);
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
    final old = roomColor;
    roomColor = c;
    notifyListeners();
    if (real && groupId != null) {
      final hex = c.toARGB32().toRadixString(16).substring(2).toUpperCase();
      api!.updateGroup(groupId!, bgColor: hex).catchError((Object _) {
        roomColor = old; // 서버 반영 실패 시 되돌린다(가짜 성공 금지)
        notifyListeners();
      });
    }
  }

  /// 텍스트/그림 전송. 실서버면 서버에 올린다.
  /// 실서버 전송이 실패하면 예외를 그대로 던진다(화면이 실패를 표시하도록 — 가짜 성공 금지).
  Future<void> sendText(String text,
      {bool ephemeral = false, String? parentId}) async {
    if (real && groupId != null) {
      final d = await api!.sendText(text, ephemeral: ephemeral, parentId: parentId);
      // 소켓 doodle:new 리로드가 먼저 도착해 이미 넣었을 수 있으므로 중복 방지.
      if (!doodles.any((x) => x.id == d.id)) doodles.insert(0, d);
      notifyListeners();
      return;
    }
    doodles.insert(0,
        Doodle(id: 'local-${doodles.length}', fromMe: true, type: DoodleType.text, text: text, when: '방금 전', ephemeral: ephemeral));
    notifyListeners();
  }

  Future<void> sendDrawing(List<int> png, String strokeJson,
      {bool ephemeral = false, String? parentId}) async {
    if (real && groupId != null) {
      final d = await api!.sendDrawing(png, strokeJson,
          ephemeral: ephemeral, parentId: parentId);
      if (!doodles.any((x) => x.id == d.id)) doodles.insert(0, d);
      notifyListeners();
      return;
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

  /// 아이템 탭: 미보유면 코인으로 구매 후 착용, 보유면 착용/해제 토글.
  /// 코인 부족이면 착용하지 않고 사유 문자열을 돌려준다(화면이 안내).
  String? buyOrWear(StoreItem item) {
    if (!item.owned) {
      if (coins < item.price) return '코인이 ${item.price - coins} 더 필요해요';
      coins -= item.price; // 세션 로컬 차감(서버 구매 API 미제공)
      item.owned = true;
    }
    if (item.wearing) {
      item.wearing = false; // 착용 해제
    } else {
      for (final h in hats) {
        h.wearing = false;
      }
      item.wearing = true;
    }
    notifyListeners();
    return null;
  }

  void rename(String v) {
    if (v.isEmpty) return;
    final old = myName;
    myName = v;
    notifyListeners();
    if (real) {
      api!.updateMe(v).catchError((Object _) {
        myName = old; // 서버 반영 실패 시 되돌린다
        notifyListeners();
      });
    }
  }

  void setPartnerNick(String v) {
    if (v.isEmpty) return;
    final old = partnerNick;
    partnerNick = v;
    notifyListeners();
    if (real && groupId != null && partnerUserId != null) {
      api!.setNickname(groupId!, partnerUserId!, v).catchError((Object _) {
        partnerNick = old;
        notifyListeners();
      });
    }
  }

  void setGroupName(String v) {
    if (v.isEmpty) return;
    final old = groupName;
    groupName = v;
    notifyListeners();
    if (real && groupId != null) {
      api!.updateGroup(groupId!, name: v).catchError((Object _) {
        groupName = old;
        notifyListeners();
      });
    }
  }

  void resetToOnboarding() {
    onboarded = false;
    notifyListeners();
  }

  /// 로그아웃 · 커플 연결 끊기. 실서버면 그룹을 나가고(멤버 삭제) 로컬 세션을 온보딩으로 되돌린다.
  /// device_uid 는 유지 — 같은 계정으로 새 그룹을 만들거나 참여할 수 있다.
  Future<void> logout() async {
    if (real && groupId != null) {
      try {
        await api!.leaveGroup(groupId!);
      } catch (_) {}
    }
    try {
      rt?.dispose();
    } catch (_) {}
    rt = null;
    groupId = null;
    petId = null;
    partnerUserId = null;
    onboarded = false;
    notifyListeners();
  }

  /// 온보딩 완료. 실서버면 그룹 생성 또는 참여를 서버에 반영한다.
  Future<void> completeOnboarding({String? name, String? joinCode}) async {
    if (name != null && name.isNotEmpty) myName = name;
    if (real) {
      try {
        if (name != null && name.isNotEmpty) await api!.updateMe(name);
        // 온보딩엔 그룹/펫 이름 입력 UI가 없으므로 사용자 이름 기반 기본값으로 생성.
        // (목 기본값 '지우 ♥ 나무'/'모리' 를 실서버에 넣지 않는다. 이후 설정/펫하우스에서 변경)
        final newGroupName = '$myName의 그룹';
        final Map res = joinCode != null && joinCode.isNotEmpty
            ? await api!.joinGroup(joinCode)
            : await api!.createGroup(newGroupName, petName);
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
