// 1f 월간 레포트 — 성장 / 최고의 낙서 / 유형 통계.
// 디자인 원본: "Memory Pager 디자인.dc.html" #1f (390x844).

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: mock,
          builder: (context, _) {
            return Column(
              children: [
                _header(context),
                Expanded(
                  child: mock.real && mock.reportMonths.isEmpty
                      ? _emptyReport()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                          child: Column(
                            children: [
                              _growthCard(),
                              const SizedBox(height: 14),
                              // 데모는 하드코딩 카드, 실서버는 백엔드 best_doodle 이 있을 때만 표시.
                              // (best_doodle 이 null 인 달엔 가짜 데이터를 보여주지 않는다.)
                              if (!mock.real) ...[
                                _bestDoodleCard(),
                                const SizedBox(height: 14),
                              ] else if (mock.reportBestImage != null ||
                                  (mock.reportBestText?.isNotEmpty ?? false)) ...[
                                _bestDoodleCard(),
                                const SizedBox(height: 14),
                              ],
                              _statsCard(),
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

  // ---------------------------------------------------------------- header
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.maybePop(context),
            child: Text('←', style: sans(17, w: FontWeight.w700, c: muted)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('월간 소식이 도착했어요', style: hand(15, c: coral)),
              const SizedBox(height: 2),
              Text(
                  mock.real && mock.reportMonths.isEmpty
                      ? '월간 레포트'
                      : '${mock.reportMonthLabel}의 레포트',
                  style: sans(22, w: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: line, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: mock.canPrevReport
                      ? () => mock.shiftReportMonth(-1)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('◀',
                        style: sans(13,
                            w: FontWeight.w700,
                            c: mock.canPrevReport ? brown : lineSoft)),
                  ),
                ),
                Text(mock.reportMonthLabel,
                    style: sans(13, w: FontWeight.w700, c: brown)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: mock.canNextReport
                      ? () => mock.shiftReportMonth(1)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('▶',
                        style: sans(13,
                            w: FontWeight.w700,
                            c: mock.canNextReport ? brown : lineSoft)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 신규 그룹(실서버, 리포트 없음)용 빈 상태 — 가짜 '6월 리포트'를 보여주지 않는다.
  Widget _emptyReport() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PetFace(size: 88),
            const SizedBox(height: 18),
            Text('아직 리포트가 없어요', style: sans(16, w: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '한 달치 낙서와 활동이 쌓이면\n${mock.petName}가 월간 소식을 정리해 줄 거예요.',
              textAlign: TextAlign.center,
              style: sans(13, c: hintWarm, h: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- card 1
  Widget _growthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const PetFace(size: 76),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        '${mock.petName}가 이만큼 컸어요',
                        style: sans(15, w: FontWeight.w800),
                      ),
                    ),
                    Text(
                      mock.levelLabel,
                      style: sans(12, w: FontWeight.w800, c: coral),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    height: 10,
                    color: chipBg,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: mock.growthPct,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mock.real && mock.reportLevelEnd > 0
                      ? '낙서 ${mock.reportDoodles}개를 먹고 Lv.${mock.reportLevelStart} → Lv.${mock.reportLevelEnd} 로 자랐어요'
                      : '낙서 ${mock.reportDoodles}개를 먹고 무럭무럭 자랐어요',
                  style: sans(12, c: hintWarm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- card 2
  Widget _bestDoodleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 달 최고의 낙서',
            style: sans(13, w: FontWeight.w800, c: dashPeach, ls: 1),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 실서버: best_doodle 이미지(있으면). 텍스트 낙서만 이긴 경우엔 이미지가
                  // 없으니 배경을 어둡게 두고 문구만 보여준다. 데모는 억새밭 샘플.
                  if (!mock.real)
                    Image.asset('assets/photos/photo_field.png', fit: BoxFit.cover)
                  else if (mock.reportBestImage != null)
                    Image.network(mock.reportBestImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: brown))
                  else
                    Container(color: brown),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: 12,
                    child: Text(
                      mock.real
                          ? (mock.reportBestText?.isNotEmpty ?? false
                              ? mock.reportBestText!
                              : '이번 달 가장 사랑받은 낙서 ♥')
                          : '오늘 억새밭!! ♥',
                      style: hand(24, c: Colors.white).copyWith(
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mock.real
                ? '${mock.reportBestDate ?? ''} · 이번 달 최고의 낙서'
                : '6월 21일 · ${mock.myName} → ${mock.partnerName} · 답장 2번을 받았어요',
            style: sans(12.5, c: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- card 3
  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('어떤 낙서가 많았을까?', style: sans(14, w: FontWeight.w800)),
          const SizedBox(height: 12),
          _barRow('사진', mock.reportPhotos, _barFrac(mock.reportPhotos), salmon),
          const SizedBox(height: 9),
          _barRow('그림', mock.reportDrawings, _barFrac(mock.reportDrawings),
              const Color(0xFFFFC0B2)),
          const SizedBox(height: 9),
          _barRow('텍스트', mock.reportTexts, _barFrac(mock.reportTexts), blush),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBox('${mock.reportPokes}', '콕 찌르기'),
              const SizedBox(width: 10),
              _statBox('${mock.reportDoodles}', '낙서'),
              const SizedBox(width: 10),
              _statBox('${mock.reportAnswers}', '질문 답변'),
            ],
          ),
        ],
      ),
    );
  }

  // 세 유형 중 최댓값을 기준으로 막대 폭을 정한다(하드코딩 폭 대신 실데이터 비례).
  double _barFrac(int count) {
    final maxCount = [mock.reportPhotos, mock.reportDrawings, mock.reportTexts]
        .fold<int>(1, (a, b) => b > a ? b : a);
    return (count / maxCount).clamp(0.0, 1.0);
  }

  Widget _barRow(String label, int count, double pct, Color fill) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: sans(12.5, w: FontWeight.w700, c: brown)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 22,
              color: paper,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$count', style: sans(12, w: FontWeight.w800)),
      ],
    );
  }

  Widget _statBox(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: blushSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(number, style: sans(18, w: FontWeight.w800, c: coral)),
            const SizedBox(height: 2),
            Text(label, style: sans(11.5, c: brown)),
          ],
        ),
      ),
    );
  }
}
