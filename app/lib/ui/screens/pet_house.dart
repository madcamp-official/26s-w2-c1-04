// Memory Pager — Pet house / 집 꾸미기 (P2 / PT-3, full-screen push target).
//
// A room you arrange. Tap a room-category item (furniture / background / prop)
// to place it; drag it to move; tap the close button to take it out. Every move
// writes through `PATCH /pets/{pet_id}/items/{item_id}` with
// `{is_equipped, pos_x, pos_y}`.
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
import '../pet_view.dart';
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
                      style: cpSans(size: 12, color: cpEuc)),
                ],
                const SizedBox(height: 18),
                CpEyebrow('소품 · 가구', size: 9),
                const SizedBox(height: 12),
                SizedBox(height: 92, child: _trayRow()),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: cpSans(size: 11, color: cpInkA(0.4)),
                    children: [
                      const TextSpan(text: '탭해서 놓고, 끌어서 옮기고, '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.close,
                            size: 12, color: cpInkA(0.4)),
                      ),
                      const TextSpan(text: ' 로 치워요'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
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
                    PetView(
                      speciesId: appState.petSpecies,
                      size: 104,
                      expression:
                          expressionForActivity(appState.currentActivity),
                    ),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: on ? cpEucA(0.10) : cpPrint,
              borderRadius: BorderRadius.circular(cpRadiusSmall),
              border: Border.all(
                color: on ? cpEucA(0.5) : cpInkA(0.08),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: on ? 0.4 : 1,
                  child: Icon(_categoryIcon(it.category),
                      size: 24, color: on ? cpEuc : cpInkA(0.7)),
                ),
                const SizedBox(height: 8),
                Text(it.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 10, color: cpInkA(0.6))),
                const SizedBox(height: 4),
                on
                    ? Text('놓음',
                        style: cpSans(
                            size: 9,
                            color: cpEuc,
                            weight: FontWeight.w600,
                            spacing: 0.3))
                    : _priceTag(it.priceCoins),
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
                child: Icon(_categoryIcon(widget.item.category),
                    size: 30, color: cpInkA(0.75)),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cpPrint,
                      shape: BoxShape.circle,
                      border: Border.all(color: cpInkA(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: cpInkA(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, size: 12, color: cpInkA(0.55)),
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

/// A Material OUTLINED line icon standing in for an item category (never emoji).
/// Only the room categories (furniture / background / prop) actually render here;
/// the worn categories are mapped too so the switch stays exhaustive.
IconData _categoryIcon(ItemCategory c) => switch (c) {
      ItemCategory.clothes => Icons.checkroom,
      ItemCategory.hat => Icons.shopping_bag_outlined,
      ItemCategory.accessory => Icons.auto_awesome_outlined,
      ItemCategory.furniture => Icons.chair_outlined,
      ItemCategory.background => Icons.image_outlined,
      ItemCategory.prop => Icons.category_outlined,
    };

/// A tiny painted gold coin + price (no emoji). Uses the [cpGold] currency token.
Widget _priceTag(int coins) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration:
              const BoxDecoration(color: cpGold, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$coins',
            style: cpSans(size: 9, color: cpInkA(0.45), spacing: 0.3)),
      ],
    );
