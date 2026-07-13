// 데모 상태 — 디자인의 샘플 세계(지우·나무늘보·모리)를 그대로 담는다.
// 전역 싱글턴 [mock] 하나. 화면들은 이걸 읽고 쓴 뒤 notifyListeners 로 갱신된다.

import 'package:flutter/material.dart';

import 'theme.dart';

enum DoodleType { photo, text, drawing }

class Doodle {
  Doodle({
    required this.id,
    required this.fromMe,
    required this.type,
    this.asset,
    this.text,
    this.caption,
    required this.when,
    this.ephemeral = false,
    this.viewed = true,
    this.replies = 0,
  });

  final String id;
  final bool fromMe; // true = 지우(나), false = 나무늘보(상대)
  final DoodleType type;
  final String? asset; // assets/photos/...
  final String? text; // 텍스트 낙서 본문
  final String? caption; // 사진/그림 위 손글씨
  final String when; // '방금 전' '5분 전' '어제' ...
  final bool ephemeral;
  bool viewed;
  final int replies;
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

  // ---- 행동
  void poke() {
    pokesToday += 1;
    notifyListeners();
  }

  void pat() {
    petBubble = [
      '삐삐! 나 여기 있어',
      '쓰다듬 최고야…',
      '오늘도 낙서 기다리는 중… 삐삐!',
      '억새밭 얘기 또 해줘!',
    ][DateTime.now().second % 4];
    notifyListeners();
  }

  void answer(String v) {
    myAnswer = v;
    notifyListeners();
  }

  void setRoomColor(Color c) {
    roomColor = c;
    notifyListeners();
  }

  void markViewed(Doodle d) {
    d.viewed = true;
    notifyListeners();
  }

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
  }

  void setGroupName(String v) {
    if (v.isNotEmpty) groupName = v;
    notifyListeners();
  }

  void resetToOnboarding() {
    onboarded = false;
    notifyListeners();
  }

  void completeOnboarding({String? name}) {
    if (name != null && name.isNotEmpty) myName = name;
    onboarded = true;
    notifyListeners();
  }
}

final AppMock mock = AppMock();
