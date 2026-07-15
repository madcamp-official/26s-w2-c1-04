// 데모 상태 — 디자인의 샘플 세계(지우·나무늘보·모리)를 그대로 담는다.
// 전역 싱글턴 [mock] 하나. 화면들은 이걸 읽고 쓴 뒤 notifyListeners 로 갱신된다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // 상대가 막 들어와서 별명을 지어줘야 하는 단계(#2). 생성자·참여자 모두 이 단계를 거친다.
  // 게이트가 이 플래그를 보고 별명 화면을 띄운다(참여자만 보던 문제를 고침).
  bool pendingNickname = false;

  // ---- 펫
  String petName = '모리';
  int petLevel = 3;
  int coins = 1240;
  double get growthPct => (petLevel * 20).clamp(0, 100) / 100;
  String get levelLabel => 'Lv.$petLevel';
  // 레벨이 오를수록 커지되 상한(≈180)에 수렴한다. 원래 96+level*12 는 고레벨(Lv50=696)
  // 에서 펫이 화면을 꽉 채워버렸다(실기기 확인). 포화 곡선으로 성장은 보이되 헤더를 넘지 않게.
  double get petSize => 100 + 80 * petLevel / (petLevel + 12);

  // ---- roomColor (설정 4g 스와치)
  Color roomColor = roomColors[0];

  // ---- 상호작용
  int pokesToday = 0; // 오늘 콕 찌른 횟수. 실서버는 부팅 시 기기에 저장된 오늘치를 복원(#2).
  String? _pokeDay; // pokesToday 가 어느 날짜의 값인지(자정 넘어가면 리셋)
  String petBubble = '오늘도 낙서 기다리는 중이야';

  // ---- 오늘의 질문 (1c)
  String question = '서로 처음 만난 날, 가장 기억에 남는 순간은?';
  bool partnerAnswered = true;
  String? myAnswer;
  String? partnerAnswer; // 상대 답변 원문 — 내가 답한 뒤 공개(#6). null 이면 아직 못 봄.

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

  // ---- 그림 일기장 (4f) — 실서버 모드에선 _reloadDiaries 에서 _diaryFeed 를 교체한다.
  // 화면에 보여줄 목록은 아래 getter `diary`(쓰다듬기로 받은 일기 + 서버/데모 일기)다.
  final List<DiaryEntry> _diaryFeed = [
    const DiaryEntry(
      dateLabel: '7월 13일 맑음',
      caption: '오늘은 둘이 억새밭 얘기를 했다. 나도 데려가 줬으면…',
      isNew: true,
      scene: 0,
    ),
    const DiaryEntry(
      dateLabel: '7월 11일 흐림',
      caption: '떡볶이가 뭐길래 이렇게 자주 나올까. 나도 먹어보고 싶다.',
      scene: 1,
    ),
  ];

  // 쓰다듬을 때 하나씩 선물하는 '우리 그림체' 그림 일기 큐(시연용). 원래는 손그림
  // 20장이 쌓여 자정(KST) 배치로 그리던 일기를, 시연에선 쓰다듬기로 꺼내 보여준다.
  // 다 떨어지면 더 나오지 않는다. 꺼낸 일기는 _patDiaries 로 옮겨 일기장에 남기며,
  // 실서버 리싱크(_reloadDiaries)는 _diaryFeed 만 교체하므로 여기서 받은 일기는 유지된다.
  final List<DiaryEntry> _patQueue = [
    const DiaryEntry(
      dateLabel: '7월 15일 맑음',
      caption: '오늘은 둘이 한강을 걸었대. 나도 그 바람 같이 맞고 싶다.',
      isNew: true,
      scene: 0,
    ),
    const DiaryEntry(
      dateLabel: '7월 14일 흐림',
      caption: '또 떡볶이 얘기! 매콤한 게 그렇게 좋을까. 나도 한 입만…',
      isNew: true,
      scene: 1,
    ),
    const DiaryEntry(
      dateLabel: '7월 13일 별밤',
      caption: '밤에 나란히 앉아 별을 셌대. 다음엔 나도 꼭 끼워줘.',
      isNew: true,
      scene: 2,
    ),
  ];
  final List<DiaryEntry> _patDiaries = [];

  /// 일기장에 보여줄 목록 = 쓰다듬기로 받은 일기(최신) + 서버/데모 일기.
  List<DiaryEntry> get diary =>
      _patDiaries.isEmpty ? _diaryFeed : [..._patDiaries, ..._diaryFeed];

  int _patRevealed = 0; // 실서버: 쓰다듬기로 이미 꺼내 보여준 실제 일기 수

  /// 아직 쓰다듬기로 꺼낼 그림 일기가 남아 있는지(시연용).
  /// 실서버: 모리가 실제로 그린 일기(이미지) 중 아직 안 꺼낸 게 있으면 true.
  /// 데모(목): 하드코딩 벡터 큐가 남아 있으면 true.
  bool get hasPatSurprise => real
      ? _patRevealed < _diaryFeed.where((d) => d.isRemote).length
      : _patQueue.isNotEmpty;

  /// 쓰다듬을 때 그림 일기를 하나 꺼낸다. 비어 있으면 null 을 돌려주고
  /// 홈은 예전처럼 학습 상태에 맞는 반응만 한다.
  /// 실서버: 모리가 그린 '실제' 일기 이미지를 최신순으로 하나씩(중복 없이) 꺼낸다 —
  ///   벡터 더미 장면 대신 진짜 우리 그림체 일기가 뜬다. 이미 일기장에 있으므로
  ///   _patDiaries 에 또 넣지 않는다(일기장 중복 방지).
  /// 데모(목): 하드코딩 벡터 큐에서 꺼내 _patDiaries 로 옮긴다(골든/오프라인용).
  DiaryEntry? popPatSurprise() {
    if (real) {
      final remote = _diaryFeed.where((d) => d.isRemote).toList();
      if (_patRevealed >= remote.length) return null;
      return remote[_patRevealed++]; // 최신순, 이미 일기장에 존재
    }
    if (_patQueue.isEmpty) return null;
    final e = _patQueue.removeAt(0);
    _patDiaries.insert(0, e);
    notifyListeners();
    return e;
  }

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

  // 사진첩 AI 큐레이션 앨범(#6). [{title, doodle_ids:[..], cover_url}]. 실서버만 채운다.
  final List<Map<String, dynamic>> albums = [];

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

  /// 해당 카테고리에서 착용 중인 아이템의 이모지(#12). 없으면 null.
  /// 캐릭터 위에 오버레이해 옷/가구/배경/소품 착용을 눈에 보이게 한다.
  String? equippedEmoji(String category) {
    if (!real) {
      if (category == 'hat') {
        for (final h in hats) {
          if (h.wearing) return h.emoji;
        }
      }
      return null;
    }
    for (final s in storeItems) {
      if (s.category == category && s.wearing) return s.emoji;
    }
    return null;
  }

  /// 해당 카테고리에서 착용 중인 아이템(#5). 없으면 null. 페인터가 이모지/이름으로
  /// 어떤 모양을 그릴지 고른다(이모지 우선, 데모는 이름으로 폴백).
  /// 미리보기 중이면(#4) 같은 슬롯을 미리보기 아이템으로 임시 대체한다.
  StoreItem? equippedItem(String category) {
    final pv = previewItem;
    if (pv != null && pv.category == category) return pv;
    if (!real) {
      if (category == 'hat') {
        for (final h in hats) {
          if (h.wearing) return h;
        }
      }
      return null;
    }
    for (final s in storeItems) {
      if (s.category == category && s.wearing) return s;
    }
    return null;
  }

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
  String? _deviceUid; // 401 복구 재등록용(#15)
  bool _reauthing = false;
  bool get real => api != null;

  // ---- 포그라운드 폴백 동기화(#2/#6) ----
  // 소켓이 백그라운드에서 끊기면 doodle:new·question:answered 를 놓친다. 앱이
  // 앞에 있을 때 주기적으로 REST 로 다시 맞춰, 상대 낙서/답변이 "안 나오는" 것을 막는다.
  Timer? _pollTimer;
  bool _foreground = true;

  /// 앱이 포그라운드로 복귀했다(main.dart 의 lifecycle observer). 끊겼던 소켓을
  /// 다시 붙이고 즉시 한 번 동기화한 뒤 폴백 폴링을 켠다(#2/#6).
  void onAppResumed() {
    _foreground = true;
    if (!real || groupId == null) return;
    try {
      rt?.ensureConnected();
    } catch (_) {}
    _resync();
    _startPolling();
  }

  /// 앱이 백그라운드로 갔다 — 폴링을 멈춰 배터리·트래픽을 아낀다.
  void onAppPaused() {
    _foreground = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _startPolling() {
    if (!real || groupId == null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!_foreground || !real || groupId == null) return;
      _resync();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 소켓이 놓쳤을 수 있는 것들을 REST 로 다시 맞춘다(#2 낙서, #6 오늘의 질문).
  /// 그룹 상세(roomColor 등)는 일부러 건드리지 않는다 — 방금 바꾼 배경색이 폴링에
  /// 되돌려지지 않도록(#1). 실패는 조용히 무시하고 다음 주기에 재시도한다.
  Future<void> _resync() async {
    if (!real || groupId == null) return;
    var changed = false;
    try {
      final fresh = await api!.doodles(groupId!);
      doodles
        ..clear()
        ..addAll(fresh);
      changed = true;
    } catch (_) {}
    try {
      await _reloadQuestion();
      changed = true;
    } catch (_) {}
    // 스토어(소유·착용) 상태도 갱신한다 — 상대가 산/입힌 꾸미기가 공유 펫에 반영되게(BUG-2).
    // 스토어만 startup 1회 로드하던 탓에 파트너 기기가 재시작 전엔 못 보던 문제.
    try {
      await _loadStore();
      changed = true;
    } catch (_) {}
    if (changed) notifyListeners();
  }

  Future<void> _reloadQuestion() async {
    if (!real || groupId == null) return;
    final q = await api!.question(groupId!);
    question = '${q['text']}';
    myAnswer = q['my_answer'] as String?;
    partnerAnswered = q['partner_answered'] == true;
    partnerAnswer = q['partner_answer'] as String?;
  }

  /// 세션이 꼬였을 때(토큰 무효·이미 그룹 소속) 서버의 진실로 다시 맞춘다.
  /// /me 에 그룹이 있으면 그 그룹을 로드해 홈으로 보내고 true, 없으면 false.
  /// device_uid 재등록은 같은 유저를 돌려주므로, 이미 그룹이 있는 사용자를
  /// 온보딩에 가두는 문제(#7: 그룹 만들기·초대코드가 409 로 막히던 것)를 막는다.
  Future<bool> _recoverFromMe() async {
    final a = api;
    if (a == null) return false;
    final m = await a.me();
    final u = m['user'] as Map?;
    if (u != null) myName = '${u['display_name']}';
    final g = m['group'];
    if (g == null) return false;
    groupId = '${(g as Map)['id']}';
    _applyGroup(await a.group(groupId!));
    await _enterGroupOrWait();
    return true;
  }

  /// 토큰 무효(401) 복구(#15) — 서버에서 세션이 사라졌거나 토큰이 갈렸을 때
  /// 기기 uid 로 재등록한다. 재등록으로 받은 유저가 이미 그룹에 있으면 그 그룹으로
  /// 복귀하고(#7), 없을 때만 온보딩으로 되돌린다. '전송 실패' 팝업 반복을 막는다.
  void _handleAuthLost() {
    if (_reauthing || !real || _deviceUid == null) return;
    _reauthing = true;
    () async {
      try {
        _stopPolling();
        try {
          rt?.dispose();
        } catch (_) {}
        rt = null;
        await api!.register(myName, _deviceUid!); // device_uid → 같은 유저·새 토큰
        if (!await _recoverFromMe()) {
          // 정말 그룹이 없을 때만 온보딩으로.
          groupId = null;
          petId = null;
          partnerUserId = null;
          onboarded = false;
          awaitingPartner = false;
          pendingNickname = false;
        }
        notifyListeners();
      } catch (_) {
      } finally {
        _reauthing = false;
      }
    }();
  }

  /// API_BASE 가 주어지면 실서버로 부팅한다. register → /me → (그룹 있으면 로드).
  Future<void> bootstrapReal(String base, String deviceUid, String name) async {
    final a = Api(base);
    api = a;
    myName = name;
    _deviceUid = deviceUid;
    a.onAuthLost = _handleAuthLost; // 401 → 재등록+온보딩 복구(#15)
    try {
      await _loadPokesToday(); // 오늘 콕 찌른 횟수 복원(#2) — 껐다 켜도 유지
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
      // 그룹을 이미 로드했다면 온보딩으로 되돌리지 않는다 — 부팅 중 일시적 실패로
      // 이미 커플인 사용자를 온보딩(→409)에 가두지 않게(#7).
      if (groupId == null) onboarded = false;
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
    _serverDrawings = (p['drawing_count'] as num?)?.toInt() ?? _serverDrawings;
    _learnGoal = (p['learn_goal'] as num?)?.toInt() ?? _learnGoal;
    // 활동 표정: 서버의 current_activity 를 말풍선에 반영(없으면 기본 유지)
    final act = p['current_activity'];
    if (act is Map && act['activity'] != null) {
      petBubble = _activityUtterance('${act['activity']}');
    }
    // 스토어 카탈로그(#13) — 보유·착용 상태 포함. 펫 얼굴 모자는 wearingHat 게터가 본다.
    await _loadStore();
    await _loadAlbums();
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
    await _reloadQuestion();
    // 실시간 연결
    rt = Rt(a.host, a.token!)..onEvent = _onRtEvent;
    await rt!.connect();
    _startPolling(); // 소켓이 놓친 낙서/답변을 메우는 포그라운드 폴백(#2/#6)
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
      case 'question:answered':
        // 상대가 오늘의 질문에 답했다(#6). 질문을 다시 받아, 둘 다 답했으면 콜드스타트
        // 없이 바로 상대 답변을 공개한다(내 답변이 있어야 서버가 상대 답을 내려준다).
        if (real && groupId != null) {
          try {
            await _reloadQuestion();
            notifyListeners();
          } catch (_) {}
        }
      case 'group:updated':
        // 상대(또는 나)가 그룹 설정을 바꿨다 — 공유 배경색을 즉시 반영한다(BUG-3).
        // 폴링에서 그룹을 재조회하지 않으므로(방금 바꾼 색 보호) 이 이벤트로 메운다.
        // 페이로드가 곧 서버의 최신값이라 클로버링 걱정이 없다.
        final bg = data['background_color'];
        if (bg is String && bg.isNotEmpty) roomColor = _hexRoom(bg);
        final gname = data['name'];
        if (gname is String && gname.isNotEmpty) groupName = gname;
        notifyListeners();
      case '__reconnect':
        // 백그라운드 등으로 끊겼다가 소켓이 다시 붙었다 — 놓친 이벤트를 메운다(#2).
        await _resync();
    }
  }

  /// 상대가 커플을 나갔을 때 로컬 세션을 정리하고 온보딩으로 되돌린다(#24).
  void _handlePartnerLeft() {
    partnerLeft = true;
    _stopPolling();
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
    if (!_seenLoaded) {
      try {
        final p = await SharedPreferences.getInstance();
        _seenDiaryCount = p.getInt('seen_diary_count') ?? 0;
      } catch (_) {}
      _seenLoaded = true;
    }
    final ds = await api!.diaries(petId!);
    _diaryFeed
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
    // 새 그림 일기가 생겼으면 팝업 노출 대상으로 표시(#10). 사진첩이 감지해 띄운다.
    // 쓰다듬기로 받은 일기(_patDiaries)와 무관하게 서버 피드 기준으로만 판단한다.
    if (_diaryFeed.isNotEmpty && _diaryFeed.length > _seenDiaryCount) {
      pendingDiaryPopup = _diaryFeed.first;
    }
  }

  // ---- 그림 일기 새 알림(#10) ----
  int _seenDiaryCount = 0;
  bool _seenLoaded = false;
  DiaryEntry? pendingDiaryPopup; // null 이 아니면 사진첩이 팝업을 띄운다.

  /// 그림 일기 팝업을 확인 처리 — 다시 뜨지 않게 개수를 기록한다.
  void ackDiaryPopup() {
    _seenDiaryCount = _diaryFeed.length;
    pendingDiaryPopup = null;
    SharedPreferences.getInstance()
        .then((p) => p.setInt('seen_diary_count', _seenDiaryCount))
        .catchError((Object _) => false);
    notifyListeners();
  }

  static Color _hexRoom(String hex6) {
    final v = int.tryParse(hex6, radix: 16);
    return v == null ? roomColors[0] : Color(0xFF000000 | v);
  }

  // ---- 행동 (dual-mode) ----
  Future<void> poke() async {
    final day = _todayKey();
    if (_pokeDay != day) {
      pokesToday = 0; // 자정을 넘겼으면 새 날 카운트로 리셋
      _pokeDay = day;
    }
    pokesToday += 1;
    notifyListeners();
    _persistPokes(); // 껐다 켜도 오늘치가 유지되도록 저장(#2)
    if (real && groupId != null && partnerUserId != null) {
      try {
        await api!.poke(groupId!, partnerUserId!);
      } catch (_) {}
    }
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPokesToday() async {
    try {
      final p = await SharedPreferences.getInstance();
      final day = _todayKey();
      pokesToday = p.getInt('pokes_$day') ?? 0;
      _pokeDay = day;
    } catch (_) {}
  }

  void _persistPokes() {
    final day = _pokeDay;
    if (day == null) return;
    SharedPreferences.getInstance()
        .then((p) => p.setInt('pokes_$day', pokesToday))
        .catchError((Object _) => false);
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
      '헤헤, 나 여기 있어',
      '쓰다듬 최고야…',
      '오늘도 낙서 기다리는 중이야',
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
        partnerAnswer = r['partner_answer'] as String?;
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
      _serverDrawings = (p['drawing_count'] as num?)?.toInt() ?? _serverDrawings;
      _learnGoal = (p['learn_goal'] as num?)?.toInt() ?? _learnGoal;
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

  /// 실서버 AI 큐레이션 앨범을 받는다(#6). 실패·빈 목록이면 '모두'만 보인다.
  Future<void> _loadAlbums() async {
    await _loadSeenAlbums();
    try {
      final list = await api!.albums(groupId!);
      albums
        ..clear()
        ..addAll(list);
    } catch (_) {}
  }

  // ---- AI 앨범 새 알림(#8) ----
  int _seenAlbumCount = 0;
  bool _seenAlbumLoaded = false;

  /// 아직 확인 안 한 새 앨범이 있는지 — 사진첩에서 'NEW' 배지로 알린다(#8).
  bool get hasNewAlbums => albums.length > _seenAlbumCount;

  Future<void> _loadSeenAlbums() async {
    if (_seenAlbumLoaded) return;
    try {
      final p = await SharedPreferences.getInstance();
      _seenAlbumCount = p.getInt('seen_album_count') ?? 0;
    } catch (_) {}
    _seenAlbumLoaded = true;
  }

  /// 새 앨범 배지 확인 처리 — 다시 뜨지 않게 개수를 기록한다.
  void ackAlbums() {
    _seenAlbumCount = albums.length;
    SharedPreferences.getInstance()
        .then((p) => p.setInt('seen_album_count', _seenAlbumCount))
        .catchError((Object _) => false);
    notifyListeners();
  }

  /// 앨범 제목의 낙서 id 집합. 없으면 빈 집합.
  Set<String> albumDoodleIds(String title) {
    for (final a in albums) {
      if ('${a['title']}' == title) {
        return {for (final i in (a['doodle_ids'] as List? ?? const [])) '$i'};
      }
    }
    return const {};
  }

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

  // ---- 구매 전 미리보기(#4) ----
  StoreItem? previewItem; // null 이 아니면 그 아이템을 펫에 임시 착용해 보여준다.

  /// 아이템 탭(#4): 보유했으면 착용/해제, 미보유면 코인 유무와 무관하게 펫에 미리
  /// 입혀 본다(구매는 미리보기 바의 '구매하기'로). 데모는 코인이 넉넉해 바로 착용한다.
  Future<String?> previewOrWear(StoreItem item) async {
    if (!real) return buyOrWear(item);
    if (item.owned) {
      previewItem = null;
      return buyOrWear(item);
    }
    previewItem = item;
    notifyListeners();
    return null;
  }

  /// 미리보기 중인 아이템을 실제로 구매·착용한다(#4). 코인 부족·실패면 사유 문자열.
  Future<String?> buyPreviewItem() async {
    final item = previewItem;
    if (item == null) return null;
    final err = await buyOrWear(item); // 구매+착용(코인 부족이면 사유 반환)
    if (err == null) previewItem = null; // 성공 시 미리보기 종료(이제 진짜 착용)
    return err;
  }

  void clearPreview() {
    if (previewItem == null) return;
    previewItem = null;
    notifyListeners();
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
    _stopPolling();
    try {
      rt?.dispose();
    } catch (_) {}
    rt = null;
    groupId = null;
    petId = null;
    partnerUserId = null;
    onboarded = false;
    awaitingPartner = false;
    pendingNickname = false;
    notifyListeners();
  }

  /// 온보딩 완료. 실서버면 그룹 생성 또는 참여를 서버에 반영한다.
  Future<void> completeOnboarding({String? name, String? joinCode}) async {
    bootstrapError = null; // 이전 실패의 잔여 에러가 성공 판정을 오염시키지 않게 초기화
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
        await _enterGroupOrWait(fresh: true);
        return;
      } catch (e) {
        // 이미 그룹에 속해 있으면(#7: device_uid 재등록으로 같은 유저가 되어 그룹이
        // 남아 있는 경우) 에러 팝업 대신 그 그룹으로 복귀시킨다. 그룹 만들기/초대코드가
        // 409 로 막히며 '의문의 플로팅 에러'만 뜨던 것을 고친다.
        if (e is ApiException &&
            (e.code == 'already_in_group' || e.code == 'already_member')) {
          try {
            if (await _recoverFromMe()) return;
          } catch (_) {}
        }
        bootstrapError = '$e';
        notifyListeners();
        return;
      }
    }
    onboarded = true;
    notifyListeners();
  }

  /// 그룹 적용 후: 상대가 있으면 홈을 해금하고, 없으면 초대 코드 대기로 둔다(#23).
  /// [fresh] 는 '방금 그룹을 만들거나 참여한' 흐름일 때만 true — 이때만 별명 짓기를
  /// 띄운다. 앱 재시작으로 이미 커플인 상태를 복원할 땐(fresh=false) 다시 안 띄운다(#1).
  Future<void> _enterGroupOrWait({bool fresh = false}) async {
    if (hasPartner) {
      awaitingPartner = false;
      onboarded = true;
      pendingNickname = fresh && !(await _nicknameDone(groupId));
      await _loadAllSafe();
      notifyListeners();
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
          pendingNickname = !(await _nicknameDone(groupId)); // 상대 참여 = fresh 전환(#2)
          onboarded = true;
          notifyListeners();
          await _loadAllSafe();
          notifyListeners();
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

  /// 별명 짓기 단계 종료(#2) — 게이트가 홈(AppShell)을 드러낸다.
  /// 이 그룹은 별명 단계를 지났다고 기기에 표시해, 껐다 켜도 다시 안 뜨게 한다(#1).
  void finishNickname() {
    pendingNickname = false;
    final gid = groupId;
    if (gid != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('nick_done_$gid', true))
          .catchError((Object _) => false);
    }
    notifyListeners();
  }

  /// 이 그룹에서 별명 짓기 단계를 이미 지났는지(#1). 기기에 영속화된 플래그.
  Future<bool> _nicknameDone(String? gid) async {
    if (gid == null) return false;
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool('nick_done_$gid') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 펫이 우리 그림체를 배웠는지(대략). 낙서가 어느 정도 쌓이고 그림 일기가 생기면 true.
  /// 아직이면(#9) 홈에서 쓰다듬을 때 '어린이 그림' 기본 낙서를 선물하고 안내 문구를 띄운다.
  bool get petLearned => doodles.length >= 6 && diary.isNotEmpty;

  // ---- 모리 학습 진행(#5) — 정확한 숫자는 숨기고 단계로만 안내 ----
  // 서버가 준 그룹 누적 손그림 수(펫 응답 drawing_count). -1이면 아직 모름 →
  // 앱 목록(최근 40건)으로 근사. 서버 값이 있으면 40건 한계 없이 정확하다.
  int _serverDrawings = -1;
  int _learnGoal = 20; // 서버 learn_goal(LEARN_MIN_DRAWINGS)
  int get _visibleDrawings =>
      doodles.where((d) => d.type == DoodleType.drawing).length;
  int get _drawingsForLearn =>
      _serverDrawings >= 0 ? _serverDrawings : _visibleDrawings;

  /// 학습 단계: 0 시작 전, 1 배우는 중, 2 거의 다, 3 완료(목표 도달).
  int get learnStage {
    final c = _drawingsForLearn;
    // 목표(손그림 20장) 도달 또는 이미 그림을 그렸으면 학습 완료.
    if (diary.isNotEmpty || c >= _learnGoal) return 3;
    if (c <= 0) return 0;
    if (c >= (_learnGoal * 0.7).round()) return 2; // 70%+
    return 1;
  }

  /// 학습 진척(0~1) — 진행바용. 정확한 개수는 노출하지 않는다(#5).
  double get learnProgress {
    if (learnStage >= 3) return 1;
    return (_drawingsForLearn / _learnGoal).clamp(0.05, 0.95);
  }

  /// 펫하우스 안내 문구(#5).
  String get learnMessage {
    switch (learnStage) {
      case 3:
        return diary.isNotEmpty
            ? '$petName가 그림체를 다 배웠어요 🎨 가끔 직접 그린 낙서를 선물해요'
            : '$petName가 그림체를 다 배웠어요! 곧 첫 그림을 선물할 거예요';
      case 2:
        return '$petName가 거의 다 배웠어요! 손그림을 조금만 더 주고받으면 그림을 그려요';
      case 1:
        return '$petName가 두 사람의 그림체를 배우는 중이에요';
      default:
        return '손그림 낙서를 주고받으면 $petName가 그림체를 배우기 시작해요';
    }
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

/// 낙서 이미지의 ImageProvider — precache(미리 디코드)용. 이미지가 없으면 null.
/// 사라지는 낙서에서 카운트다운 시작 전에 이 이미지를 미리 받아둔다(BUG-1).
ImageProvider? doodleImageProvider(Doodle d) {
  final url = d.imageUrl;
  if (url != null) return NetworkImage(url);
  if (d.asset != null) return AssetImage(d.asset!);
  return null;
}
