// 사진첩(목록)·달력 공용 토글 세그먼트(#9). 두 화면이 같은 필을 써서 오갈 때
// 연속성이 유지된다. 전환은 무애니메이션이라 화면 이동이 아니라 탭 전환처럼 느껴진다.

import 'package:flutter/material.dart';

import '../theme.dart';

/// 슬라이드 없이 즉시 전환하는 라우트 — 토글이 탭처럼 느껴지게 한다.
Route<T> instantRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => page,
    );

/// [목록 | 달력] 세그먼트 필. 활성 탭은 흰 배경 + 그림자로 강조.
Widget viewToggle({
  required bool listActive,
  required VoidCallback onList,
  required VoidCallback onCalendar,
}) {
  Widget seg(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: active ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: active
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Text(
          label,
          style: active
              ? sans(12, w: FontWeight.w800)
              : sans(12, w: FontWeight.w600, c: muted),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: chipBg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        seg('목록', listActive, onList),
        seg('달력', !listActive, onCalendar),
      ],
    ),
  );
}
