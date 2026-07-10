// design_03_clay_room — "Clay Room".
//
// A tiny isometric 3D room the shared pet actually lives in. Every surface is a
// soft-extruded clay object with a plump ambient shadow and a matte putty
// palette. Type is chunky and rounded and sits IN the scene. On the pet screen
// two-finger spin (a horizontal drag on web) rotates the whole diorama in real
// 3D — the pet billboards to keep facing your finger, framed album photos hang
// on the rotating back wall, and owned furniture stands on the floor.
//
// Self-contained: Flutter Material only. No packages, no assets, no network,
// no Random, no DateTime.now(). All imagery is gradient + emoji from demo data.
// Everything except the public [Design03] is private with a _D03 / _d03 prefix.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// --------------------------------------------------------------- palette
const Color _d03Butter = Color(0xFFF4D58D); // warm butter
const Color _d03Clay = Color(0xFFE8A6A1); // clay-pink
const Color _d03Sage = Color(0xFFA9C4A0); // sage
const Color _d03Putty = Color(0xFFEFE7DC); // putty base
const Color _d03Occ = Color(0xFF8A6A52); // warm-brown occlusion
const Color _d03Ink = Color(0xFF4A3527); // chunky ink brown
const Color _d03Wall = Color(0xFFF3ECDF); // room wall
const Color _d03WallSide = Color(0xFFE7DBC7); // shaded wall

Color _d03Darken(Color c, [double amt = 0.16]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amt).clamp(0.0, 1.0)).toColor();
}

Color _d03Lighten(Color c, [double amt = 0.08]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amt).clamp(0.0, 1.0)).toColor();
}

TextStyle _d03Type({
  double size = 15,
  Color color = _d03Ink,
  FontWeight weight = FontWeight.w800,
  double spacing = 0.2,
  double height = 1.05,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// ============================================================== the variant
class Design03 extends DesignVariant {
  @override
  String get id => '03';
  @override
  String get name => 'Clay Room';
  @override
  String get concept =>
      '펫이 실제로 사는 아이소메트릭 3D 점토 방 — 부드럽게 눌러 빚은 오브젝트, 통통한 그림자, 매트한 퍼티 색.';
  @override
  String get signature =>
      '두 손가락으로 방을 3D로 돌리면 펫이 손가락을 따라 고개를 돌리고, 벽에 걸린 액자와 자란 만큼 늘어난 가구가 함께 회전한다.';
  @override
  String get inspiration =>
      'Isometric clay-render toy rooms + soft-body 3D UI trend (Blender clay dioramas).';
  @override
  Color get accent => _d03Clay;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d03Type(),
      child: switch (screen) {
        HeroScreen.drawSend => _D03DrawSend(data: data),
        HeroScreen.petHome => _D03PetHome(data: data),
        HeroScreen.memoryAlbum => _D03Album(data: data),
      },
    );
  }
}

// ================================================================ clay atoms
/// A soft-extruded clay slab: matte vertical sheen, a hard extruded "side" and
/// a plump warm-brown ambient shadow beneath.
class _D03Clay extends StatelessWidget {
  const _D03Clay({
    this.child,
    required this.color,
    this.radius = 22,
    this.depth = 7,
    this.padding,
    this.width,
  });
  final Widget? child;
  final Color color;
  final double radius;
  final double depth;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d03Lighten(color, 0.08), color],
        ),
        boxShadow: [
          BoxShadow(
            color: _d03Darken(color, 0.15),
            offset: Offset(0, depth),
            blurRadius: 0,
          ),
          BoxShadow(
            color: _d03Occ.withOpacity(0.26),
            offset: Offset(0, depth + 9),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Chunky rounded display type with a soft extruded drop so it "sits" in scene.
class _D03Puff extends StatelessWidget {
  const _D03Puff(
    this.text, {
    this.size = 34,
    this.color = _d03Ink,
    this.depth = 3,
    this.spacing = 0.4,
  });
  final String text;
  final double size;
  final Color color;
  final double depth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final base = _d03Type(
      size: size,
      weight: FontWeight.w900,
      spacing: spacing,
      height: 1.0,
    );
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(0, depth),
          child: Text(text, style: base.copyWith(color: _d03Darken(color, 0.24))),
        ),
        Text(text, style: base.copyWith(color: color)),
      ],
    );
  }
}

/// A round clay button (tool / nav / back).
class _D03Circle extends StatelessWidget {
  const _D03Circle({
    required this.child,
    required this.color,
    this.size = 52,
    this.onTap,
  });
  final Widget child;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_d03Lighten(color, 0.10), color],
          ),
          boxShadow: [
            BoxShadow(
              color: _d03Darken(color, 0.16),
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: _d03Occ.withOpacity(0.24),
              offset: const Offset(0, 12),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Chunky clay progress meter.
class _D03Gauge extends StatelessWidget {
  const _D03Gauge({required this.value, this.fill = _d03Butter, this.height = 20});
  final double value;
  final Color fill;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: _d03Darken(_d03Putty, 0.06),
            borderRadius: BorderRadius.circular(height),
            boxShadow: [
              BoxShadow(
                color: _d03Occ.withOpacity(0.18),
                offset: const Offset(0, 3),
                blurRadius: 6,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                width: (w * value.clamp(0.0, 1.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_d03Lighten(fill, 0.10), fill],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _d03Darken(fill, 0.16),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom clay nav shared by pet + album screens.
class _D03Nav extends StatelessWidget {
  const _D03Nav({required this.current});
  final int current; // 0 pet · 1 album · 2 talk

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.pets_rounded, '펫키우기'),
      (Icons.photo_library_rounded, '사진첩'),
      (Icons.brush_rounded, '소통'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: _d03Wall,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _d03Occ.withOpacity(0.22),
            offset: const Offset(0, -4),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < items.length; i++)
                _navItem(items[i].$1, items[i].$2, i == current),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool sel) {
    final base = sel ? _d03Clay : _d03Putty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: sel ? 18 : 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d03Lighten(base, 0.08), base],
        ),
        boxShadow: sel
            ? [
                BoxShadow(
                  color: _d03Darken(base, 0.16),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _d03Ink),
          if (sel) ...[
            const SizedBox(width: 7),
            Text(label, style: _d03Type(size: 12.5, weight: FontWeight.w900)),
          ],
        ],
      ),
    );
  }
}

// ================================================================ DRAW & SEND
class _D03DrawSend extends StatefulWidget {
  const _D03DrawSend({required this.data});
  final AppData data;
  @override
  State<_D03DrawSend> createState() => _D03DrawSendState();
}

class _D03DrawSendState extends State<_D03DrawSend> {
  int pen = 1;
  double thickness = 8;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    final penColor = demoPenColors[pen];
    return Scaffold(
      backgroundColor: _d03Putty,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- top bar
              Row(
                children: [
                  _D03Circle(
                    color: _d03Putty,
                    size: 48,
                    onTap: () {},
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 22, color: _d03Ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TO',
                            style: _d03Type(
                                size: 10,
                                color: _d03Occ,
                                weight: FontWeight.w900,
                                spacing: 3)),
                        const SizedBox(height: 2),
                        _D03Puff('${couple.partnerNickname}에게', size: 26),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: _D03Clay(
                      color: _d03Clay,
                      radius: 20,
                      depth: 6,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('보내기',
                              style: _d03Type(
                                  size: 14,
                                  color: Colors.white,
                                  weight: FontWeight.w900)),
                          const SizedBox(width: 6),
                          const Icon(Icons.send_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ---- canvas: a debossed clay tablet
              Expanded(child: _canvas(penColor)),
              const SizedBox(height: 16),
              // ---- pen palette
              _sectionLabel('점토 펜'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < demoPenColors.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => pen = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: pen == i ? 46 : 38,
                        height: pen == i ? 46 : 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _d03Lighten(demoPenColors[i], 0.14),
                              demoPenColors[i],
                            ],
                          ),
                          border: Border.all(
                            color: pen == i ? _d03Ink : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _d03Darken(demoPenColors[i], 0.18),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: _d03Occ.withOpacity(0.22),
                              offset: const Offset(0, 8),
                              blurRadius: 10,
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // ---- thickness
              Row(
                children: [
                  Text('굵기',
                      style: _d03Type(size: 12, color: _d03Occ, spacing: 2)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 12,
                        activeTrackColor: _d03Clay,
                        inactiveTrackColor: _d03Darken(_d03Putty, 0.06),
                        thumbColor: _d03Butter,
                        overlayColor: _d03Clay.withOpacity(0.15),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 13),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: thickness,
                        min: 2,
                        max: 22,
                        onChanged: (v) => setState(() => thickness = v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text('${thickness.round()}',
                        textAlign: TextAlign.right,
                        style: _d03Type(size: 15, weight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 4),
                  const Text('💡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(mode.description,
                        style: _d03Type(
                            size: 12,
                            color: _d03Occ,
                            weight: FontWeight.w600,
                            height: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ---- bottom actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _action(Icons.photo_library_rounded, '갤러리', _d03Sage),
                  _action(Icons.photo_camera_rounded, '사진', _d03Butter),
                  _action(Icons.notifications_active_rounded, '찌르기', _d03Clay),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: _d03Type(size: 11, color: _d03Occ, weight: FontWeight.w900, spacing: 2.5));

  Widget _canvas(Color penColor) {
    return Container(
      decoration: BoxDecoration(
        color: _d03Lighten(_d03Putty, 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _d03Darken(_d03Putty, 0.08), width: 3),
        boxShadow: [
          // debossed: inner-ish top shadow + tiny outer lift
          BoxShadow(
            color: _d03Occ.withOpacity(0.16),
            offset: const Offset(0, -3),
            blurRadius: 10,
            spreadRadius: -6,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // preview clay stroke reflecting pen color + thickness
          Positioned(
            left: 26,
            right: 26,
            top: 40,
            child: _D03ClayStroke(color: penColor, thickness: thickness),
          ),
          const Positioned(
            right: 22,
            bottom: 22,
            child: Text('✏️', style: TextStyle(fontSize: 30)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎨', style: const TextStyle(fontSize: 46)),
                const SizedBox(height: 10),
                Text('여기에 낙서해서 빚어 보내기',
                    style: _d03Type(
                        size: 14, color: _d03Occ, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return _D03Clay(
      color: _d03Darken(_d03Putty, 0.04),
      radius: 22,
      depth: 5,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final m in SendMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => mode = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: mode == m
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_d03Lighten(_d03Butter, 0.08), _d03Butter],
                          )
                        : null,
                    boxShadow: mode == m
                        ? [
                            BoxShadow(
                              color: _d03Darken(_d03Butter, 0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m == SendMode.normal
                            ? Icons.push_pin_rounded
                            : Icons.timer_rounded,
                        size: 16,
                        color: _d03Ink,
                      ),
                      const SizedBox(width: 6),
                      Text(m.label,
                          style: _d03Type(
                              size: 14, weight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _D03Circle(
          color: color,
          size: 56,
          onTap: () {},
          child: Icon(icon, size: 24, color: _d03Ink),
        ),
        const SizedBox(height: 8),
        Text(label, style: _d03Type(size: 12, weight: FontWeight.w800)),
      ],
    );
  }
}

class _D03ClayStroke extends StatelessWidget {
  const _D03ClayStroke({required this.color, required this.thickness});
  final Color color;
  final double thickness;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: thickness.clamp(3, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d03Lighten(color, 0.12), color],
        ),
        boxShadow: [
          BoxShadow(
            color: _d03Darken(color, 0.18),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
          BoxShadow(
            color: _d03Occ.withOpacity(0.18),
            offset: const Offset(0, 6),
            blurRadius: 8,
            spreadRadius: -3,
          ),
        ],
      ),
    );
  }
}

// ================================================================== PET HOME
class _D03PetHome extends StatefulWidget {
  const _D03PetHome({required this.data});
  final AppData data;
  @override
  State<_D03PetHome> createState() => _D03PetHomeState();
}

class _D03PetHomeState extends State<_D03PetHome> {
  double _spin = 0.30; // radians of diorama rotation
  bool _patted = false;

  void _onPan(DragUpdateDetails d) {
    setState(() {
      _spin = (_spin + d.delta.dx * 0.012).clamp(-0.95, 0.95);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    return Scaffold(
      backgroundColor: _d03Putty,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- header: name + level + coins
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _D03Puff(pet.name, size: 32),
                      const SizedBox(height: 8),
                      _D03Clay(
                        color: _d03Sage,
                        radius: 14,
                        depth: 4,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        child: Text('Lv.${pet.level}',
                            style: _d03Type(
                                size: 13, weight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D03Clay(
                    color: _d03Butter,
                    radius: 18,
                    depth: 5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text('${pet.coins}',
                            style: _d03Type(
                                size: 16, weight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ---- the rotatable diorama
            Expanded(
              child: ClipRect(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _onPan,
                  onTap: () => setState(() => _patted = !_patted),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Center(child: _room(pet)),
                      ),
                      if (_patted)
                        Positioned(
                          top: 6,
                          left: 24,
                          right: 24,
                          child: Center(child: _speech(pet.speech)),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 6,
                        child: Center(
                          child: _D03Clay(
                            color: _d03Wall,
                            radius: 16,
                            depth: 3,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Text(
                              _patted
                                  ? '두 손가락으로 방 돌리기 · 톡 쓰다듬기'
                                  : '두 손가락으로 방을 돌리고 · 톡 쓰다듬어요',
                              style: _d03Type(
                                  size: 11.5,
                                  color: _d03Occ,
                                  weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ---- growth gauge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  Text('성장',
                      style: _d03Type(
                          size: 12, color: _d03Occ, spacing: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: _D03Gauge(value: pet.growth)),
                  const SizedBox(width: 12),
                  Text('${(pet.growth * 100).round()}%',
                      style: _d03Type(size: 15, weight: FontWeight.w900)),
                ],
              ),
            ),
            // ---- store shelf (자란 만큼 늘어난 가구/상점)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  Text('스토어',
                      style: _d03Type(
                          size: 13,
                          color: _d03Occ,
                          weight: FontWeight.w900,
                          spacing: 2)),
                  const SizedBox(width: 8),
                  Text('방을 채우는 점토 가구',
                      style: _d03Type(
                          size: 11,
                          color: _d03Occ,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                itemCount: pet.store.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _storeTile(pet.store[i]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _D03Nav(current: 0),
    );
  }

  // -------- the 3D clay room
  Widget _room(Pet pet) {
    const w = 208.0, h = 150.0, d = 208.0;
    final owned = pet.store.where((e) => e.owned).toList();
    final hat = pet.store
        .where((e) => e.equipped && e.category == '모자')
        .cast<PetItem?>()
        .firstWhere((_) => true, orElse: () => null);
    // furniture: owned items that are not the worn hat, first two.
    final furniture =
        owned.where((e) => !(e.equipped && e.category == '모자')).toList();

    final parent = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(0.32)
      ..rotateY(_spin);

    Widget face(Matrix4 m, Widget c) =>
        Transform(alignment: Alignment.center, transform: m, child: c);

    // walls + floor
    final floor = face(
      Matrix4.identity()
        ..translate(0.0, h / 2, 0.0)
        ..rotateX(math.pi / 2),
      _D03RoomPanel(
        width: w,
        height: d,
        color: _d03Darken(_d03Putty, 0.05),
        rug: _d03Sage,
      ),
    );
    final backWall = face(
      Matrix4.identity()..translate(0.0, 0.0, -d / 2),
      _D03BackWall(width: w, height: h, album: widget.data.album),
    );
    final leftWall = face(
      Matrix4.identity()
        ..translate(-w / 2, 0.0, 0.0)
        ..rotateY(math.pi / 2),
      _D03SideWall(width: d, height: h, streak: widget.data.couple.streakDays),
    );

    // billboarded pet: counter-rotates so it keeps facing your finger.
    final petFig = face(
      Matrix4.identity()
        ..translate(0.0, h / 2 - 58, 26.0)
        ..rotateY(-_spin * 1.25),
      _D03PetFigure(pet: pet, hat: hat, gaze: _spin),
    );

    // furniture standing on the floor
    final furnWidgets = <Widget>[];
    const spots = [
      Offset(-62, -34),
      Offset(66, -12),
      Offset(-8, 44),
    ];
    for (int i = 0; i < furniture.length && i < spots.length; i++) {
      final it = furniture[i];
      furnWidgets.add(face(
        Matrix4.identity()
          ..translate(spots[i].dx, h / 2 - 24, spots[i].dy)
          ..rotateY(-_spin),
        _D03Furniture(emoji: it.emoji, label: it.name),
      ));
    }

    return SizedBox(
      width: 320,
      height: 300,
      child: Transform(
        alignment: Alignment.center,
        transform: parent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            floor,
            leftWall,
            backWall,
            ...furnWidgets,
            petFig,
          ],
        ),
      ),
    );
  }

  Widget _speech(String text) {
    return _D03Clay(
      color: Colors.white,
      radius: 20,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💬', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: _d03Type(size: 14, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _storeTile(PetItem it) {
    final base = it.equipped
        ? _d03Clay
        : it.owned
            ? _d03Sage
            : _d03Wall;
    return _D03Clay(
      color: base,
      radius: 20,
      depth: 6,
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(it.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          Text(it.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _d03Type(size: 12, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          _tag(it),
        ],
      ),
    );
  }

  Widget _tag(PetItem it) {
    if (it.equipped) {
      return _pill('착용중', _d03Ink, Colors.white);
    }
    if (it.owned) {
      return _pill('보유', Colors.white, _d03Ink);
    }
    return _pill('🪙 ${it.price}', _d03Butter, _d03Ink);
  }

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(t,
            style: _d03Type(size: 10.5, color: fg, weight: FontWeight.w900)),
      );
}

// ---- room parts ------------------------------------------------------------
class _D03RoomPanel extends StatelessWidget {
  const _D03RoomPanel({
    required this.width,
    required this.height,
    required this.color,
    required this.rug,
  });
  final double width, height;
  final Color color;
  final Color rug;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Container(
        width: width * 0.62,
        height: height * 0.62,
        decoration: BoxDecoration(
          color: rug,
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: _d03Darken(rug, 0.12),
              blurRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _D03BackWall extends StatelessWidget {
  const _D03BackWall({
    required this.width,
    required this.height,
    required this.album,
  });
  final double width, height;
  final List<Doodle> album;
  @override
  Widget build(BuildContext context) {
    final shots = album.take(3).toList();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d03Lighten(_d03Wall, 0.04), _d03Wall],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final s in shots) _frame(s)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _frame(Doodle d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 2, height: 8, color: _d03Occ.withOpacity(0.4)),
        _D03Clay(
          color: _d03Butter,
          radius: 10,
          depth: 4,
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 42,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: d.swatch,
              ),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ],
    );
  }
}

class _D03SideWall extends StatelessWidget {
  const _D03SideWall({
    required this.width,
    required this.height,
    required this.streak,
  });
  final double width, height;
  final int streak;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d03Lighten(_d03WallSide, 0.03), _d03WallSide],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: _D03Clay(
        color: _d03Clay,
        radius: 14,
        depth: 4,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text('$streak일',
                style: _d03Type(
                    size: 13, color: Colors.white, weight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _D03PetFigure extends StatelessWidget {
  const _D03PetFigure({required this.pet, required this.hat, required this.gaze});
  final Pet pet;
  final PetItem? hat;
  final double gaze; // spin used as a subtle look offset
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // plump ground shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: 78,
              height: 20,
              decoration: BoxDecoration(
                color: _d03Occ.withOpacity(0.28),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 74)),
          ),
          if (hat != null)
            Positioned(
              // hat leans toward the finger for a live "head-track" feel
              top: 4 + gaze * 4,
              left: 46 + gaze * 12,
              child: Text(hat!.emoji, style: const TextStyle(fontSize: 34)),
            ),
        ],
      ),
    );
  }
}

class _D03Furniture extends StatelessWidget {
  const _D03Furniture({required this.emoji, required this.label});
  final String emoji;
  final String label;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 38)),
          Container(
            width: 44,
            height: 12,
            decoration: BoxDecoration(
              color: _d03Occ.withOpacity(0.24),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================= MEMORY ALBUM
class _D03Album extends StatefulWidget {
  const _D03Album({required this.data});
  final AppData data;
  @override
  State<_D03Album> createState() => _D03AlbumState();
}

class _D03AlbumState extends State<_D03Album> {
  bool byDate = true;
  DoodleType? filter;

  static const _frameColors = [_d03Butter, _d03Clay, _d03Sage];

  @override
  Widget build(BuildContext context) {
    final items = widget.data.album
        .where((d) => filter == null || d.type == filter)
        .toList();
    if (byDate) {
      items.sort((a, b) => b.at.compareTo(a.at));
    } else {
      items.sort((a, b) => a.type.index.compareTo(b.type.index));
    }

    return Scaffold(
      backgroundColor: _d03Putty,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- header + sort toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _D03Puff('낙서 사진첩', size: 28),
                  const Spacer(),
                  _sortToggle(),
                ],
              ),
            ),
            // ---- type filters
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip('전체', filter == null,
                      () => setState(() => filter = null)),
                  for (final t in DoodleType.values)
                    _filterChip(t.label, filter == t,
                        () => setState(() => filter = t)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ---- framed clay photo wall
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) =>
                    _frame(items[i], _frameColors[i % _frameColors.length]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _D03Nav(current: 1),
    );
  }

  Widget _sortToggle() {
    return _D03Clay(
      color: _d03Darken(_d03Putty, 0.04),
      radius: 18,
      depth: 4,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _sortOpt('날짜별', byDate, () => setState(() => byDate = true)),
          _sortOpt('유형별', !byDate, () => setState(() => byDate = false)),
        ],
      ),
    );
  }

  Widget _sortOpt(String t, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: sel
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_d03Lighten(_d03Clay, 0.08), _d03Clay],
                )
              : null,
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _d03Darken(_d03Clay, 0.16),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(t,
            style: _d03Type(
                size: 12.5,
                color: sel ? Colors.white : _d03Occ,
                weight: FontWeight.w900)),
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: _D03Clay(
          color: sel ? _d03Butter : _d03Wall,
          radius: 16,
          depth: sel ? 5 : 3,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label,
              style: _d03Type(
                  size: 13,
                  color: _d03Ink,
                  weight: sel ? FontWeight.w900 : FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _frame(Doodle d, Color frameColor) {
    return Column(
      children: [
        // hanging nail
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _d03Darken(_d03Putty, 0.14),
            boxShadow: [
              BoxShadow(
                color: _d03Occ.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _D03Clay(
            color: frameColor,
            radius: 22,
            depth: 8,
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // the "photo"
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: d.swatch,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _dot(Icon(d.type.icon,
                              size: 14, color: Colors.white)),
                        ),
                        if (d.liked)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _dot(const Icon(Icons.favorite,
                                size: 14, color: Color(0xFFFF5A7A))),
                          ),
                        if (d.mode == SendMode.disappearing)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _dot(const Icon(Icons.timer_rounded,
                                size: 13, color: Colors.white)),
                          ),
                        Center(
                          child: Text(d.emoji,
                              style: const TextStyle(fontSize: 44)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d03Type(size: 14, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${d.author} · ${d.at.month}/${d.at.day}',
                    style: _d03Type(
                        size: 11.5,
                        color: _d03Occ,
                        weight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Widget child) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.22),
        ),
        child: child,
      );
}
