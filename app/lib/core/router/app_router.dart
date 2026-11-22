import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/organization/presentation/home_shell_screen.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String settings = '/settings';
}

/// Provides the root [GoRouter] instance for Scatter Notes.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchPlaceholderScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPlaceholderScreen(),
      ),
    ],
  );
});

/// Placeholder search screen wired in Phase 1; expanded with FTS5 UI in Phase 2.
class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Notes')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Offline full-text search (FTS5) and multi-facet filtering '
            '(Space, Class/Project, Topic, Label) will land in Phase 2.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Placeholder settings screen wired in Phase 1; expanded with nudge
/// intensity controls in Phase 3.
class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nudge intensity (Quiet / Balanced / Active), theme preferences, '
            'and local backup/export controls will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
