import 'package:flutter/material.dart';

class SearchUsersScreen extends StatelessWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Partner"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Search feature coming soon ❤️",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}