import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/app_state.dart';

/// Bottom-tab shell.
///
/// The "My practice" tab is revealed by the server-issued role, never by a
/// client-side flag (PROMPT.md section 5).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isDoctor = context.watch<AppState>().session.isDoctor;

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: s.tabHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.medical_services_outlined),
        selectedIcon: const Icon(Icons.medical_services),
        label: s.tabServices,
      ),
      if (isDoctor)
        NavigationDestination(
          icon: const Icon(Icons.event_available_outlined),
          selectedIcon: const Icon(Icons.event_available),
          label: s.tabPractice,
        )
      else
        NavigationDestination(
          icon: const Icon(Icons.folder_shared_outlined),
          selectedIcon: const Icon(Icons.folder_shared),
          label: s.tabFile,
        ),
      NavigationDestination(
        icon: const Icon(Icons.more_horiz),
        label: s.tabMore,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
