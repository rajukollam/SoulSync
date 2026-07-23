import 'package:flutter/material.dart';
import 'package:couple_app/core/app/app_lifecycle_manager.dart';
import '../../services/auth_service.dart';
import '../chat/chat_list_screen.dart';
import '../chat/search_users_screen.dart';
import '../status/status_screen.dart';
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

  AppLifecycleManager? _lifecycleManager;

  int selectedIndex = 0;

  late final List<Widget> pages = [
    const HomePage(),
   ChatListScreen(),
    const StatusScreen(),
     ProfileScreen(),
  ];
  @override
void initState() {
  super.initState();

  print("🏠 HomeScreen initState");

  final user = _authService.currentUser;

  print("👤 Current user: ${user?.uid}");

  if (user != null) {
    _lifecycleManager = AppLifecycleManager(
      uid: user.uid,
    );

    print("🚀 Starting lifecycle manager");

    _lifecycleManager!.start();
  }
}

@override
void dispose() {
  _lifecycleManager?.stop();
  super.dispose();
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
     appBar: AppBar(
  leading: selectedIndex == 0
      ? null
      : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              selectedIndex = 0;
            });
          },
        ),
        title: const Text('SoulSync ❤️'),
        actions: [
  if (selectedIndex == 1)
    IconButton(
      icon: const Icon(Icons.person_add_alt_1),
      tooltip: 'Connect',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchUsersScreen(),
          ),
        );
      },
    ),

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
    return SafeArea(
  top: false,
  child: Container(
    decoration: const BoxDecoration(
      gradient: AppGradients.background,
    ),
    child: const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        kToolbarHeight + 16,
        AppSpacing.md,
        100,
      ),
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