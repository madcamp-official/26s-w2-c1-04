// Memory Pager — 디자인 토큰.
// 유일한 원본: "썸원 스타일 앱 디자인/Memory Pager 디자인.dc.html" (실측값 그대로).
// 본문 Pretendard(400/600/700/800) · 손글씨 Gaegu(400/700).

import 'package:flutter/material.dart';

// ---------------------------------------------------------------- palette
const Color ink = Color(0xFF3A2E2E); // 코코아 잉크 — 기본 텍스트
const Color coral = Color(0xFFE8566B); // 주 액센트 — CTA·하트·활성
const Color coralHot = Color(0xFFFF5A70); // 캔버스 위 낙서 잉크
const Color salmon = Color(0xFFFF8E7E); // 펫 몸통
const Color blush = Color(0xFFFFE3DD); // 활성 필·펫 배경·roomColor 기본
const Color blushSoft = Color(0xFFFFF0EC); // 옅은 하이라이트 bg
const Color paper = Color(0xFFFFF7F4); // 온보딩·설정 바탕
const Color paperCard = Color(0xFFFFFDFC); // 홈·사진첩 바탕
const Color paperDiary = Color(0xFFFFF9F0); // 일기장 바탕
const Color paperReply = Color(0xFFFFFAF7); // 답장 캔버스 바탕
const Color chipBg = Color(0xFFF5EDEA); // 세그먼트·비활성 칩
const Color line = Color(0xFFF0E4DF); // 카드 보더·구분선
const Color lineSoft = Color(0xFFEBDDD8);
const Color muted = Color(0xFFB8A8A3); // 보조 텍스트
const Color brown = Color(0xFF8A6E67); // 본문 보조
const Color brownWarm = Color(0xFFB06A5E); // 서브 강조
const Color inkSoft = Color(0xFF6B5A55);
const Color hintWarm = Color(0xFF9B8A85);
const Color goldText = Color(0xFFB08A2E); // 일기 날짜·골드 텍스트
const Color goldCoin = Color(0xFFFFB800); // 코인
const Color goldBg = Color(0xFFFFF3D6);
const Color goldDash = Color(0xFFEBD9A8); // 일기 점선 프레임
const Color partnerBlue = Color(0xFF4E8DF5); // 상대(나무) 아바타
const Color partnerBlueBg = Color(0xFFDCEEFF);
const Color myPinkBg = Color(0xFFFFD4CC); // 나(지우) 아바타 bg
const Color dashPeach = Color(0xFFFFB4A6); // 초대코드 점선
const Color lilac = Color(0xFF9A6CE0); // 이웃집
const Color lilacBg = Color(0xFFEFE3FF);
const Color lilacInk = Color(0xFF6B5A8A);

/// 뷰어/캔버스의 어두운 오버레이 톤 (design: rgba(40,25,22,x)).
Color overlay(double a) => const Color(0xFF281916).withValues(alpha: a);

/// roomColor 프리셋 — 설정 4g의 스와치 4색.
const List<Color> roomColors = [
  Color(0xFFFFE3DD), // 블러시 (기본)
  Color(0xFFFFF2CC), // 크림
  Color(0xFFDCEEFF), // 베이비 블루
  Color(0xFFEFE3FF), // 라일락
];

// ---------------------------------------------------------------- type
/// 본문 — Pretendard.
TextStyle sans(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = ink,
  double? h,
  double ls = 0,
}) =>
    TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

/// 손글씨 — Gaegu. 낙서 텍스트·펫 대사·일기.
TextStyle hand(
  double size, {
  Color c = ink,
  FontWeight w = FontWeight.w400,
  double? h,
  double ls = 0,
}) =>
    TextStyle(
      fontFamily: 'Gaegu',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

// ---------------------------------------------------------------- theme
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: paper,
  fontFamily: 'Pretendard',
  colorScheme: ColorScheme.fromSeed(seedColor: coral).copyWith(
    surface: paper,
    onSurface: ink,
    primary: coral,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: coral),
);
