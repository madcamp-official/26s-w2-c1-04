// Memory Pager — Onboarding (P0, full-screen, no bottom nav).
//
// Three steps drive the whole first run, mapping 1:1 onto the contract:
//   ① 내 이름          POST /auth/register   (or PATCH /me when we already exist)
//   ② 그룹 만들기/가입  POST /groups | POST /groups/join
//   ③ 별명 지어주기     PATCH /groups/{id}/members/{user_id}
//
// Creating a group also mints the invite code (and, server-side, the pet and a
// default style model) — we show the code so the partner can join. Joining a
// full group is a real 409; we surface the server's own message rather than
// guessing what went wrong.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';
import 'pet_picker.dart';

const Uuid _uuid = Uuid();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _groupName = TextEditingController(text: '우리집');
  final TextEditingController _petName = TextEditingController(text: '삐삐');
  final TextEditingController _code = TextEditingController();
  final TextEditingController _nickname = TextEditingController();

  int _step = 0;
  bool _joining = false; // step ② mode: false = 만들기, true = 가입
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = appState.me?.displayName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _groupName.dispose();
    _petName.dispose();
    _code.dispose();
    _nickname.dispose();
    super.dispose();
  }

  // -- actions ---------------------------------------------------------------

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } on ApiException catch (e) {
      // Speak the server's own words — never invent a reason.
      if (mounted) setState(() => _error = e.error.message);
      return;
    } catch (_) {
      if (mounted) setState(() => _error = '잠시 후 다시 시도해 주세요');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitName() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = '이름을 입력해 주세요');
      return;
    }
    await _run(() async {
      if (appState.me == null) {
        await appState.register(n, _uuid.v4());
      } else {
        await appState.updateMe(n);
      }
    });
    if (_error == null && mounted) setState(() => _step = 1);
  }

  Future<void> _createGroup() async {
    final g = _groupName.text.trim();
    final p = _petName.text.trim();
    if (g.isEmpty || p.isEmpty) {
      setState(() => _error = '그룹 이름과 펫 이름을 입력해 주세요');
      return;
    }
    await _run(() => appState.createGroup(g, p));
    if (_error == null && mounted) setState(() => _step = 2);
  }

  Future<void> _joinGroup() async {
    final c = _code.text.trim();
    if (c.isEmpty) {
      setState(() => _error = '초대 코드를 입력해 주세요');
      return;
    }
    await _run(() => appState.joinGroup(c));
    if (_error == null && mounted) setState(() => _step = 2);
  }

  Future<void> _finish() async {
    final partner = _partner();
    final nick = _nickname.text.trim();
    if (partner != null && nick.isNotEmpty) {
      await _run(() => appState.setNickname(partner.userId, nick));
      if (_error != null) return;
    }
    if (!mounted) return;
    // The reactive home swaps itself once a group exists. Only the QA deep-link
    // (`?route=onboarding`) pins us here, so leave explicitly in that case.
    if (Uri.base.queryParameters['route'] == 'onboarding') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    }
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

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 15, color: cpEuc),
                    const SizedBox(width: 8),
                    Text(
                      'Memory Pager',
                      style: cpSerif(
                        size: 15,
                        color: cpInkA(0.6),
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _title(),
                  style: cpSerif(
                    size: 26,
                    weight: FontWeight.w600,
                    style: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_subtitle(),
                    style: cpSans(size: 13, color: cpInkA(0.5), height: 1.5)),
                const SizedBox(height: 26),
                _StepDots(step: _step),
                const SizedBox(height: 30),
                switch (_step) {
                  0 => _stepName(),
                  1 => _stepGroup(),
                  2 => _stepPet(),
                  _ => _stepNickname(),
                },
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 15, color: cpEuc),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(_error!,
                            style: cpSans(size: 12, color: cpEuc)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title() => switch (_step) {
        0 => '이름을 알려주세요',
        1 => _joining ? '초대 코드로 들어가기' : '우리 그룹 만들기',
        2 => '펫을 골라주세요',
        _ => '거의 다 됐어요',
      };

  String _subtitle() => switch (_step) {
        0 => '상대에게 보일 이름이에요. 나중에 바꿀 수 있어요.',
        1 => '그룹은 두 사람만의 공간이에요. 정원은 2명입니다.',
        2 => '둘이 함께 키울 펫이에요. 언제든 설정에서 바꿀 수 있어요.',
        _ => '초대 코드를 상대에게 보내고, 별명을 지어주세요.',
      };

  Widget _stepPet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PetPickerBody(),
        const SizedBox(height: 24),
        CpPrimaryButton(label: '다음', onTap: () => setState(() => _step = 3)),
      ],
    );
  }

  Widget _stepName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CpTextField(controller: _name, label: '내 이름', hint: '예) 종혁'),
        const SizedBox(height: 24),
        CpPrimaryButton(label: _busy ? '잠시만요' : '다음', onTap: _submitName),
      ],
    );
  }

  Widget _stepGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CpFilterChip(
                label: '그룹 만들기',
                selected: !_joining,
                onTap: () => setState(() {
                  _joining = false;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CpFilterChip(
                label: '그룹 가입하기',
                selected: _joining,
                onTap: () => setState(() {
                  _joining = true;
                  _error = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_joining) ...[
          CpTextField(controller: _groupName, label: '그룹 이름', hint: '예) 우리집'),
          const SizedBox(height: 16),
          CpTextField(controller: _petName, label: '펫 이름', hint: '예) 삐삐'),
          const SizedBox(height: 24),
          CpPrimaryButton(
              label: _busy ? '만드는 중' : '만들기', onTap: _createGroup),
        ] else ...[
          CpTextField(controller: _code, label: '초대 코드', hint: '예) LOVE8213'),
          const SizedBox(height: 24),
          CpPrimaryButton(label: _busy ? '들어가는 중' : '가입하기', onTap: _joinGroup),
        ],
      ],
    );
  }

  Widget _stepNickname() {
    final g = appState.group;
    final partner = _partner();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (g != null) _InviteCard(code: g.inviteCode, groupName: g.name),
        const SizedBox(height: 24),
        if (partner == null)
          CpMatted(
            mat: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_empty, size: 20, color: cpInkA(0.4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '아직 상대가 들어오지 않았어요.\n상대가 코드로 들어오면 설정에서 별명을 지어줄 수 있어요.',
                    style: cpSans(size: 13, color: cpInkA(0.6), height: 1.5),
                  ),
                ),
              ],
            ),
          )
        else ...[
          CpTextField(
            controller: _nickname,
            label: '${partner.displayName}님의 별명',
            hint: '예) 토리',
          ),
        ],
        const SizedBox(height: 24),
        CpPrimaryButton(label: _busy ? '저장 중' : '시작하기', onTap: _finish),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.code, required this.groupName});

  final String code;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return CpMatted(
      mat: 18,
      inset: 12,
      child: Column(
        children: [
          Icon(Icons.mail_outline, size: 22, color: cpEucA(0.7)),
          const SizedBox(height: 12),
          CpEyebrow('$groupName · 초대 코드', size: 9),
          const SizedBox(height: 12),
          SelectableText(
            code.isEmpty ? '—' : code,
            style: cpSerif(
              size: 24,
              weight: FontWeight.w600,
              style: FontStyle.normal,
              spacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text('이 코드를 상대에게 보내주세요',
              style: cpSans(size: 11, color: cpInkA(0.45))),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == step ? 24 : 18,
            height: 5,
            decoration: BoxDecoration(
              color: i <= step ? cpEuc : cpInkA(0.12),
              borderRadius: BorderRadius.circular(cpRadiusPill),
            ),
          ),
          if (i != 3) const SizedBox(width: 7),
        ],
      ],
    );
  }
}
