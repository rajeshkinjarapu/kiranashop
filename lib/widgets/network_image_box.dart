import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageBox extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
    );

    Widget child;
    
    if (url.isEmpty) {
      child = placeholder;
    } else if (url.startsWith('data:image/')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = Uri.parse('data:image/jpeg;base64,$base64Str').data!.contentAsBytes();
        child = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (e) {
        child = placeholder;
      }
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
