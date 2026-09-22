import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/formatters.dart';
import '../models/product.dart';
import '../screens/member/product_details_screen.dart';
import 'add_to_cart_button.dart';
import 'network_image_box.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: NetworkImageBox(
                    url: product.imageUrl,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mandali(fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
              ),
              if (product.unit.isNotEmpty)
                Text(
                  product.unit,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(product.price),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  AddToCartButton(product: product),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
