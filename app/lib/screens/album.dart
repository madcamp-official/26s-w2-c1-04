// 1e 낙서 사진첩 — 주간 스트립 + 인물 필터 + 낙서 타임라인.
// 디자인 원본: "Memory Pager 디자인.dc.html" #1e (390x844).

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'calendar.dart';
import 'diary.dart';
import 'view_toggle.dart';
import 'viewer.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  // 0 = 모두, 1 = 나(지우), 2 = 상대(나무)
  int _filter = 0;
  bool _grid = false; // 격자 갤러리 ↔ 타임라인(목록) 토글(#7)
  DateTime? _selectedDay; // 주간 스트립에서 고른 날(그날 낙서만 표시). null=전체
  String? _album; // AI 큐레이션 앨범(#6). null = 모두

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperCard,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: mock,
          builder: (context, _) {
            // 선택한 AI 앨범(#6)의 낙서 id 집합. null 이면 전체.
            final albumIds =
                _album == null ? null : mock.albumDoodleIds(_album!);
            final items = mock.doodles.where((d) {
              if (_filter != 0 && (_filter == 1 ? !d.fromMe : d.fromMe)) {
                return false;
              }
              if (_selectedDay != null) {
                final a = d.at;
                if (a == null || !_sameDay(a, _selectedDay!)) return false;
              }
              if (albumIds != null && !albumIds.contains(d.id)) return false;
              return true;
            }).toList();

            // 새 그림 일기 알림(#6) — 낙서들 맨 위에 배너로 뜨고, X 로 닫는다.
            // (격자/목록 어느 보기에서도 보인다.)
            final pendingDiary = mock.pendingDiaryPopup;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('낙서 사진첩', style: sans(22, w: FontWeight.w800)),
                      Row(
                        children: [
                          // 격자/목록 보기 토글(#7) — 겹사진 아이콘 대체.
                          gridListToggle(
                            gridActive: _grid,
                            onGrid: () => setState(() => _grid = true),
                            onList: () => setState(() => _grid = false),
                          ),
                          const SizedBox(width: 8),
                          // 목록/달력 토글 — 달력 화면과 동일한 세그먼트 필로 통일(#9).
                          viewToggle(
                            listActive: true,
                            onList: () {},
                            onCalendar: () => Navigator.of(context)
                                .push(instantRoute(const CalendarScreen())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ---- 본문
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 그림 일기 알림 배너(#6) — 맨 위, 양쪽 보기 공통, X 로 닫기.
                        if (pendingDiary != null) ...[
                          _diaryAlertBanner(pendingDiary),
                          const SizedBox(height: 14),
                        ],
                        _weekStrip(),
                        const SizedBox(height: 14),
                        _personChips(),
                        const SizedBox(height: 12),
                        // AI 큐레이션 앨범 진입(#8) — 항상 노출. 없으면 '모두'만.
                        _albumSection(),
                        const SizedBox(height: 14),
                        if (_selectedDay != null) ...[
                          _selectedDayBar(),
                          const SizedBox(height: 12),
                        ],
                        if (_grid) _photoGrid(items) else ..._timeline(items),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 격자 갤러리
  Widget _photoGrid(List<Doodle> items) {
    if (items.isEmpty) return _emptyHint();
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final d in items)
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ViewerScreen(doodle: d)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // 텍스트 낙서는 이미지가 없어 빈 칸이 되던 것을 텍스트 타일로 채운다.
              child: d.type == DoodleType.text
                  ? Container(
                      color: blushSoft,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        d.text ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: hand(16),
                      ),
                    )
                  : doodleImage(d),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ 주간 스트립
  // 오늘 포함 최근 7일. 그날 주고받은 낙서가 있으면 썸네일, 없으면 빈 원.
  // 탭하면 그날 낙서만 필터(다시 탭하면 해제). 하드코딩 샘플 사진을 없앤다.
  Widget _weekStrip() {
    const wk = ['월', '화', '수', '목', '금', '토', '일'];
    final today = DateTime(mock.today.year, mock.today.month, mock.today.day);
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];

    Doodle? doodleOn(DateTime day) {
      for (final d in mock.doodles) {
        final a = d.at;
        if (a != null && _sameDay(a, day)) return d;
      }
      return null;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          _weekDay(
            label: _sameDay(day, today) ? '오늘' : wk[day.weekday - 1],
            day: day,
            doodle: doodleOn(day),
            isToday: _sameDay(day, today),
            selected:
                _selectedDay != null && _sameDay(day, _selectedDay!),
          ),
      ],
    );
  }

  Widget _weekDay({
    required String label,
    required DateTime day,
    required Doodle? doodle,
    required bool isToday,
    required bool selected,
  }) {
    final has = doodle != null;
    Widget circle;
    if (has && (doodle.asset != null || doodle.imageUrl != null)) {
      circle = ClipOval(
          child: SizedBox(width: 40, height: 40, child: doodleImage(doodle)));
    } else if (has) {
      circle = Container(
        decoration: const BoxDecoration(color: goldBg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('글', style: hand(14, c: goldText)),
      );
    } else {
      circle = Container(
        decoration: const BoxDecoration(color: chipBg, shape: BoxShape.circle),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: has
          ? () => setState(() => _selectedDay = selected
              ? null
              : DateTime(day.year, day.month, day.day))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: sans(11,
                  w: (isToday || selected) ? FontWeight.w800 : FontWeight.w700,
                  c: (isToday || selected) ? coral : muted)),
          const SizedBox(height: 5),
          SizedBox(
            width: 40,
            height: 40,
            child: selected
                ? Stack(clipBehavior: Clip.none, children: [
                    circle,
                    Positioned(
                      left: -4,
                      top: -4,
                      right: -4,
                      bottom: -4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: coral, width: 2.5),
                        ),
                      ),
                    ),
                  ])
                : circle,
          ),
        ],
      ),
    );
  }

  // 선택한 날 표시 + 전체 보기로 해제.
  Widget _selectedDayBar() {
    final d = _selectedDay!;
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('${d.month}월 ${d.day}일 낙서',
                style: sans(12.5, w: FontWeight.w800, c: brown)),
            const Spacer(),
            Text('전체 보기 ✕', style: sans(12, w: FontWeight.w700, c: coral)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 인물 칩
  Widget _personChips() {
    Widget chip(String label, int value) {
      final active = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? ink : chipBg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: sans(12.5,
                w: active ? FontWeight.w700 : FontWeight.w600,
                c: active ? Colors.white : brown),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('모두', 0),
        const SizedBox(width: 8),
        chip(mock.myName, 1),
        const SizedBox(width: 8),
        chip(mock.partnerName, 2),
      ],
    );
  }

  // AI 큐레이션 앨범 섹션(#8) — 항상 노출한다. 앨범이 없으면 '모두' 하나 + 안내 문구,
  // 앨범이 생기면 칩으로 보여주고 새 앨범엔 'NEW' 배지로 알린다.
  Widget _albumSection() {
    Widget chip(String label, String? value) {
      final active = _album == value;
      return GestureDetector(
        onTap: () {
          setState(() => _album = value);
          if (mock.hasNewAlbums) mock.ackAlbums(); // 확인 처리(#8)
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? coral : blushSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: sans(12.5,
                w: FontWeight.w700, c: active ? Colors.white : coral),
          ),
        ),
      );
    }

    final hasAlbums = mock.albums.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('✨ ${mock.petName}가 묶어준 앨범',
                style: sans(11.5, w: FontWeight.w800, c: brownWarm)),
            if (mock.hasNewAlbums) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: coral,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('NEW',
                    style: sans(9, w: FontWeight.w800, c: Colors.white, ls: .5)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('모두', null),
              for (final a in mock.albums) ...[
                const SizedBox(width: 8),
                chip('${a['title']} ${a['count']}', '${a['title']}'),
              ],
            ],
          ),
        ),
        if (!hasAlbums) ...[
          const SizedBox(height: 6),
          Text('낙서가 쌓이면 ${mock.petName}가 주제별 앨범을 만들어줘요',
              style: sans(11.5, c: muted)),
        ],
      ],
    );
  }

  // ------------------------------------------------------------ 타임라인
  List<Widget> _timeline(List<Doodle> items) {
    if (items.isEmpty) return [_emptyHint()];
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 14));
      children.add(_section(items[i]));
    }
    return children;
  }

  Widget _section(Doodle d) {
    final when = d.when == '방금 전' ? '오늘' : d.when;
    final dir = d.fromMe
        ? '${mock.myName} → ${mock.partnerName}'
        : '${mock.partnerName} → ${mock.myName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: '$when ',
            style: sans(13, w: FontWeight.w800),
            children: [
              TextSpan(
                  text: '· $dir', style: sans(13, w: FontWeight.w600, c: muted)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ViewerScreen(doodle: d)),
          ),
          child: (d.asset != null || d.imageUrl != null)
              ? _photoCard(d)
              : _textCard(d),
        ),
      ],
    );
  }

  Widget _photoCard(Doodle d) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        // 낙서는 원본 그대로 보여준다(#9) — 모리 코멘트(caption)를 위에 얹지 않는다.
        child: doodleImage(d),
      ),
    );
  }

  Widget _textCard(Doodle d) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -0.0349, // -2deg
        child: Text(d.text ?? '', style: hand(22, c: coral)),
      ),
    );
  }

  // ------------------------------------------------------------ 그림 일기 알림 배너(#6)
  // 낙서 목록 맨 위에 뜨는 '새 그림 일기' 알림. 탭하면 일기장으로, X 로 닫는다.
  Widget _diaryAlertBanner(DiaryEntry d) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        mock.ackDiaryPopup();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DiaryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: blushSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dashPeach, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: blush,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('🎨', style: sans(18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${mock.petName}의 새 그림 일기',
                      style: sans(13, w: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text('${d.dateLabel} · 눌러서 보기',
                      style: sans(12, c: brownWarm)),
                ],
              ),
            ),
            // X — 알림만 닫는다(일기는 그대로 일기장에 남는다).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: mock.ackDiaryPopup,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                child: Icon(Icons.close_rounded, size: 18, color: brownWarm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 낙서가 아직 없을 때 담백한 빈 상태 안내.
  Widget _emptyHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Text(
        _album != null
            ? '이 앨범엔 아직 낙서가 없어요'
            : '아직 주고받은 낙서가 없어요\n첫 낙서를 보내보세요',
        textAlign: TextAlign.center,
        style: sans(13, w: FontWeight.w600, c: muted, h: 1.5),
      ),
    );
  }
}

