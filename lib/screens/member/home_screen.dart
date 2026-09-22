import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/product_card.dart';
import 'notifications_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final products = context.watch<ProductProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 42),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                NetworkImageBox(
                                  url: settings.logoUrl,
                                  width: 52,
                                  height: 52,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        settings.shopName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.circle,
                                              size: 10,
                                              color: settings.isOpen
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            settings.isOpen ? 'Open now' : 'Closed',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                  );
                                },
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '2', 
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: AppTheme.primary.withValues(alpha: 0.7)),
                              const SizedBox(width: 12),
                              Text('Search products...',
                                  style:
                                      TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (products.offers.isNotEmpty)
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.offers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final offer = products.offers[i];
                              return Container(
                                width: 260,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primary,
                                      AppTheme.primaryDark
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      offer.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (offer.subtitle.isNotEmpty)
                                      Text(
                                        offer.subtitle,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      if (products.offers.isNotEmpty)
                        const SizedBox(height: 16),
                      if (products.categories.isNotEmpty) ...[
                        const Text('Categories',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: products.categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final cat = products.categories[i];
                              return InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductListScreen(
                                        categoryId: cat.id,
                                        categoryName: cat.name),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppTheme.primary
                                          .withValues(alpha: 0.1),
                                      child: cat.imageUrl.isNotEmpty
                                          ? ClipOval(
                                              child: NetworkImageBox(
                                                  url: cat.imageUrl,
                                                  width: 52,
                                                  height: 52),
                                            )
                                          : const Icon(Icons.category,
                                              color: AppTheme.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 64,
                                      child: Text(
                                        cat.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (products.featuredProducts.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text('Featured Products',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) =>
                          ProductCard(product: products.featuredProducts[i]),
                      childCount: products.featuredProducts.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Text('Recently Added',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (products.recentProducts.isEmpty && !products.loading)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products yet',
                    subtitle: 'Products added by the shop will appear here',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) =>
                          ProductCard(product: products.recentProducts[i]),
                      childCount: products.recentProducts.length,
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
