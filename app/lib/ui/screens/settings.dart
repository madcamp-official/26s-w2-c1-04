// Memory Pager — Settings (P2/ST-1, full-screen push target).
//
// Post-hoc editing of everything onboarding set (API.md §12 ST-1):
//   내 이름       PATCH /me
//   상대 별명     PATCH /groups/{id}/members/{user_id}
//   그룹 이름     PATCH /groups/{id}
//   배경 색상     PATCH /groups/{id}   (6-hex, no '#')
//
// Each field saves on its own; nothing is written until you press 저장, and a
// failure shows the server's own message. Styled in the Sumone language: warm
// cream ground, soft rounded cards, one gentle pink accent, outlined line icons
// for chrome — zero emoji. Pet CHARACTERS stay hand-drawn (PetView).

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import '../pet_view.dart';
import 'onboarding.dart';
import 'pet_picker.dart';

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

/// A gentle warm error tone (never pure red) for save failures.
const Color _errorTone = Color(0xFFB5654A);

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

                const CpEyebrow('배경 색상'),
                const SizedBox(height: 14),
                _swatchRow(g?.backgroundColor),
                const SizedBox(height: 30),
                const CpHair(),
                const SizedBox(height: 22),

                const CpSectionHeader(eyebrow: '펫', title: '펫 캐릭터'),
                const SizedBox(height: 14),
                _petRow(context),
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
                  _errorSlip(_error!),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 15, color: cpEuc),
              const SizedBox(width: 6),
              Text('저장했어요',
                  style:
                      cpSans(size: 11, color: cpEuc, weight: FontWeight.w600)),
            ],
          ),
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
    final cur = (current ?? '').toUpperCase();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final hex in _swatches)
          GestureDetector(
            onTap: () =>
                _save('bg', () => appState.updateGroup(backgroundColor: hex)),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hexToColor(hex),
                borderRadius: BorderRadius.circular(cpRadiusSmall),
                border: Border.all(
                  color: cur == hex ? cpEuc : cpInkA(0.12),
                  width: cur == hex ? 2 : 1,
                ),
                boxShadow: cur == hex
                    ? [
                        BoxShadow(
                          color: cpEucA(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: cur == hex
                  ? const Icon(Icons.check, size: 20, color: cpEuc)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _petRow(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PetPickerScreen()),
      ),
      behavior: HitTestBehavior.opaque,
      child: CpMatted(
        mat: 14,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cpMist,
                borderRadius: BorderRadius.circular(cpRadiusSmall),
              ),
              child: PetView(
                  speciesId: appState.petSpecies, size: 48, frozenT: 0.25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('펫 캐릭터 바꾸기',
                      style: cpSans(size: 15, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('둘이 함께 키울 캐릭터를 골라요',
                      style: cpSans(size: 12, color: cpInkA(0.45))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: cpInkA(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _inviteRow(Group g) {
    return CpMatted(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cpEucA(0.10),
              borderRadius: BorderRadius.circular(cpRadiusSmall),
            ),
            child: const Icon(Icons.mail_outline, size: 22, color: cpEuc),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CpEyebrow('초대 코드'),
                const SizedBox(height: 6),
                SelectableText(
                  g.inviteCode.isEmpty ? '—' : g.inviteCode,
                  style: cpSans(size: 18, weight: FontWeight.w700, spacing: 2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cpDim,
              borderRadius: BorderRadius.circular(cpRadiusPill),
              border: Border.all(color: cpInkA(0.06)),
            ),
            child: Text('정원 ${g.memberCount}/2',
                style: cpSans(
                    size: 11, color: cpInkA(0.5), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _errorSlip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _errorTone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(cpRadiusSmall),
        border: Border.all(color: _errorTone.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 16, color: _errorTone),
          const SizedBox(width: 8),
          Flexible(
            child: Text(message,
                style: cpSans(size: 12, color: _errorTone)),
          ),
        ],
      ),
    );
  }
}
