import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_navigation.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({super.key, required this.body});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/campaigns')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0; // default to requests
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/app');
        break;
      case 1:
        context.go('/campaigns');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: body,
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
