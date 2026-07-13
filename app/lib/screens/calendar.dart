// 2d 사진첩 · 추억 달력 — 날짜에 낙서가 쌓임.
// 디자인: Memory Pager 디자인.dc.html #2d (390px 카드) 실측값 그대로.

import 'package:flutter/material.dart';

import '../theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperCard,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 16),
              _monthRow(),
              const SizedBox(height: 16),
              _weekdayRow(),
              const SizedBox(height: 6),
              _dateGrid(),
              const SizedBox(height: 16),
              _selectedDayCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: ink),
          ),
        ),
        Text('낙서 사진첩', style: sans(20, w: FontWeight.w800)),
        const Spacer(),
        // 세그먼트 필: [목록 | 달력(활성)]
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  child:
                      Text('목록', style: sans(12, w: FontWeight.w600, c: muted)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text('달력', style: sans(12, w: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- month
  Widget _monthRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('◀', style: sans(13, c: muted)),
        const SizedBox(width: 16),
        Text('2026년 7월', style: sans(15, w: FontWeight.w800)),
        const SizedBox(width: 16),
        Text('▶', style: sans(13, c: muted)),
      ],
    );
  }

  Widget _weekdayRow() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Center(
              child: Text(d, style: sans(11, w: FontWeight.w700, c: muted)),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- grid
  Widget _dateGrid() {
    // 7월: 1일이 수요일 시작(빈칸 2) — 디자인 그대로 19일까지.
    final cells = <Widget>[
      const SizedBox(),
      const SizedBox(),
      _plainCell(1),
      _plainCell(2),
      _photoCell(3, 'assets/photos/photo_sky.png'),
      _plainCell(4),
      _heartCell(5),
      _plainCell(6),
      _diaryCell(7),
      _plainCell(8),
      _plainCell(9),
      _plainCell(10),
      _photoCell(11, 'assets/photos/photo_sky.png'),
      _heartCell(12),
      _photoCell(13, 'assets/photos/photo_field.png', selected: true),
      _plainCell(14, dim: true),
      _plainCell(15, dim: true),
      _plainCell(16, dim: true),
      _plainCell(17, dim: true),
      _plainCell(18, dim: true),
      _plainCell(19, dim: true),
    ];
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  /// 숫자만 있는 날. [dim]은 미래 날짜(lineSoft).
  Widget _plainCell(int day, {bool dim = false}) {
    return Center(
      child: Text('$day', style: sans(12, c: dim ? lineSoft : muted)),
    );
  }

  /// 사진이 쌓인 날 — 흰 숫자 배지. [selected]면 coral 2.5 아웃라인.
  Widget _photoCell(int day, String asset, {bool selected = false}) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              '$day',
              style: sans(10, w: FontWeight.w800, c: Colors.white).copyWith(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: .5),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!selected) return photo;
    // outline: 2.5px solid coral, offset 1px — 셀 밖으로 살짝 벗어난 테두리.
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        photo,
        Positioned(
          left: -3.5,
          top: -3.5,
          right: -3.5,
          bottom: -3.5,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: coral, width: 2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 하트 낙서가 있던 날.
  Widget _heartCell(int day) {
    return Container(
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Text('♥', style: hand(13, c: coral))),
          Positioned(
            top: 2,
            left: 4,
            child: Text('$day',
                style: sans(10, w: FontWeight.w700, c: brownWarm)),
          ),
        ],
      ),
    );
  }

  /// 텍스트 낙서('글')가 있던 날.
  Widget _diaryCell(int day) {
    return Container(
      decoration: BoxDecoration(
        color: goldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Text('글', style: hand(12, c: goldText))),
          Positioned(
            top: 2,
            left: 4,
            child: Text('$day',
                style: sans(10, w: FontWeight.w700, c: goldText)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- selected
  Widget _selectedDayCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/photos/photo_field.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7월 13일 · 낙서 3개', style: sans(13, w: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('오늘 억새밭!! ♥', style: hand(15, c: brown)),
            ],
          ),
        ],
      ),
    );
  }
}
