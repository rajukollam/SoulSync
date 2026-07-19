import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key});

  static const List<String> quotes = [
    "Love is not about counting days, it's about making the days count. ❤️",
    "Every love story is beautiful, but yours is waiting to be written. ✨",
    "Home is wherever we're together. 🏡",
    "The little moments become the biggest memories. 📸",
    "Forever starts with today's small moments. 💕",
  ];

  @override
  Widget build(BuildContext context) {
    final quote = quotes[Random().nextInt(quotes.length)];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                quote,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}