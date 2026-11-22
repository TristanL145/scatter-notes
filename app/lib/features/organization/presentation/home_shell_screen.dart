import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/router/app_router.dart';

/// Phase 1 root shell displaying seeded spaces and live note counts from the
/// local Drift database.
class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(bootstrapSpacesProvider);
    final spacesAsync = ref.watch(spacesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scatter Notes'),
        actions: [
          IconButton(
            tooltip: 'Search notes',
            onPressed: () => context.push(AppRoutes.search),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: bootstrapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to initialize spaces: $error')),
        data: (_) => spacesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Error loading spaces: $error')),
          data: (spaces) {
            if (spaces.isEmpty) {
              return const Center(child: Text('No spaces configured yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: spaces.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SpaceCard(space: spaces[index]),
            );
          },
        ),
      ),
    );
  }
}

class _SpaceCard extends ConsumerWidget {
  const _SpaceCard({required this.space});

  final Space space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesBySpaceProvider(space.id));
    final noteCountLabel = notesAsync.when(
      data: (notes) => notes.length == 1 ? '1 note' : '${notes.length} notes',
      loading: () => 'Loading notes...',
      error: (error, _) => 'Unavailable',
    );

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(child: Icon(_iconForName(space.icon))),
        title: Text(space.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(noteCountLabel),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school_outlined;
      case 'rocket_launch':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
