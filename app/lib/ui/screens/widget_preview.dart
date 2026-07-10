// Memory Pager — Home-screen widget preview (P1/RV-5, full-screen push target).
//
// Mirrors what the Android AppWidget shows from `GET /widget/{group_id}`.
//
// The one rule that matters (API.md §7): when the latest doodle is *ephemeral*
// the widget must NOT render its thumbnail — putting it on the home screen would
// be a "view" the user never consciously took, and the 5-second fuse only starts
// on a real view. So we show a lock; tapping opens the in-app viewer, and the
// view (`POST /doodles/{id}/view`) is registered there instead.
//
// Tapping the widget lands on the 낙서 사진첩 (SPEC §2). The real widget is a
// native Kotlin AppWidget; this screen is the in-app rehearsal of its contract.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/api/mock_repository.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

class WidgetPreviewScreen extends StatefulWidget {
  const WidgetPreviewScreen({super.key});

  @override
  State<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends State<WidgetPreviewScreen> {
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await appState.loadWidget();
    } catch (_) {
      // Widget data is a convenience read; a failure just leaves the empty state.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Widget tap → 낙서 사진첩 (SPEC §2). Reset the stack the way a real
  /// home-screen launch would.
  void _openAlbum() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell(initialTab: 1)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '홈 위젯',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final w = appState.widgetData;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CpSectionHeader(
                  eyebrow: '미리보기',
                  title: '홈 화면에 이렇게 보여요',
                ),
                const SizedBox(height: 20),
                Center(
                  child: _HomeScreenMock(
                    child: _busy
                        ? const _WidgetShell(child: _Loading())
                        : (w == null
                            ? const _WidgetShell(child: _NoDoodle())
                            : _WidgetShell(
                                onTap: _openAlbum,
                                child: _WidgetFace(data: w),
                              )),
                  ),
                ),
                const SizedBox(height: 26),
                if (w != null) _explain(w),
                const SizedBox(height: 26),
                const CpHair(),
                const SizedBox(height: 18),
                Text(
                  '실제 위젯은 안드로이드 네이티브(AppWidget)로 동작해요. '
                  '이 화면은 위젯이 서버에서 받는 값과 규칙을 그대로 미리 보여줍니다.',
                  style: cpSans(size: 11, color: cpInkA(0.42), height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _explain(WidgetData w) {
    final lines = <String>[
      if (w.isEphemeral)
        '사라지기 모드예요. 위젯에 띄우는 순간을 "확인"으로 볼 수 없어서 썸네일 대신 자물쇠만 보여줘요.'
      else
        '일반 모드예요. 최근 낙서의 썸네일을 그대로 보여줍니다.',
      '탭하면 낙서 사진첩으로 들어가요.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CpEyebrow('규칙', size: 9),
        const SizedBox(height: 12),
        for (final l in lines) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 10),
                child: Container(width: 3, height: 3, color: cpEuc),
              ),
              Expanded(
                child: Text(l,
                    style: cpSans(size: 12, color: cpInkA(0.6), height: 1.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ===========================================================================
// The widget itself
// ===========================================================================

/// A slab of "home screen" so the widget reads as a widget, not a card.
class _HomeScreenMock extends StatelessWidget {
  const _HomeScreenMock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cpDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cpInkA(0.08), width: 0.5),
      ),
      child: child,
    );
  }
}

class _WidgetShell extends StatelessWidget {
  const _WidgetShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: cpPrint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cpInkA(0.12), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
        ),
      );
}

class _NoDoodle extends StatelessWidget {
  const _NoDoodle();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📟', style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 10),
            Text('아직 받은 낙서가 없어요',
                style: cpSans(size: 12, color: cpInkA(0.45))),
          ],
        ),
      );
}

class _WidgetFace extends StatelessWidget {
  const _WidgetFace({required this.data});

  final WidgetData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: data.isEphemeral ? const _Locked() : _Thumb(data: data)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cpInkA(0.10), width: 0.5)),
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  data.senderNickname,
                  overflow: TextOverflow.ellipsis,
                  style: cpSans(size: 12, weight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Text(_stamp(data.createdAt),
                  style: cpSans(size: 10, color: cpInkA(0.45))),
            ],
          ),
        ),
      ],
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cpDim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 22, color: cpInkA(0.5)),
            const SizedBox(height: 8),
            Text('확인하면 사라져요',
                style: cpSans(size: 11, color: cpInkA(0.5), spacing: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.data});

  final WidgetData data;

  @override
  Widget build(BuildContext context) {
    final repo = appState.repo;
    final StrokeData? strokes =
        repo is MockRepository ? repo.strokeDataFor(data.doodleId) : null;
    final Uint8List? photo =
        repo is MockRepository ? repo.photoBytesFor(data.doodleId) : null;

    if (photo != null) return Image.memory(photo, fit: BoxFit.cover);
    if (strokes != null && strokes.strokes.isNotEmpty) {
      return CustomPaint(
        painter: CpDoodlePainter(strokes, background: cpPrint),
        size: Size.infinite,
      );
    }
    // No renderable media — say so, don't invent a picture.
    return Container(
      color: cpPrint,
      child: Center(
        child: Text('🖼', style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String _stamp(DateTime utc) {
  final t = utc.toLocal();
  return '${t.month}/${t.day} ${_two(t.hour)}:${_two(t.minute)}';
}
