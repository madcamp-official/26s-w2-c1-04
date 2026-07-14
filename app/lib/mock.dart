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
    this.at,
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
  final DateTime? at; // 실제 생성 시각(로컬). 날짜별 그룹핑용. 미상이면 null.
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
  StoreItem(this.name, this.price,
      {this.wearing = false, bool? owned, this.id, this.category, this.emoji})
      : owned = owned ?? (price == 0); // 무료(중절모)는 기본 보유

  final String name;
  final int price;
  final String? id; // 실서버 아이템 id(데모는 null)
  final String? category; // 실서버 카테고리(hat/clothes/accessory/furniture/background/prop)
  final String? emoji; // 이모지 글리프(asset_url "emoji:🎩" 파싱). null 이면 페인터로 그림
  bool wearing;
  bool owned; // 보유 여부(실서버는 pet_items, 데모는 세션 로컬)
}

class AppMock extends ChangeNotifier {
  // ---- 사람 · 그룹 (디자인 샘플)
  String myName = '지우';
  String partnerName = '나무';
  String partnerNick = '나무늘보';
  // 실서버에서 상대가 그룹에 실제로 있는지. 데모는 항상 커플이 완성된 상태로 본다.
  // #17(유령 파트너 방지)·#23(솔로 해금 방지)·#18(빈 상태 안내) 게이팅에 쓴다.
  bool get hasPartner => real ? partnerUserId != null : true;
  String groupName = '지우 ♥ 나무';
  String inviteCode = 'PAGER-0713';
  int dDay = 412;
  bool onboarded = true; // 데모는 온보딩 완료 상태로 부팅. 설정의 로그아웃으로 리셋.
  bool partnerLeft = false; // 상대가 커플을 나감(#24) — 온보딩에서 안내 문구 노출용.
  // 그룹은 만들었지만 아직 상대가 안 들어옴(#23). 이 동안엔 홈을 해금하지 않고
  // 초대 코드 대기 화면만 보여준다(솔로 해금으로 코드가 꼬이는 것을 막는다).
  bool awaitingPartner = false;

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

  // 데모 세계의 '오늘'. 골든 결정성을 위해 실서버가 아닐 땐 고정 날짜를 쓴다
  // (데모 낙서 날짜·주간 스트립이 실행 시각에 따라 달라지지 않게).
  static final DateTime _demoToday = DateTime(2026, 7, 13);
  DateTime get today => real ? DateTime.now() : _demoToday;

  // ---- 낙서들 (디자인 샘플 콘텐츠)
  final List<Doodle> doodles = [
    Doodle(
      id: 'd1',
      fromMe: false,
      type: DoodleType.photo,
      asset: 'assets/photos/photo_field.png',
      caption: '오늘 억새밭!!',
      when: '방금 전',
      at: DateTime(2026, 7, 13, 9),
      viewed: false,
      replies: 2,
    ),
    Doodle(
      id: 'd2',
      fromMe: true,
      type: DoodleType.text,
      text: '퇴근하고 떡볶이 ㄱ? ♥',
      when: '어제',
      at: DateTime(2026, 7, 12, 19),
    ),
    Doodle(
      id: 'd3',
      fromMe: false,
      type: DoodleType.photo,
      asset: 'assets/photos/photo_sky.png',
      caption: '오늘 하늘 예쁘다 ♥',
      when: '7월 11일',
      at: DateTime(2026, 7, 11, 15),
    ),
    Doodle(
      id: 'd4',
      fromMe: true,
      type: DoodleType.text,
      text: '배고파 ♥',
      when: '7월 10일',
      at: DateTime(2026, 7, 10, 12),
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

  // 실서버 스토어 카탈로그(#13). 데모는 위 hats 만 쓴다.
  final List<StoreItem> storeItems = [];

  // UI 탭(한글) → 서버 카테고리 집합. 소품 탭에 액세서리도 함께 노출한다.
  static const Map<String, List<String>> _catMap = {
    '모자': ['hat'],
    '옷': ['clothes'],
    '가구': ['furniture'],
    '배경': ['background'],
    '소품': ['prop', 'accessory'],
  };

  /// 탭 카테고리의 아이템 목록. 실서버는 카탈로그에서, 데모는 모자만.
  List<StoreItem> itemsForCategory(String korCat) {
    if (!real) return korCat == '모자' ? hats : const [];
    final wanted = _catMap[korCat] ?? const [];
    return storeItems.where((s) => wanted.contains(s.category)).toList();
  }

  /// 펫 얼굴에 모자를 씌울지. 실서버는 카탈로그의 hat 착용 여부.
  bool get wearingHat => real
      ? storeItems.any((s) => s.category == 'hat' && s.wearing)
      : hats.any((h) => h.wearing);

  // ---- 월간 레포트 (1f) — 실서버 모드에선 _loadAll 에서 최신 달 값으로 교체.
  int reportPhotos = 12, reportDrawings = 8, reportTexts = 5;
  int reportPokes = 47, reportDoodles = 25, reportAnswers = 30;
  // 이달의 최고 낙서(실서버 best_doodle). null 이면 카드를 숨긴다. 데모는 하드코딩 카드 사용.
  String? reportBestImage, reportBestText, reportBestDate;
  // 펫 레벨 변화(실서버 pet_level_start/end). 성장 카드에 'Lv.a → Lv.b' 로 표시.
  int reportLevelStart = 0, reportLevelEnd = 0;
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
    reportLevelStart = (rep['pet_level_start'] as num?)?.toInt() ?? 0;
    reportLevelEnd = (rep['pet_level_end'] as num?)?.toInt() ?? 0;
    // 이달의 최고 낙서 — 사진/그림은 이미지, 텍스트는 문구. 없으면 카드 숨김.
    final best = rep['best_doodle'];
    if (best is Map) {
      final img = best['photo_url'] ?? best['drawing_url'] ?? best['thumb_url'];
      reportBestImage = img == null ? null : _mediaUrl('$img');
      reportBestText = best['text_body'] as String?;
      reportBestDate = _diaryDateLabel('${best['created_at'] ?? ''}'.split('T').first);
    } else {
      reportBestImage = null;
      reportBestText = null;
      reportBestDate = null;
    }
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
        // /me 의 group 은 {id,name}뿐이라 상세(초대코드·상대·D-day)를 따로 복원한다.
        _applyGroup(await a.group(gid));
        await _enterGroupOrWait(); // 상대가 있으면 홈, 없으면 초대 대기(#23)
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
    partnerUserId = null;
    for (final mm in members) {
      final m = mm as Map;
      if ('${m['user_id']}' != api?.myUserId) {
        partnerUserId = '${m['user_id']}';
        partnerName = '${m['display_name']}';
        partnerNick = m['nickname'] != null ? '${m['nickname']}' : '${m['display_name']}';
      }
    }
    if (partnerUserId == null) {
      // 아직 혼자다 — 데모 기본값('나무'/'나무늘보')이 실서버로 새어 유령 파트너로
      // 보이던 문제(#17)를 막는다. 상대가 참여하면 위 루프가 실제 이름으로 채운다.
      partnerName = '상대';
      partnerNick = '상대';
    }
    final created = g['created_at'];
    if (created != null) {
      final c = DateTime.tryParse('$created');
      // 커플 관례: 만난 첫날이 D+1 이다(경과일 + 1).
      if (c != null) dDay = DateTime.now().toUtc().difference(c).inDays + 1;
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
    // 스토어 카탈로그(#13) — 보유·착용 상태 포함. 펫 얼굴 모자는 wearingHat 게터가 본다.
    await _loadStore();
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
      reportLevelStart = reportLevelEnd = 0;
      reportBestImage = reportBestText = reportBestDate = null;
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

  /// `_loadAll` 을 일시적 네트워크 실패에 견디게 재시도한다. 그룹 생성/부팅 직후
  /// 단 한 번의 실패로 사용자가 빈(부분 상태) 홈에 갇히지 않게 한다. 3회 모두
  /// 실패하면 마지막 예외를 던져 호출측이 처리한다.
  Future<void> _loadAllSafe() async {
    Object? lastErr;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _loadAll();
        return;
      } catch (e) {
        lastErr = e;
        try {
          rt?.dispose(); // 중도 실패로 열린 소켓을 정리하고 다음 시도에서 새로 연결
        } catch (_) {}
        rt = null;
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw lastErr!;
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
      case 'doodle:updated': // 캡션 생성 완료 등 서버측 갱신 — 목록을 다시 받는다.
        if (real && groupId != null) {
          // 먼저 받아온 뒤 통째로 교체한다. clear() 를 await 앞에 두면 그 사이
          // 전송 응답의 낙관적 삽입이 빈 목록에 들어가고 addAll 이 같은 항목을 다시
          // 붙여 발신자 앨범에 낙서가 2건으로 중복된다(경합).
          final fresh = await api!.doodles(groupId!);
          doodles
            ..clear()
            ..addAll(fresh);
          notifyListeners();
          await _refreshPetStats(); // 상대 전송으로 오른 공유 코인 반영(#12)
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
        await _refreshPetStats(); // 레벨업 보너스 코인 반영(#12)
      case 'diary:new':
        // 펫이 새 그림 일기를 그렸다 — 일기 목록을 다시 불러온다.
        if (real && petId != null) {
          try {
            await _reloadDiaries();
            notifyListeners();
          } catch (_) {}
        }
      case 'member:left':
        // 상대가 커플 연결을 끊었다(#24). 내 이탈 에코는 무시하고,
        // 상대가 나간 경우 즉시 세션을 정리하고 온보딩으로 되돌린다(방치 금지).
        if ('${data['user_id']}' != api?.myUserId) {
          _handlePartnerLeft();
        }
    }
  }

  /// 상대가 커플을 나갔을 때 로컬 세션을 정리하고 온보딩으로 되돌린다(#24).
  void _handlePartnerLeft() {
    partnerLeft = true;
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
      await _refreshPetStats(); // 활동별 코인 증가를 화면에 반영(#12)
      return;
    }
    doodles.insert(0,
        Doodle(id: 'local-${doodles.length}', fromMe: true, type: DoodleType.text, text: text, when: '방금 전', at: today, ephemeral: ephemeral));
    notifyListeners();
  }

  Future<void> sendDrawing(List<int> png, String strokeJson,
      {bool ephemeral = false, String? parentId}) async {
    if (real && groupId != null) {
      final d = await api!.sendDrawing(png, strokeJson,
          ephemeral: ephemeral, parentId: parentId);
      if (!doodles.any((x) => x.id == d.id)) doodles.insert(0, d);
      notifyListeners();
      await _refreshPetStats(); // 활동별 코인 증가를 화면에 반영(#12)
      return;
    }
    doodles.insert(0,
        Doodle(id: 'local-${doodles.length}', fromMe: true, type: DoodleType.drawing, when: '방금 전', at: today, ephemeral: ephemeral));
    notifyListeners();
  }

  /// 활동 후 펫의 코인·레벨을 다시 받아 화면에 반영한다(#12).
  /// 낙서 전송 응답엔 코인이 없어(펫에 적립됨) 따로 펫을 조회해야
  /// "코인 안 줬다"처럼 보이지 않는다.
  Future<void> _refreshPetStats() async {
    if (!real || groupId == null) return;
    try {
      final p = await api!.pet(groupId!);
      coins = (p['coins'] as num).toInt();
      petLevel = (p['level'] as num).toInt();
      notifyListeners();
    } catch (_) {}
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

  /// 실서버 스토어 카탈로그를 받아 storeItems 를 채운다(#13).
  Future<void> _loadStore() async {
    try {
      final s = await api!.store(groupId!);
      final list = (s['items'] as List? ?? const []);
      storeItems
        ..clear()
        ..addAll([for (final it in list) _storeItemFrom(it as Map)]);
      coins = (s['coins'] as num?)?.toInt() ?? coins;
    } catch (_) {
      // 스토어 로드 실패는 앱 사용을 막지 않는다(홈/펫은 그려진다).
    }
  }

  StoreItem _storeItemFrom(Map j) {
    final asset = '${j['asset_url']}';
    final emoji = asset.startsWith('emoji:') ? asset.substring(6) : null;
    return StoreItem(
      '${j['name']}',
      (j['price_coins'] as num).toInt(),
      id: '${j['id']}',
      category: '${j['category']}',
      emoji: emoji,
      owned: j['owned'] == true,
      wearing: j['equipped'] == true,
    );
  }

  /// 아이템 탭: 미보유면 코인으로 구매 후 착용, 보유면 착용/해제 토글.
  /// 코인 부족·실패면 사유 문자열을 돌려준다(화면이 안내). 실서버는 서버에 지속화한다.
  Future<String?> buyOrWear(StoreItem item) async {
    if (real && item.id != null) {
      try {
        if (!item.owned) {
          if (coins < item.price) return '코인이 ${item.price - coins} 더 필요해요';
          coins = await api!.buyItem(groupId!, item.id!);
          item.owned = true;
        }
        final wantEquip = !item.wearing;
        await api!.equipItem(groupId!, item.id!, wantEquip);
        if (wantEquip) {
          // 같은 서버 카테고리 배타 착용(서버와 동일 규칙을 로컬에도 반영).
          for (final s in storeItems) {
            if (s.category == item.category) s.wearing = false;
          }
        }
        item.wearing = wantEquip;
        notifyListeners();
        return null;
      } on ApiException catch (e) {
        if (e.code == 'insufficient_coins') return '코인이 부족해요';
        return '잠시 후 다시 시도해 주세요';
      } catch (_) {
        return '잠시 후 다시 시도해 주세요';
      }
    }
    // 데모 — 세션 로컬 차감/착용.
    if (!item.owned) {
      if (coins < item.price) return '코인이 ${item.price - coins} 더 필요해요';
      coins -= item.price;
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
    awaitingPartner = false;
    notifyListeners();
  }

  /// 온보딩 완료. 실서버면 그룹 생성 또는 참여를 서버에 반영한다.
  Future<void> completeOnboarding({String? name, String? joinCode}) async {
    partnerLeft = false; // 새 그룹을 만들거나 참여하면 이탈 안내를 지운다.
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
        // 그룹이 서버에 생성/참여됐다. 참여(상대 있음)면 홈, 생성(솔로)이면 초대 대기(#23).
        // 이후 로드가 실패해도 상태를 되돌리지 않는다 — 재시도 시 서버가 409를 던지고,
        // 사용자는 이미 그룹이 있으므로 여기가 맞다. 끝내 실패하면 bootstrapError 만 남는다.
        await _enterGroupOrWait();
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

  /// 그룹 적용 후: 상대가 있으면 홈을 해금하고, 없으면 초대 코드 대기로 둔다(#23).
  Future<void> _enterGroupOrWait() async {
    if (hasPartner) {
      awaitingPartner = false;
      onboarded = true;
      await _loadAllSafe();
    } else {
      awaitingPartner = true;
      onboarded = false;
      notifyListeners();
      _pollForPartner(); // 상대 참여를 폴링(백그라운드) — await 하지 않는다.
    }
  }

  /// 초대 대기 중 상대 참여를 폴링한다(#23). 들어오면 홈으로 전환한다.
  Future<void> _pollForPartner() async {
    while (awaitingPartner && real && groupId != null) {
      await Future.delayed(const Duration(seconds: 3));
      if (!awaitingPartner || !real || groupId == null) return;
      try {
        final g = await api!.group(groupId!);
        _applyGroup(g);
        if (hasPartner) {
          awaitingPartner = false;
          onboarded = true;
          notifyListeners();
          await _loadAllSafe();
          return;
        }
      } catch (_) {
        // 일시적 네트워크 오류는 무시하고 다음 폴링에서 재시도.
      }
    }
  }

  /// 초대 대기 취소(#23) — 만든 그룹을 나가고 온보딩으로 되돌린다.
  Future<void> cancelWaiting() async {
    awaitingPartner = false;
    await logout();
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
