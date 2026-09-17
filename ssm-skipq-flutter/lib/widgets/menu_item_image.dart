import 'package:flutter/material.dart';

import '../config/menu_assets.dart';
import '../config/theme.dart';
import '../models/menu.dart';

class MenuItemImage extends StatelessWidget {
  const MenuItemImage({
    super.key,
    required this.item,
    this.width = 88,
    this.height = 88,
    this.borderRadius = 12,
  });

  final MenuItem item;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final localAsset = MenuAssets.localAssetFor(item);
    final networkUrl = item.imageUrl.trim();

    return Semantics(
      image: true,
      label: '${item.name} image',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          color: AppTheme.bgSubtle,
          child: networkUrl.isNotEmpty && localAsset != null
              ? FadeInImage(
                  placeholder: AssetImage(localAsset),
                  image: NetworkImage(networkUrl),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => _buildFallback(localAsset),
                )
              : networkUrl.isNotEmpty
                  ? Image.network(
                      networkUrl,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _placeholder(showProgress: true);
                      },
                      errorBuilder: (_, __, ___) => _buildFallback(localAsset),
                    )
                  : _buildFallback(localAsset),
        ),
      ),
    );
  }

  Widget _buildFallback(String? localAsset) {
    if (localAsset != null) {
      return Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool showProgress = false}) {
    return Center(
      child: showProgress
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.restaurant_menu,
              color: AppTheme.textMuted,
              size: width * 0.34,
            ),
    );
  }
}
