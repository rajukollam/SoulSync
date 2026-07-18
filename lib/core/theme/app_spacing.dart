import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing
  static const double xs = 6;
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 30;
  static const double xl = 40;
  static const double xxl = 60;

  // Border Radius
  static const double radiusSmall = 16;
  static const double radiusMedium = 24;
  static const double radiusLarge = 32;

  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // Common Horizontal Padding
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: lg,
  );

  // Common Vertical Padding
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(
    vertical: md,
  );

  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  // Large Card Padding
  static const EdgeInsets largeCardPadding = EdgeInsets.all(lg);

  // Small Card Padding
  static const EdgeInsets smallCardPadding = EdgeInsets.all(sm);
}