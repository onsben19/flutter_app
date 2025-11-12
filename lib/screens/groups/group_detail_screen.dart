import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GroupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Afficher le menu d'options
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Détails du groupe\n(À implémenter)',
          textAlign: TextAlign.center,
          style: AppTheme.headingMedium,
        ),
      ),
    );
  }
}