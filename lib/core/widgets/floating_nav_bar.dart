import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, "Home"),
    (Icons.chat_bubble_outline_rounded, "Chat"),
    (Icons.amp_stories_outlined, "Status"),
    (Icons.person_outline_rounded, "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final selected = index == currentIndex;
                  final item = _items[index];

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              scale: selected ? 1.15 : 1,
                              child: Icon(
                                item.$1,
                                color: selected
                                    ? AppColors.primary
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? AppColors.primary
                                    : Colors.white60,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}