// Shared mock domain data for "Memory Pager" — a closed couple app.
//
// Every design variant renders the SAME data so that comparing 10 designs is
// apples-to-apples. Designs must NOT change these values; they only restyle.
//
// No network / real images are used (web-first, offline). Visual content is
// represented with gradients + emoji so any design can render without assets.

import 'package:flutter/material.dart';

/// The three hero screens every design must implement.
enum HeroScreen { drawSend, petHome, memoryAlbum }

extension HeroScreenMeta on HeroScreen {
  String get label => switch (this) {
        HeroScreen.drawSend => '소통 · 낙서 보내기',
        HeroScreen.petHome => '펫 키우기',
        HeroScreen.memoryAlbum => '낙서 사진첩',
      };
  String get shortLabel => switch (this) {
        HeroScreen.drawSend => 'Draw & Send',
        HeroScreen.petHome => 'Pet Home',
        HeroScreen.memoryAlbum => 'Memory Album',
      };
  IconData get icon => switch (this) {
        HeroScreen.drawSend => Icons.brush_rounded,
        HeroScreen.petHome => Icons.pets_rounded,
        HeroScreen.memoryAlbum => Icons.photo_library_rounded,
      };
}

/// How a doodle was sent (per 기능정의서: 일반 vs 사라지기 모드).
enum SendMode { normal, disappearing }

extension SendModeMeta on SendMode {
  String get label => switch (this) {
        SendMode.normal => '일반',
        SendMode.disappearing => '사라지기',
      };
  String get description => switch (this) {
        SendMode.normal => '다음 보내기 전까지 남음 · 레포트 반영',
        SendMode.disappearing => '확인 후 5초 뒤 삭제 · 레포트 미반영',
      };
}

/// Content emphasis of a doodle (per 기능정의서: 사진/텍스트/그림 위주).
enum DoodleType { photo, text, drawing }

extension DoodleTypeMeta on DoodleType {
  String get label => switch (this) {
        DoodleType.photo => '사진 위주',
        DoodleType.text => '텍스트 위주',
        DoodleType.drawing => '그림 위주',
      };
  IconData get icon => switch (this) {
        DoodleType.photo => Icons.photo_camera_rounded,
        DoodleType.text => Icons.text_fields_rounded,
        DoodleType.drawing => Icons.gesture_rounded,
      };
}

/// A single shared memory in the album / a received doodle.
class Doodle {
  final String id;
  final DoodleType type;
  final SendMode mode;
  final String author; // '나' or partner nickname
  final String caption;
  final String emoji; // stand-in for the drawn/photo content
  final List<Color> swatch; // gradient stand-in for the canvas
  final DateTime at;
  final bool liked;

  const Doodle({
    required this.id,
    required this.type,
    required this.mode,
    required this.author,
    required this.caption,
    required this.emoji,
    required this.swatch,
    required this.at,
    this.liked = false,
  });
}

/// The couple (closed group of 2) — pairing via invite code per 기능정의서.
class Couple {
  final String myName;
  final String partnerName;
  final String partnerNickname; // 별명 지어주기
  final String inviteCode;
  final int streakDays; // consecutive days of sharing
  const Couple({
    required this.myName,
    required this.partnerName,
    required this.partnerNickname,
    required this.inviteCode,
    required this.streakDays,
  });
}

/// A purchasable / equippable pet item (스토어: 옷/모자/집/기타).
class PetItem {
  final String name;
  final String emoji;
  final int price;
  final String category; // 모자 / 옷 / 집 / 소품
  final bool owned;
  final bool equipped;
  const PetItem({
    required this.name,
    required this.emoji,
    required this.price,
    required this.category,
    this.owned = false,
    this.equipped = false,
  });
}

/// The couple's shared pet (grows from interaction; AI learns drawing style).
class Pet {
  final String name;
  final int level;
  final double growth; // 0..1 toward next level
  final int coins;
  final String moodEmoji;
  final String speech; // 쓰다듬으면 말을 함
  final List<PetItem> store;
  const Pet({
    required this.name,
    required this.level,
    required this.growth,
    required this.coins,
    required this.moodEmoji,
    required this.speech,
    required this.store,
  });
}

/// Monthly report figures (월간 레포트).
class MonthlyReport {
  final int totalDoodles;
  final double growthDelta; // e.g. +0.32 this month
  final Doodle bestDoodle;
  final Map<DoodleType, int> typeCounts;
  const MonthlyReport({
    required this.totalDoodles,
    required this.growthDelta,
    required this.bestDoodle,
    required this.typeCounts,
  });
}

/// The full bundle handed to every design's build().
class AppData {
  final Couple couple;
  final Pet pet;
  final List<Doodle> album;
  final MonthlyReport report;
  const AppData({
    required this.couple,
    required this.pet,
    required this.album,
    required this.report,
  });
}

/// Fixed demo dataset. Dates are relative to a fixed anchor so builds are
/// deterministic (no DateTime.now()).
final DateTime _anchor = DateTime(2026, 7, 10, 9, 0);
DateTime _daysAgo(int d) => _anchor.subtract(Duration(days: d));

final List<Doodle> _album = [
  Doodle(
    id: 'd1',
    type: DoodleType.drawing,
    mode: SendMode.normal,
    author: '토리',
    caption: '오늘 아침 해장',
    emoji: '🍜',
    swatch: const [Color(0xFFFFB199), Color(0xFFFF0844)],
    at: _daysAgo(0),
    liked: true,
  ),
  Doodle(
    id: 'd2',
    type: DoodleType.photo,
    mode: SendMode.disappearing,
    author: '나',
    caption: '퇴근길 노을',
    emoji: '🌇',
    swatch: const [Color(0xFFFDCB6E), Color(0xFFE17055)],
    at: _daysAgo(0),
  ),
  Doodle(
    id: 'd3',
    type: DoodleType.text,
    mode: SendMode.normal,
    author: '토리',
    caption: '보고싶다는 낙서',
    emoji: '💌',
    swatch: const [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    at: _daysAgo(1),
    liked: true,
  ),
  Doodle(
    id: 'd4',
    type: DoodleType.drawing,
    mode: SendMode.normal,
    author: '나',
    caption: '우리 고양이',
    emoji: '🐱',
    swatch: const [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
    at: _daysAgo(2),
  ),
  Doodle(
    id: 'd5',
    type: DoodleType.photo,
    mode: SendMode.normal,
    author: '토리',
    caption: '카페 라떼',
    emoji: '☕',
    swatch: const [Color(0xFFD299C2), Color(0xFFFEF9D7)],
    at: _daysAgo(3),
  ),
  Doodle(
    id: 'd6',
    type: DoodleType.drawing,
    mode: SendMode.disappearing,
    author: '나',
    caption: '자기 전 인사',
    emoji: '🌙',
    swatch: const [Color(0xFF667EEA), Color(0xFF764BA2)],
    at: _daysAgo(4),
    liked: true,
  ),
];

final AppData demoData = AppData(
  couple: const Couple(
    myName: '종혁',
    partnerName: '지민',
    partnerNickname: '토리',
    inviteCode: 'LOVE-8213',
    streakDays: 47,
  ),
  pet: Pet(
    name: '몽이',
    level: 7,
    growth: 0.62,
    coins: 1000,
    moodEmoji: '🐣',
    speech: '오늘 낙서 고마워! 헤헤',
    store: const [
      PetItem(name: '베레모', emoji: '🎩', price: 300, category: '모자', owned: true, equipped: true),
      PetItem(name: '리본', emoji: '🎀', price: 200, category: '모자'),
      PetItem(name: '노란 우비', emoji: '🧥', price: 450, category: '옷'),
      PetItem(name: '별 목도리', emoji: '🧣', price: 380, category: '옷', owned: true),
      PetItem(name: '아늑한 집', emoji: '🏠', price: 1200, category: '집'),
      PetItem(name: '화분', emoji: '🪴', price: 150, category: '소품', owned: true, equipped: true),
    ],
  ),
  album: _album,
  report: MonthlyReport(
    totalDoodles: 128,
    growthDelta: 0.34,
    bestDoodle: _album[2],
    typeCounts: const {DoodleType.drawing: 71, DoodleType.photo: 42, DoodleType.text: 15},
  ),
);

/// A small palette of pens for the Draw & Send screen (펜/색깔 선택).
const List<Color> demoPenColors = [
  Color(0xFF2D2A32),
  Color(0xFFFF5A5F),
  Color(0xFFFFB400),
  Color(0xFF00C2A8),
  Color(0xFF3D7EFF),
  Color(0xFFB06AB3),
];
