import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/shop_item.dart';
import '../../providers/pet_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/token_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopItemType _selectedType = ShopItemType.potion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final tokens = context.watch<TokenProvider>().tokens;
    final items = shop.catalog
        .where((item) => item.type == _selectedType)
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FEFF), Color(0xFFE4F4FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ZENZOO SHOP', style: AppTextStyles.title),
                        Text('Focus rewards only', style: AppTextStyles.muted),
                      ],
                    ),
                    const Spacer(),
                    _TokenChip(tokens: tokens),
                  ],
                ),
                const SizedBox(height: 18),
                _Tabs(
                  selectedType: _selectedType,
                  onSelected: (type) => setState(() => _selectedType = type),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(switch (_selectedType) {
                      ShopItemType.potion => '🧪 Potions',
                      ShopItemType.food => '🍎 Food',
                      ShopItemType.companion => '🦊 Companions',
                    }, style: AppTextStyles.title),
                    const Expanded(child: Divider(indent: 12, endIndent: 12)),
                    Text('${items.length} items', style: AppTextStyles.muted),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                    itemBuilder: (context, index) {
                      return _ShopItemCard(item: items[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text('$tokens ⚡', style: AppTextStyles.label),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selectedType, required this.onSelected});

  final ShopItemType selectedType;
  final ValueChanged<ShopItemType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _TabButton(
            label: '🧪 Potions',
            selected: selectedType == ShopItemType.potion,
            onTap: () => onSelected(ShopItemType.potion),
          ),
          _TabButton(
            label: '🍎 Food',
            selected: selectedType == ShopItemType.food,
            onTap: () => onSelected(ShopItemType.food),
          ),
          _TabButton(
            label: '🦊 Pets',
            selected: selectedType == ShopItemType.companion,
            onTap: () => onSelected(ShopItemType.companion),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primaryBlue
              : AppColors.surfaceLight,
          foregroundColor: selected ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final owned = shop.isOwned(item.id);
    final quantity = shop.quantityFor(item.id);
    final canBuy = !item.isCompanion || !owned;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (item.isHot)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'HOT',
                  style: AppTextStyles.muted.copyWith(color: Colors.white),
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShopItemVisual(item: item),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                item.isCompanion
                    ? item.companionBonus
                    : '+${item.effectValue} ${item.effectType.name}',
                style: AppTextStyles.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('${item.priceTokens} ⚡', style: AppTextStyles.label),
              if (!item.isCompanion && quantity > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Owned: x$quantity',
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canBuy ? () => _buy(context, item) : null,
                  child: Text(item.isCompanion && owned ? 'Owned' : 'Buy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, ShopItem item) async {
    try {
      final success = await context.read<ShopProvider>().buy(
        item: item,
        tokens: context.read<TokenProvider>(),
        pet: context.read<PetProvider>(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? item.isCompanion
                      ? '${item.name} joined your habitat!'
                      : '${item.name} added to inventory!'
                : 'Not enough tokens.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ShopItemVisual extends StatelessWidget {
  const _ShopItemVisual({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.companionAssetPath;
    if (assetPath == null) {
      return Text(item.emoji, style: const TextStyle(fontSize: 42));
    }

    return SizedBox(
      height: 58,
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
