// Memory Pager — Pet house / 집 꾸미기 (P2 / PT-3, full-screen push target).
//
// A room you arrange. Tap a room-category item (furniture / background / prop)
// to place it; drag it to move; tap ✕ to take it out. Every move writes through
// `PATCH /pets/{pet_id}/items/{item_id}` with `{is_equipped, pos_x, pos_y}`.
//
// Contract gap worth naming: `GET /groups/{id}/pet` returns `equipped_items`
// WITHOUT `pos_x`/`pos_y` (API.md §5), even though the column exists in the ERD.
// So positions are written but not readable back. We keep them in screen state
// for this session and lay unseen items out deterministically — we never invent
// a "saved" position we cannot actually read.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

/// Categories that live in the room (the rest are worn on the pet).
const Set<ItemCategory> _roomCategories = <ItemCategory>{
  ItemCategory.furniture,
  ItemCategory.background,
  ItemCategory.prop,
};

class PetHouseScreen extends StatefulWidget {
  const PetHouseScreen({super.key});

  @override
  State<PetHouseScreen> createState() => _PetHouseScreenState();
}

class _PetHouseScreenState extends State<PetHouseScreen> {
  /// itemId -> normalized position inside the room (0..1).
  final Map<String, Offset> _pos = <String, Offset>{};

  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      await appState.loadItems();
      await appState.refreshPet();
    } catch (_) {
      if (mounted) setState(() => _error = '불러오지 못했어요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Item> get _tray =>
      appState.items.where((i) => _roomCategories.contains(i.category)).toList();

  List<EquippedItem> get _placed => (appState.pet?.equippedItems ?? [])
      .where((e) => _roomCategories.contains(e.category))
      .toList();

  /// Deterministic slot for an item we've never positioned (no Random).
  Offset _slotFor(String itemId, int index) {
    return _pos[itemId] ??= Offset(
      0.22 + (index % 3) * 0.28,
      0.30 + ((index ~/ 3) % 3) * 0.22,
    );
  }

  Future<void> _write(String itemId,
      {required bool equipped, Offset? at}) async {
    final p = appState.pet;
    if (p == null) return;
    setState(() => _error = null);
    try {
      await appState.repo.updatePetItem(
        p.id,
        itemId,
        isEquipped: equipped,
        posX: at == null ? null : (at.dx * 100).round(),
        posY: at == null ? null : (at.dy * 100).round(),
      );
      await appState.refreshPet();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.status == 404 || e.status == 422
          ? '먼저 스토어에서 구매해 주세요'
          : e.error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '반영하지 못했어요');
    }
  }

  Future<void> _place(Item item) async {
    final already = _placed.any((e) => e.itemId == item.id);
    if (already) return;
    final at = _slotFor(item.id, _placed.length);
    await _write(item.id, equipped: true, at: at);
  }

  Future<void> _remove(String itemId) async {
    await _write(itemId, equipped: false);
    if (mounted) setState(() => _pos.remove(itemId));
  }

  Future<void> _moved(String itemId, Offset at) async {
    setState(() => _pos[itemId] = at);
    await _write(itemId, equipped: true, at: at);
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '집 꾸미기',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (_busy && appState.items.isEmpty) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _room()),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: cpSans(size: 12, color: const Color(0xFFB5654A))),
                ],
                const SizedBox(height: 18),
                CpEyebrow('소품 · 가구', size: 9),
                const SizedBox(height: 12),
                SizedBox(height: 92, child: _trayRow()),
                const SizedBox(height: 10),
                Text('탭해서 놓고, 끌어서 옮기고, ✕로 치워요',
                    textAlign: TextAlign.center,
                    style: cpSans(size: 11, color: cpInkA(0.4))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _room() {
    final placed = _placed;
    final pet = appState.pet;
    return CpMatted(
      mat: 14,
      inset: 0,
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              // The pet always sits in its room.
              Align(
                alignment: const Alignment(0, 0.55),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐣', style: const TextStyle(fontSize: 54)),
                    const SizedBox(height: 6),
                    Text(pet?.name ?? '',
                        style: cpSans(size: 11, color: cpInkA(0.45))),
                  ],
                ),
              ),
              if (placed.isEmpty)
                Center(
                  child: Text('아직 놓은 물건이 없어요',
                      style: cpSans(size: 12, color: cpInkA(0.35))),
                ),
              for (int i = 0; i < placed.length; i++)
                _PlacedItem(
                  key: ValueKey(placed[i].itemId),
                  item: placed[i],
                  pos: _slotFor(placed[i].itemId, i),
                  bounds: size,
                  onMoved: (at) => _moved(placed[i].itemId, at),
                  onRemove: () => _remove(placed[i].itemId),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _trayRow() {
    final tray = _tray;
    if (tray.isEmpty) {
      return const CpEmptyState(
          icon: Icons.chair_outlined, text: '놓을 수 있는 물건이 없어요');
    }
    final placedIds = _placed.map((e) => e.itemId).toSet();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: tray.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final it = tray[i];
        final on = placedIds.contains(it.id);
        return GestureDetector(
          onTap: on ? null : () => _place(it),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: cpPrint,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: on ? cpEucA(0.55) : cpInkA(0.10),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: on ? 0.35 : 1,
                  child: Text(_glyph(it.category),
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 6),
                Text(it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 10, color: cpInkA(0.6))),
                const SizedBox(height: 3),
                Text(on ? '놓음' : '🪙 ${it.priceCoins}',
                    style: cpSans(
                        size: 9,
                        color: on ? cpEuc : cpInkA(0.45),
                        spacing: 0.4)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// A placed item — draggable inside the room
// ===========================================================================

class _PlacedItem extends StatefulWidget {
  const _PlacedItem({
    super.key,
    required this.item,
    required this.pos,
    required this.bounds,
    required this.onMoved,
    required this.onRemove,
  });

  final EquippedItem item;
  final Offset pos; // normalized 0..1
  final Size bounds;
  final ValueChanged<Offset> onMoved;
  final VoidCallback onRemove;

  @override
  State<_PlacedItem> createState() => _PlacedItemState();
}

class _PlacedItemState extends State<_PlacedItem> {
  late Offset _p = widget.pos;

  @override
  void didUpdateWidget(covariant _PlacedItem old) {
    super.didUpdateWidget(old);
    if (old.pos != widget.pos) _p = widget.pos;
  }

  @override
  Widget build(BuildContext context) {
    const box = 56.0;
    final left = (_p.dx * widget.bounds.width - box / 2)
        .clamp(0.0, (widget.bounds.width - box).clamp(0.0, double.infinity));
    final top = (_p.dy * widget.bounds.height - box / 2)
        .clamp(0.0, (widget.bounds.height - box).clamp(0.0, double.infinity));

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          setState(() {
            _p = Offset(
              (_p.dx + d.delta.dx / widget.bounds.width).clamp(0.0, 1.0),
              (_p.dy + d.delta.dy / widget.bounds.height).clamp(0.0, 1.0),
            );
          });
        },
        onPanEnd: (_) => widget.onMoved(_p),
        child: SizedBox(
          width: box,
          height: box,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(_glyph(widget.item.category),
                    style: const TextStyle(fontSize: 32)),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cpPrint,
                      shape: BoxShape.circle,
                      border: Border.all(color: cpInkA(0.2), width: 0.5),
                    ),
                    child: Text('✕',
                        style: cpSans(size: 9, color: cpInkA(0.6))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _glyph(ItemCategory c) => switch (c) {
      ItemCategory.clothes => '👕',
      ItemCategory.hat => '🎩',
      ItemCategory.accessory => '🎀',
      ItemCategory.furniture => '🪑',
      ItemCategory.background => '🖼️',
      ItemCategory.prop => '🧸',
    };
