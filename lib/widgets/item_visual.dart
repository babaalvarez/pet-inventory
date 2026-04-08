import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ItemVisual extends StatelessWidget {
  const ItemVisual({
    super.key,
    required this.name,
    required this.representation,
    required this.displayColorValue,
    required this.displayShape,
    required this.imagePath,
    this.imageUrl,
    this.size = 52,
    this.borderRadius = 14,
    this.showFrame = true,
    this.showBackground = true,
  });

  final String name;
  final InventoryRepresentation representation;
  final int displayColorValue;
  final InventoryDisplayShape displayShape;
  final String imagePath;
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final bool showFrame;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final accent = Color(
      displayColorValue == 0
          ? defaultInventoryDisplayColorValue(name)
          : displayColorValue,
    );

    final content = representation == InventoryRepresentation.image
        ? _ImageVisual(accent: accent, imagePath: imagePath, imageUrl: imageUrl)
        : _ShapeVisual(
            name: name,
            color: accent,
            shape: displayShape,
            size: size,
            showBackground: showBackground,
          );

    if (showFrame) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: representation == InventoryRepresentation.image
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: content,
            )
          : content,
    );
  }
}

class _ImageVisual extends StatelessWidget {
  const _ImageVisual({
    required this.accent,
    required this.imagePath,
    required this.imageUrl,
  });

  final Color accent;
  final String imagePath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ImageFallback(accent: accent),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _ImageFallback(accent: accent),
      );
    }

    return _ImageFallback(accent: accent);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.88),
            accent.withValues(alpha: 0.58),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: Colors.white.withValues(alpha: 0.94),
        ),
      ),
    );
  }
}

class _ShapeVisual extends StatelessWidget {
  const _ShapeVisual({
    required this.name,
    required this.color,
    required this.shape,
    required this.size,
    required this.showBackground,
  });

  final String name;
  final Color color;
  final InventoryDisplayShape shape;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final glyph = Center(
      child: _ShapeGlyph(
        shape: shape,
        color: color,
        icon: _productIconForName(name),
        size: size,
      ),
    );

    if (!showBackground) {
      return glyph;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.3)],
        ),
      ),
      child: glyph,
    );
  }
}

class _ShapeGlyph extends StatelessWidget {
  const _ShapeGlyph({
    required this.shape,
    required this.color,
    required this.icon,
    required this.size,
  });

  final InventoryDisplayShape shape;
  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.42;
    switch (shape) {
      case InventoryDisplayShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: iconSize, color: Colors.white),
        );
      case InventoryDisplayShape.diamond:
        return Transform.rotate(
          angle: 0.78539816339,
          child: Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.78539816339,
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
            ),
          ),
        );
      case InventoryDisplayShape.capsule:
        return Container(
          width: size * 1.25,
          height: size * 0.68,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size),
          ),
          child: Icon(icon, size: iconSize, color: Colors.white),
        );
      case InventoryDisplayShape.roundedSquare:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, size: iconSize, color: Colors.white),
        );
    }
  }
}

IconData _productIconForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('food') || lower.contains('kibble')) {
    return Icons.pets;
  }
  if (lower.contains('treat') ||
      lower.contains('chew') ||
      lower.contains('bite')) {
    return Icons.cookie_outlined;
  }
  if (lower.contains('shampoo') || lower.contains('wipe')) {
    return Icons.soap_outlined;
  }
  if (lower.contains('carrier') || lower.contains('bag')) {
    return Icons.shopping_bag_outlined;
  }
  if (lower.contains('toy') ||
      lower.contains('feather') ||
      lower.contains('spring')) {
    return Icons.toys_outlined;
  }
  if (lower.contains('scoop') || lower.contains('litter')) {
    return Icons.cleaning_services_outlined;
  }
  return Icons.inventory_2_outlined;
}
