// 2d 사진첩 · 추억 달력 — 날짜에 낙서가 쌓임.
// 디자인: Memory Pager 디자인.dc.html #2d (390px 카드) 실측값 그대로.
// 월 이동·날짜 선택 동작. 2026-07은 디자인 샘플 장식, 그 외 달은 실제 그리드.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'viewer.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month; // 표시 중인 달(1일)
  late DateTime _selected; // 선택된 날짜

  @override
  void initState() {
    super.initState();
    final t = mock.today;
    _month = DateTime(t.year, t.month);
    _selected = DateTime(t.year, t.month, t.day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 그 날 주고받은 실제 낙서들(날짜별). 하드코딩 샘플을 대체한다.
  List<Doodle> _doodlesOn(DateTime day) => mock.doodles
      .where((d) => d.at != null && _sameDay(d.at!, day))
      .toList();

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      // 이동한 달의 1일을 선택(그 달에 오늘이 있으면 오늘).
      final t = mock.today;
      _selected = (t.year == _month.year && t.month == _month.month)
          ? DateTime(t.year, t.month, t.day)
          : DateTime(_month.year, _month.month, 1);
    });
  }

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
        GestureDetector(
          onTap: () => _shiftMonth(-1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text('◀', style: sans(13, c: muted)),
          ),
        ),
        const SizedBox(width: 10),
        Text('${_month.year}년 ${_month.month}월',
            style: sans(15, w: FontWeight.w800)),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _shiftMonth(1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text('▶', style: sans(13, c: muted)),
          ),
        ),
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
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday % 7; // 일요일 시작(월=1..일=7 → 일=0)
    final daysIn = DateTime(_month.year, _month.month + 1, 0).day;

    final cells = <Widget>[];
    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysIn; day++) {
      cells.add(_cellFor(day));
    }
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  /// 그 날의 셀 — 실제 낙서 데이터로 그린다.
  /// 사진/그림 있으면 썸네일, 텍스트만 있으면 '글' 배지, 없으면 숫자.
  Widget _cellFor(int day) {
    final date = DateTime(_month.year, _month.month, day);
    final ds = _doodlesOn(date);
    final selected = _sameDay(date, _selected);
    final t = mock.today;
    final dim = date.isAfter(DateTime(t.year, t.month, t.day));

    if (ds.isEmpty) return _plainCell(date, day, selected, dim: dim);
    Doodle? photo;
    for (final d in ds) {
      if (d.asset != null || d.imageUrl != null) {
        photo = d;
        break;
      }
    }
    if (photo != null) return _photoCell(date, day, photo, selected);
    return _markCell(date, day, selected); // 텍스트만 있던 날
  }

  // 선택 하이라이트: 채워진 셀도 확실히 보이도록 셀 밖으로 coral 2.5 링을 두른다.
  Widget _wrapSelected(Widget cell, bool selected, {double radius = 13}) {
    if (!selected) return cell;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        cell,
        Positioned(
          left: -3.5,
          top: -3.5,
          right: -3.5,
          bottom: -3.5,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: coral, width: 2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 낙서 없는 날(탭 → 선택). 선택되면 coral 배경으로 확실히 강조.
  Widget _plainCell(DateTime date, int day, bool selected, {bool dim = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: selected
            ? BoxDecoration(color: coral, borderRadius: BorderRadius.circular(10))
            : null,
        child: Center(
          child: Text('$day',
              style: sans(12,
                  w: selected ? FontWeight.w800 : FontWeight.w400,
                  c: selected
                      ? Colors.white
                      : (dim ? lineSoft : muted))),
        ),
      ),
    );
  }

  /// 사진/그림이 있던 날 — 썸네일 + 흰 숫자. 선택되면 coral 링.
  Widget _photoCell(DateTime date, int day, Doodle d, bool selected) {
    final cell = GestureDetector(
      onTap: () => setState(() => _selected = date),
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            doodleImage(d),
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
      ),
    );
    return _wrapSelected(cell, selected);
  }

  /// 텍스트 낙서('글')만 있던 날. 선택되면 coral 링.
  Widget _markCell(DateTime date, int day, bool selected) {
    final cell = GestureDetector(
      onTap: () => setState(() => _selected = date),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
    return _wrapSelected(cell, selected);
  }

  // ---------------------------------------------------------------- selected
  Widget _selectedDayCard() {
    final ds = _doodlesOn(_selected);
    final first = ds.isEmpty ? null : ds.first;
    final hasPhoto =
        first != null && (first.asset != null || first.imageUrl != null);
    final preview = first == null
        ? '이 날의 낙서가 없어요'
        : (first.caption ?? first.text ?? '눌러서 보기');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: first == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ViewerScreen(doodle: first)),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                    width: 48, height: 48, child: doodleImage(first)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ds.isEmpty
                        ? '${_selected.month}월 ${_selected.day}일'
                        : '${_selected.month}월 ${_selected.day}일 · 낙서 ${ds.length}개',
                    style: sans(13, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hand(15, c: ds.isEmpty ? muted : brown)),
                ],
              ),
            ),
            if (first != null) Text('→', style: sans(13, c: brownWarm)),
          ],
        ),
      ),
    );
  }
}
