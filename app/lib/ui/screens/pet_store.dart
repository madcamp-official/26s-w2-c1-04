// Memory Pager — Pet store (full-screen push target).
//
// The coin store and pet-customization surface. A category segment
// ([ItemCategory]) filters the catalog via `appState.loadItems(category:)`; the
// grid of store cards shows each item's category line icon, name, and price. Tapping
// a soft sheet to *buy* it (`appState.buyItem`, which surfaces a quiet "coins
// short" notice on a 422) or, once owned, to *equip / unequip* it
// (`appState.equipItem`, which toggles within its category on the backend).
//
// The header's [CpCoins] and the whole grid live under one ListenableBuilder so
// coins, equipped state, and inventory reflect the REST source of truth the
// instant `buyItem` / `equipItem` re-read the pet.
//
// Ownership honesty: the wire [Pet] exposes only *equipped* items, not the full
// inventory. So ownership is tracked as it is *observed* — an item is "known
// owned" only if it is currently equipped (from the server) or was purchased in
// this session. Nothing is guessed; unconfirmed items simply show "buy", and a
// re-buy is a harmless idempotent no-op on the backend.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

class PetStoreScreen extends StatefulWidget {
  const PetStoreScreen({super.key});

  @override
  State<PetStoreScreen> createState() => _PetStoreScreenState();
}

class _PetStoreScreenState extends State<PetStoreScreen> {
  // The category tabs. `null` is the leading "전체" (all) segment.
  static const List<ItemCategory?> _cats = <ItemCategory?>[
    null,
    ItemCategory.hat,
    ItemCategory.clothes,
    ItemCategory.prop,
    ItemCategory.accessory,
    ItemCategory.furniture,
    ItemCategory.background,
  ];

  ItemCategory? _category;
  bool _loading = true;

  /// Items observed to be owned — currently-equipped ids (from the pet) plus
  /// ids bought this session. Only ever grows; never fabricated.
  final Set<String> _known = <String>{};

  /// Guards out-of-order category loads (last tap wins).
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    // Kick off the first load without a synchronous setState (disallowed in
    // initState); `_fetch`'s setState lands after the first `await`.
    _fetch(null);
  }

  /// Change the selected category tab (safe outside initState).
  void _select(ItemCategory? cat) {
    setState(() {
      _category = cat;
      _loading = true;
    });
    _fetch(cat);
  }

  Future<void> _fetch(ItemCategory? cat) async {
    final seq = ++_seq;
    try {
      await appState.loadItems(category: cat);
    } catch (_) {
      // Keep whatever was last shown; the empty/grid state below stays honest.
    }
    if (!mounted || seq != _seq) return;
    setState(() => _loading = false);
  }

  void _openItem(Item item) {
    final equipped =
        appState.pet?.equippedItems.any((e) => e.itemId == item.id) ?? false;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ItemSheet(
        item: item,
        owned: _known.contains(item.id) || equipped,
        onOwned: (id) {
          if (!mounted) return;
          setState(() => _known.add(id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pet = appState.pet;
        // Absorb server-confirmed ownership (equipped ⊂ owned). Idempotent and
        // monotonic, so doing it in build is safe and needs no setState.
        if (pet != null) {
          for (final e in pet.equippedItems) {
            _known.add(e.itemId);
          }
        }

        return CpScaffold(
          title: '상점',
          leading: CpIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [CpCoins(pet?.coins ?? 0)],
          body: pet == null
              ? const Center(
                  child: CpEmptyState(
                    icon: Icons.storefront_outlined,
                    text: '펫이 없어요',
                  ),
                )
              : _buildBody(pet),
        );
      },
    );
  }

  Widget _buildBody(Pet pet) {
    final equipped = pet.equippedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        CpChipRow(
          children: [
            for (final c in _cats)
              CpFilterChip(
                label: c == null ? '전체' : _categoryLabel(c),
                selected: _category == c,
                onTap: () => _select(c),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _EquippedStrip(equipped: equipped, petName: pet.name),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: CpHair(opacity: 0.08),
        ),
        const SizedBox(height: 4),
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildGrid() {
    final items = appState.items;

    if (_loading && items.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: CpEmptyState(
          icon: Icons.inventory_2_outlined,
          text: '이 카테고리에는\n아직 아이템이 없어요',
        ),
      );
    }

    final equippedIds = <String>{
      for (final e in appState.pet?.equippedItems ?? const <EquippedItem>[])
        e.itemId,
    };

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.84,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final isEquipped = equippedIds.contains(item.id);
        final owned = isEquipped || _known.contains(item.id);
        return _StoreCard(
          item: item,
          equipped: isEquipped,
          owned: owned,
          onTap: () => _openItem(item),
        );
      },
    );
  }
}

// ===========================================================================
// Equipped summary strip — what the pet is wearing right now
// ===========================================================================

class _EquippedStrip extends StatelessWidget {
  const _EquippedStrip({required this.equipped, required this.petName});

  final List<EquippedItem> equipped;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CpEyebrow('$petName · 착용 중'),
        const SizedBox(height: 10),
        if (equipped.isEmpty)
          Text(
            '아직 아무것도 착용하지 않았어요',
            style: cpSans(size: 13, color: cpInkA(0.45)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in equipped) _wornPill(e),
            ],
          ),
      ],
    );
  }

  Widget _wornPill(EquippedItem e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: cpEucA(0.10),
        borderRadius: BorderRadius.circular(cpRadiusPill),
        border: Border.all(color: cpEucA(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_categoryIcon(e.category), size: 15, color: cpEuc),
          const SizedBox(width: 7),
          Text(
            _categoryLabel(e.category),
            style: cpSans(size: 11.5, color: cpInk, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Store card
// ===========================================================================

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.item,
    required this.equipped,
    required this.owned,
    required this.onTap,
  });

  final Item item;
  final bool equipped;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cpPrint,
          borderRadius: BorderRadius.circular(cpRadiusCard),
          border: Border.all(
            color: equipped ? cpEucA(0.5) : cpInkA(0.06),
            width: equipped ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cpInkA(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: equipped ? cpEucA(0.10) : cpDim,
                    borderRadius: BorderRadius.circular(cpRadiusSmall),
                  ),
                  child: Icon(
                    _categoryIcon(item.category),
                    size: 38,
                    color: equipped ? cpEuc : cpInkA(0.45),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cpSans(size: 13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _statusLine(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine() {
    if (equipped) {
      return Text(
        '착용 중',
        style: cpEyebrowStyle(color: cpEuc, size: 9.5),
      );
    }
    if (owned) {
      return Text(
        '보유',
        style: cpEyebrowStyle(color: cpInkA(0.5), size: 9.5),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.paid_outlined, size: 14, color: cpGold),
        const SizedBox(width: 6),
        Text(
          '${item.priceCoins}',
          style: cpSans(size: 12.5, weight: FontWeight.w600, spacing: 0.4),
        ),
      ],
    );
  }
}

// ===========================================================================
// Item sheet — buy / equip / unequip
// ===========================================================================

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({
    required this.item,
    required this.owned,
    required this.onOwned,
  });

  final Item item;

  /// Whether the item is already known-owned when the sheet opens.
  final bool owned;

  /// Called with the item id after a successful purchase so the grid updates.
  final ValueChanged<String> onOwned;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late bool _owned = widget.owned;
  bool _busy = false;
  String? _notice;

  Item get _item => widget.item;

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await appState.buyItem(_item.id);
      widget.onOwned(_item.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _owned = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // 422 unprocessable == coins short (see MockRepository.buyItem).
        _notice = (e.status == 422 || e.code == 'unprocessable')
            ? '코인이 부족해요'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = '구매하지 못했어요. 다시 시도해 주세요';
      });
    }
  }

  Future<void> _setEquipped(bool equip) async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      await appState.equipItem(_item.id, equip: equip);
      if (!mounted) return;
      setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = e.status == 404 ? '보유하지 않은 아이템이에요' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = '변경하지 못했어요. 다시 시도해 주세요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pet = appState.pet;
        final coins = pet?.coins ?? 0;
        final equipped =
            pet?.equippedItems.any((e) => e.itemId == _item.id) ?? false;
        final owned = equipped || _owned;
        final price = _item.priceCoins;
        final shortfall = price - coins;

        return Container(
          decoration: BoxDecoration(
            color: cpMist,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(cpRadiusCard),
            ),
            border: Border(top: BorderSide(color: cpInkA(0.08))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cpInkA(0.15),
                        borderRadius: BorderRadius.circular(cpRadiusPill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CpEyebrow(_categoryLabel(_item.category)),
                  const SizedBox(height: 8),
                  Text(
                    _item.name,
                    style: cpSans(size: 22, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  CpMatted(
                    mat: 20,
                    child: SizedBox(
                      height: 96,
                      child: Center(
                        child: Icon(
                          _categoryIcon(_item.category),
                          size: 46,
                          color: cpInkA(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _metaRow(owned: owned, equipped: equipped, price: price),
                  if (!owned && shortfall > 0) ...[
                    const SizedBox(height: 12),
                    _noticeBox('코인이 $shortfall 더 필요해요'),
                  ],
                  if (_notice != null) ...[
                    const SizedBox(height: 12),
                    _noticeBox(_notice!),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: _action(owned: owned, equipped: equipped),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metaRow({
    required bool owned,
    required bool equipped,
    required int price,
  }) {
    if (equipped) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: cpEuc),
          const SizedBox(width: 8),
          Text('지금 착용 중이에요',
              style: cpSans(size: 13, color: cpInk, weight: FontWeight.w500)),
        ],
      );
    }
    if (owned) {
      return Text('보유 중 · 착용할 수 있어요',
          style: cpSans(size: 13, color: cpInkA(0.6)));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CpEyebrow('가격'),
        const Spacer(),
        Icon(Icons.paid_outlined, size: 18, color: cpGold),
        const SizedBox(width: 8),
        Text('$price',
            style: cpSans(size: 20, weight: FontWeight.w600, spacing: 0.4)),
      ],
    );
  }

  Widget _action({required bool owned, required bool equipped}) {
    if (_busy) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
      );
    }
    if (equipped) {
      return CpPrimaryButton(
        label: '해제하기',
        filled: false,
        onTap: () => _setEquipped(false),
      );
    }
    if (owned) {
      return CpPrimaryButton(
        label: '착용하기',
        onTap: () => _setEquipped(true),
      );
    }
    return CpPrimaryButton(label: '구매하기', onTap: _buy);
  }

  Widget _noticeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cpEucA(0.10),
        borderRadius: BorderRadius.circular(cpRadiusSmall),
        border: Border.all(color: cpEucA(0.4)),
      ),
      child: Text(
        text,
        style: cpSans(size: 12.5, color: cpInk, weight: FontWeight.w500),
      ),
    );
  }
}

// ===========================================================================
// Category display helpers (labels/icons are UI copy, not wire data)
// ===========================================================================

String _categoryLabel(ItemCategory c) {
  switch (c) {
    case ItemCategory.hat:
      return '모자';
    case ItemCategory.clothes:
      return '옷';
    case ItemCategory.accessory:
      return '액세서리';
    case ItemCategory.furniture:
      return '가구';
    case ItemCategory.background:
      return '배경';
    case ItemCategory.prop:
      return '소품';
  }
}

/// A Material OUTLINED line icon standing in for each category — a vector
/// placeholder, never an emoji. The real per-item vectors land in a later step.
IconData _categoryIcon(ItemCategory c) {
  switch (c) {
    case ItemCategory.hat:
      return Icons.style_outlined;
    case ItemCategory.clothes:
      return Icons.checkroom;
    case ItemCategory.accessory:
      return Icons.diamond_outlined;
    case ItemCategory.furniture:
      return Icons.chair_outlined;
    case ItemCategory.background:
      return Icons.image_outlined;
    case ItemCategory.prop:
      return Icons.toys_outlined;
  }
}
