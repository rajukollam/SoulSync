import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Circular avatar with an optional WhatsApp-style status ring.
///
/// [hasStatus] draws a colored ring around the avatar to indicate there's an
/// active status to view; [seen] dims that ring to a plain color, matching
/// how chat apps distinguish unseen vs already-viewed updates.
class StatusAvatar extends StatelessWidget {
  final String imageUrl;
  final String label;
  final double radius;
  final bool hasStatus;
  final bool seen;

  const StatusAvatar({
    super.key,
    required this.imageUrl,
    required this.label,
    this.radius = 28,
    this.hasStatus = false,
    this.seen = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasStatus && !seen ? AppGradients.heart : null,
        color: hasStatus && seen ? AppColors.border : null,
        border: hasStatus ? null : Border.all(color: AppColors.border),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.surfaceLight,
          backgroundImage:
              imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty
              ? Text(
                  label.isNotEmpty ? label[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
