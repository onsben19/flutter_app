import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../../widgets/app_user_icon_button.dart';

import '../../services/group_repository.dart';
import '../../services/session_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupRepo = GroupRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final session = await SessionService.getLoggedInUser();
      if (session == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final groups = await _groupRepo.getGroupsForUser(session.id);

      // Adapt repository models -> Map for GroupCard
      final now = DateTime.now();
      final adapted = <Map<String, dynamic>>[];

      for (final g in groups) {
        final groupId = g.id!;
        final memberCount = await _groupRepo.countMembers(groupId);
        final start = await _groupRepo.getStartDate(groupId);
        final end = await _groupRepo.getEndDate(groupId);
        final isActive = (end ?? start ?? now).isAfter(now);

        // NEW: fetch raw row to get image_path
        final raw = await _groupRepo.getRawGroupRow(groupId);
        final imagePath = (raw['image_path'] as String?) ?? '';

        adapted.add({
          'id': groupId.toString(),
          'name': g.name,
          'description': g.description ?? '',
          'memberCount': memberCount,
          'startDate': start ?? now,
          'endDate': end ?? now,
          'imageUrl': null,     // kept for compatibility if you ever use URLs
          'imagePath': imagePath, // ⬅️ used by GroupCard
          'isActive': isActive,
        });
      }

      if (!mounted) return;
      setState(() => _groups = adapted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onCreate() async {
    final createdId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    );
    if (createdId != null) {
      await _loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

// ...
    appBar: AppBar(
    leading: const AppUserIconButton(), // 👈 same look as right-side icons
    title: const Text('Mes Groupes'),
    actions: [
    IconButton(
    icon: const Icon(Icons.search),
    onPressed: () {},
    ),
    IconButton(
    icon: const Icon(Icons.notifications_outlined),
    onPressed: () {},
    ),
    ],
    ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadGroups,
        child: _groups.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _groups.length + 1, // +1 pour la carte "Créer"
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCreateGroupCard();
            }
            final group = _groups[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GroupCard(
                group: group,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(group: group),
                    ),
                  );
                  // Optionally refresh after returning from detail
                  await _loadGroups();
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "groups_fab",
        onPressed: _onCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau groupe'),
      ),
    );
  }

  Widget _buildCreateGroupCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          onTap: _onCreate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créer un nouveau groupe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Invitez vos amis à planifier votre prochain voyage',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondaryColor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.group_outlined, size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text('Aucun groupe de voyage', style: AppTheme.headingMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Créez votre premier groupe pour commencer à planifier un voyage avec vos amis',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Créer un groupe'),
            ),
          ],
        ),
      ),
    );
  }
}
