// Memory Pager — Settings (P2/ST-1, full-screen push target).
//
// Post-hoc editing of everything onboarding set (API.md §12 ST-1):
//   내 이름       PATCH /me
//   상대 별명     PATCH /groups/{id}/members/{user_id}
//   그룹 이름     PATCH /groups/{id}
//   배경 색상     PATCH /groups/{id}   (6-hex, no '#')
//
// Each field saves on its own; nothing is written until you press 저장, and a
// failure shows the server's own message.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'onboarding.dart';

/// Muted group backgrounds. Wire format is 6-hex uppercase without '#'.
const List<String> _swatches = <String>[
  'FFFFFF',
  'ECEDE9',
  'E6E9E4',
  'EFE8E2',
  'E7EAEE',
  'EDE7EE',
  'E9EFEA',
  'F1EAE1',
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _groupName = TextEditingController();
  final TextEditingController _nickname = TextEditingController();

  String? _busyField;
  String? _error;
  String? _saved;

  @override
  void initState() {
    super.initState();
    _name.text = appState.me?.displayName ?? '';
    _groupName.text = appState.group?.name ?? '';
    _nickname.text = _partner()?.nickname ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _groupName.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Member? _partner() {
    final g = appState.group;
    final meId = appState.me?.id;
    if (g == null) return null;
    for (final m in g.members) {
      if (m.userId != meId) return m;
    }
    return null;
  }

  Future<void> _save(String field, Future<void> Function() body) async {
    setState(() {
      _busyField = field;
      _error = null;
      _saved = null;
    });
    try {
      await body();
      if (mounted) setState(() => _saved = field);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요');
    } finally {
      if (mounted) setState(() => _busyField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '설정',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final g = appState.group;
          final partner = _partner();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CpSectionHeader(eyebrow: '나', title: '내 이름'),
                const SizedBox(height: 14),
                CpTextField(controller: _name, hint: '이름'),
                const SizedBox(height: 12),
                _saveRow(
                  'name',
                  () => appState.updateMe(_name.text.trim()),
                  enabled: _name.text.trim().isNotEmpty,
                ),
                const SizedBox(height: 30),
                const CpHair(),
                const SizedBox(height: 22),

                if (partner != null) ...[
                  CpSectionHeader(
                    eyebrow: '상대',
                    title: '${partner.displayName}님의 별명',
                  ),
                  const SizedBox(height: 14),
                  CpTextField(controller: _nickname, hint: '예) 토리'),
                  const SizedBox(height: 12),
                  _saveRow(
                    'nickname',
                    () => appState.setNickname(
                        partner.userId, _nickname.text.trim()),
                    enabled: _nickname.text.trim().isNotEmpty,
                  ),
                  const SizedBox(height: 30),
                  const CpHair(),
                  const SizedBox(height: 22),
                ],

                const CpSectionHeader(eyebrow: '그룹', title: '그룹 이름'),
                const SizedBox(height: 14),
                CpTextField(controller: _groupName, hint: '예) 우리집'),
                const SizedBox(height: 12),
                _saveRow(
                  'group',
                  () => appState.updateGroup(name: _groupName.text.trim()),
                  enabled: _groupName.text.trim().isNotEmpty,
                ),
                const SizedBox(height: 26),

                CpEyebrow('배경 색상', size: 9),
                const SizedBox(height: 14),
                _swatchRow(g?.backgroundColor),
                const SizedBox(height: 26),

                if (g != null) _inviteRow(g),
                const SizedBox(height: 30),
                const CpHair(),
                const SizedBox(height: 22),

                CpPrimaryButton(
                  label: '온보딩 다시 하기',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const OnboardingScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                Text('그룹을 새로 만들거나 다른 그룹에 가입할 수 있어요.',
                    textAlign: TextAlign.center,
                    style: cpSans(size: 11, color: cpInkA(0.4))),

                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: cpSans(size: 12, color: const Color(0xFFB5654A))),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _saveRow(String field, Future<void> Function() body,
      {required bool enabled}) {
    final busy = _busyField == field;
    final saved = _saved == field;
    return Row(
      children: [
        if (saved)
          Text('저장했어요',
              style: cpSans(size: 11, color: cpEuc, weight: FontWeight.w600)),
        const Spacer(),
        Opacity(
          opacity: enabled && !busy ? 1 : 0.35,
          child: SizedBox(
            width: 96,
            child: CpPrimaryButton(
              label: busy ? '저장 중' : '저장',
              onTap: () {
                if (enabled && !busy) _save(field, body);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _swatchRow(String? current) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final hex in _swatches)
          GestureDetector(
            onTap: () => _save('bg', () => appState.updateGroup(backgroundColor: hex)),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hexToColor(hex),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: (current ?? '').toUpperCase() == hex
                      ? cpEuc
                      : cpInkA(0.14),
                  width: (current ?? '').toUpperCase() == hex ? 1.5 : 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _inviteRow(Group g) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cpPrint,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: cpInkA(0.10), width: 0.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CpEyebrow('초대 코드', size: 9),
              const SizedBox(height: 8),
              SelectableText(
                g.inviteCode.isEmpty ? '—' : g.inviteCode,
                style: cpSans(size: 17, weight: FontWeight.w600, spacing: 2),
              ),
            ],
          ),
          const Spacer(),
          Text('정원 ${g.memberCount}/2',
              style: cpSans(size: 11, color: cpInkA(0.45))),
        ],
      ),
    );
  }
}
