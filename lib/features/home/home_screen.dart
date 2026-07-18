import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../chat/chat_list_screen.dart';
import '../memories/memories_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/floating_nav_bar.dart';
import 'widgets/music_card.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/quote_card.dart';
import 'widgets/relationship_card.dart';
import 'widgets/stats_section.dart';
import 'widgets/welcome_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  int selectedIndex = 0;

  late final List<Widget> pages = [
    const HomePage(),
    const ChatListScreen(),
    const MemoriesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('SoulSync ❤️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: FloatingNavBar(
        currentIndex: selectedIndex,
        onTap: (i) {
          setState(() {
            selectedIndex = i;
          });
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.background,
      ),
      child: const SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeHeader(),
              SizedBox(height: AppSpacing.lg),
              QuickActionsCard(),
              SizedBox(height: AppSpacing.lg),
              RelationshipCard(),
              SizedBox(height: AppSpacing.lg),
              StatsSection(),
              SizedBox(height: AppSpacing.lg),
              QuoteCard(),
              SizedBox(height: AppSpacing.lg),
              MusicCard(),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}