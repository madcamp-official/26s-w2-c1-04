// 4g 설정 — 프로필/그룹/알림.
// 디자인: "썸원 스타일 앱 디자인/Memory Pager 디자인.dc.html" #4g (248-288행) 실측.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mock.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 알림 토글 — 로컬 데모 상태.
  bool _pokeNotif = true;
  bool _reportNotif = true;
  bool _contactNotif = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            // ---- 헤더: ← 설정
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('←',
                          style: sans(16, w: FontWeight.w700, c: muted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('설정', style: sans(20, w: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ListenableBuilder(
                  listenable: mock,
                  builder: (context, _) => Column(
                    children: [
                      // ---- 내 정보
                      _section('내 정보', [
                        _navRow(
                          '내 이름',
                          mock.myName,
                          () => _editField(
                            title: '내 이름',
                            initial: mock.myName,
                            onSave: mock.rename,
                          ),
                        ),
                        _divider(),
                        _navRow(
                          '상대방 별명',
                          mock.partnerNick,
                          () => _editField(
                            title: '상대방 별명',
                            initial: mock.partnerNick,
                            onSave: mock.setPartnerNick,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // ---- 그룹 (그룹 이름은 제거 — 서로 별명 짓는 기능으로 대체)
                      _section('그룹', [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('배경 색상',
                                    style: sans(15, w: FontWeight.w600)),
                              ),
                              for (int i = 0; i < roomColors.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                _swatch(roomColors[i]),
                              ],
                            ],
                          ),
                        ),
                        _divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('초대 코드',
                                    style: sans(15, w: FontWeight.w600)),
                              ),
                              Text(
                                mock.inviteCode,
                                style: sans(14,
                                    w: FontWeight.w700, c: coral, ls: 2),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _copyInvite,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: coral,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    '복사',
                                    style: sans(11.5,
                                        w: FontWeight.w800, c: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // ---- 알림
                      _section('알림', [
                        _toggleRow('콕 찌르기 알림', _pokeNotif,
                            (v) => setState(() => _pokeNotif = v)),
                        _divider(),
                        _toggleRow('월간 레포트 알림', _reportNotif,
                            (v) => setState(() => _reportNotif = v)),
                        _divider(),
                        _toggleRow('연락 유도 알림', _contactNotif,
                            (v) => setState(() => _contactNotif = v)),
                      ]),
                      const SizedBox(height: 16),
                      // ---- 데모 계정 전환 (시연용) — 한 기기로 여러 커플 보여주기
                      _section('데모 계정 전환', [
                        for (var i = 0;
                            i < AppMock.demoAccounts.length;
                            i++) ...[
                          if (i > 0) _divider(),
                          _navRow(
                            AppMock.demoAccounts.keys.elementAt(i),
                            '전환',
                            () => _switchTo(
                                AppMock.demoAccounts.values.elementAt(i)),
                          ),
                        ],
                        _divider(),
                        _navRow('우리 커플로 돌아가기', '복귀', _switchHome),
                      ]),
                      // 로그아웃 · 커플 연결 끊기 버튼 제거(#16). 로그인/로그아웃 개념을
                      // 기능에서 빼둔다(DB 스키마·mock.logout 은 남겨둠 — 401 복구가 사용).
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 조각들

  Widget _section(String label, List<Widget> rows) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line, width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text(label,
                  style: sans(12, w: FontWeight.w800, c: muted, ls: 1)),
            ),
            ...rows,
          ],
        ),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: chipBg,
      );

  Widget _navRow(String label, String value, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(child: Text(label, style: sans(15, w: FontWeight.w600))),
              Text(value, style: sans(14, c: brown)),
              const SizedBox(width: 8),
              Text('›', style: sans(13, c: lineSoft)),
            ],
          ),
        ),
      );

  Widget _swatch(Color c) {
    final selected = mock.roomColor == c;
    return GestureDetector(
      onTap: () => mock.setRoomColor(c),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? coral : Colors.white,
            width: selected ? 2.5 : 2,
          ),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(color: lineSoft, spreadRadius: 1, blurRadius: 0),
                ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool on, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Expanded(child: Text(label, style: sans(15, w: FontWeight.w600))),
            GestureDetector(
              onTap: () => onChanged(!on),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: 46,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: on ? coral : lineSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // ------------------------------------------------------------ 동작

  Future<void> _editField({
    required String title,
    required String initial,
    required void Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: sans(17, w: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
          style: sans(15, w: FontWeight.w600),
          cursorColor: coral,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: coral, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: sans(14, w: FontWeight.w700, c: muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('저장', style: sans(14, w: FontWeight.w800, c: coral)),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) onSave(v);
  }

  void _copyInvite() {
    Clipboard.setData(ClipboardData(text: mock.inviteCode));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            '초대 코드가 복사되었어요',
            style: sans(13.5, w: FontWeight.w600, c: Colors.white),
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  // 설정을 먼저 닫아 아래 게이트가 스플래시를 그리게 한 뒤 전환한다(context 미사용).
  Future<void> _switchTo(String uid) async {
    Navigator.of(context).maybePop();
    await mock.switchAccount(uid);
  }

  Future<void> _switchHome() async {
    Navigator.of(context).maybePop();
    await mock.switchToHome();
  }
}
