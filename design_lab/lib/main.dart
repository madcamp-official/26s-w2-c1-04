// Memory Pager — Design Comparison Gallery
//
// A web-first harness that renders 10 completely different design directions of
// the same app across 3 hero screens, inside a phone frame, for side-by-side
// comparison. Run: flutter run -d chrome

import 'package:flutter/material.dart';
import 'shared/design_variant.dart';
import 'shared/models.dart';
import 'registry.dart';

void main() => runApp(GalleryApp(params: Uri.base.queryParameters));

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key, this.params = const {}});
  final Map<String, String> params;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Pager · Design Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D7EFF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: GalleryPage(params: params),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, this.params = const {}});
  final Map<String, String> params;
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int selected;
  late HeroScreen screen;
  bool solo = false;

  @override
  void initState() {
    super.initState();
    final p = widget.params;
    // Deep-link support for automated QA: ?d=<id>&s=<screen name>&solo=1
    solo = p['solo'] == '1';
    screen = HeroScreen.values.firstWhere(
      (s) => s.name == p['s'],
      orElse: () => HeroScreen.drawSend,
    );
    final id = p['d'];
    final idx = id == null ? -1 : designs.indexWhere((d) => d.id == id);
    selected = idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final design = designs[selected];
    if (solo) {
      return Scaffold(
        backgroundColor: const Color(0xFF14151A),
        body: Center(child: PhoneFrame(child: design.build(context, screen, demoData))),
      );
    }
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Pager · 디자인 비교  (${designs.length}종)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SegmentedButton<HeroScreen>(
              segments: [
                for (final s in HeroScreen.values)
                  ButtonSegment(value: s, icon: Icon(s.icon), label: Text(s.shortLabel)),
              ],
              selected: {screen},
              onSelectionChanged: (v) => setState(() => screen = v.first),
            ),
          ),
        ),
      ),
      drawer: wide ? null : Drawer(child: _designList()),
      body: Row(
        children: [
          if (wide) SizedBox(width: 340, child: _designList()),
          Expanded(
            child: Container(
              color: const Color(0xFF14151A),
              child: Column(
                children: [
                  _infoBar(design),
                  Expanded(child: Center(child: PhoneFrame(child: design.build(context, screen, demoData)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBar(DesignVariant d) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        color: const Color(0xFF1B1D24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: d.accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('#${d.id}  ${d.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text(d.concept, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 2),
            Text('✦ ${d.signature}', style: TextStyle(color: d.accent, fontSize: 12)),
          ],
        ),
      );

  Widget _designList() => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: designs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = designs[i];
          final sel = i == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => selected = i);
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? d.accent.withValues(alpha: 0.18) : const Color(0xFF1B1D24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? d.accent : Colors.white10, width: sel ? 2 : 1),
              ),
              child: Row(
                children: [
                  Container(width: 26, height: 26, decoration: BoxDecoration(color: d.accent, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${d.id}  ${d.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(d.concept,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// Renders a child at fixed logical phone size (428 x 926) with device chrome,
/// scaling down to fit the available viewport. Overrides MediaQuery so the
/// embedded Scaffold lays out as if it were a real phone.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});
  final Widget child;
  static const double w = 428, h = 926;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final scale = ((c.maxHeight - 32) / h).clamp(0.1, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(48),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 4)],
              border: Border.all(color: const Color(0xFF2A2C34), width: 10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(w, h),
                  padding: EdgeInsets.only(top: 44, bottom: 24),
                  devicePixelRatio: 3,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
