import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../screens/member/product_details_screen.dart';
import '../../widgets/network_image_box.dart';
import 'notifications_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'all_categories_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final products = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: _HomeHeader(
              shopName: settings.shopName,
              logoUrl: settings.logoUrl,
              isOpen: settings.isOpen,
              userName: userName,
            ),
          ),



          // ── Fresh Banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8DE889), Color(0xFF4ADE80)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '>',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Fresh & Healthy\nEveryday',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 60),
                  ],
                ),
              ),
            ),
          ),


          // ── Categories ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Shop by Category',
                    showSeeAll: true,
                    onTapSeeAll: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllCategoriesScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.categories.length > 0 ? products.categories.length : 4,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        if (products.categories.length > 0) {
                          final cat = products.categories[i];
                          return _CategoryChip(
                            name: cat.name,
                            imageUrl: cat.imageUrl,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductListScreen(
                                  categoryId: cat.id,
                                  categoryName: cat.name,
                                ),
                              ),
                            ),
                          );
                        } else {
                          final mocks = [
                            {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded},
                            {'name': 'Snacks', 'icon': Icons.cookie_rounded},
                            {'name': 'Beverages', 'icon': Icons.local_drink_rounded},
                            {'name': 'Household', 'icon': Icons.cleaning_services_rounded},
                          ];
                          final mock = mocks[i];
                          return _CategoryChip(
                            name: mock['name'] as String,
                            imageUrl: '',
                            mockIcon: mock['icon'] as IconData,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CategoriesScreen()),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Popular Products ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              child: _SectionHeader(
                title: 'Popular Products',
                showSeeAll: true,
                onTapSeeAll: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen(categoryId: '', categoryName: 'Popular Products')),
                ),
              ),
            ),
          ),

          if (products.loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (products.recentProducts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No products yet',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    Text('Products added by the shop will appear here',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ProductGridCard(
                    product: products.recentProducts[i],
                  ),
                  childCount: products.recentProducts.length > 3 ? 3 : products.recentProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String shopName;
  final String logoUrl;
  final bool isOpen;
  final String userName;

  const _HomeHeader({
    required this.shopName,
    required this.logoUrl,
    required this.isOpen,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: Logo + Shop name + Notification
              Row(
                children: [
                  // Logo
                  if (logoUrl.isNotEmpty)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: NetworkImageBox(
                            url: logoUrl, width: 40, height: 40),
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: Colors.white, size: 20),
                    ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFF34D399)
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOpen ? 'Open now' : 'Closed',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback? onTapSeeAll;

  const _SectionHeader({required this.title, required this.showSeeAll, this.onTapSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        if (showSeeAll)
          GestureDetector(
            onTap: onTapSeeAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF10B981), // Green color matching image
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Offer Banner
// ──────────────────────────────────────────────

class _OfferBanner extends StatelessWidget {
  final dynamic offer;

  const _OfferBanner({required this.offer});

  static const List<List<Color>> _gradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFEF4444), Color(0xFFF97316)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = offer.title.hashCode.abs() % _gradients.length;
    final colors = _gradients[idx];

    return Container(
      width: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SPECIAL OFFER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                offer.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              if (offer.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  offer.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Category Chip
// ──────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final IconData? mockIcon;

  const _CategoryChip({
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.mockIcon,
  });

  static const List<Color> _colors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[name.hashCode.abs() % _colors.length];
    
    // Total width roughly fits 4 items per standard phone screen width
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(2), // slight padding for inner image
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: (imageUrl != '')
                ? ClipOval(
                    child: NetworkImageBox(
                      url: imageUrl, 
                      width: 68, 
                      height: 68,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(mockIcon ?? Icons.category_rounded, color: color, size: 32),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 76,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B), // Darker text for professional look
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Featured Product Card (Horizontal Scroll)
// ──────────────────────────────────────────────

class _FeaturedProductCard extends StatelessWidget {
  final Product product;

  const _FeaturedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        width: 115,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: const Color(0xFFF0F4FF),
                child: NetworkImageBox(
                  url: product.imageUrl,
                  width: double.infinity,
                  height: 90,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (product.unit.isNotEmpty)
                    Text(
                      product.unit,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatMoney(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      _AddBtn(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Product Grid Card
// ──────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final Product product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    color: const Color(0xFFF0F4FF),
                    child: NetworkImageBox(
                      url: product.imageUrl,
                      width: double.infinity,
                      height: 80,
                    ),
                  ),
                ),
                if (!product.inStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.2,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (product.unit.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.unit,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            formatMoney(product.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF1E3A8A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.inStock) ...[
                          const SizedBox(width: 4),
                          _AddBtn(product: product),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Add to Cart Button (inline small)
// ──────────────────────────────────────────────

class _AddBtn extends StatelessWidget {
  final Product product;
  const _AddBtn({required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyOf(product.id);

    if (qty == 0) {
      return GestureDetector(
        onTap: () => context.read<CartProvider>().add(product),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      );
    }

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.read<CartProvider>().decrement(product),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () => context.read<CartProvider>().add(product),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
