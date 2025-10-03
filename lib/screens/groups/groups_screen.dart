import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // Données factices pour les groupes
  final List<Map<String, dynamic>> _groups = [
    {
      'id': '1',
      'name': 'Voyage à Paris',
      'description': 'Week-end entre amis dans la capitale',
      'memberCount': 4,
      'startDate': DateTime(2024, 6, 15),
      'endDate': DateTime(2024, 6, 18),
      'imageUrl': 'https://example.com/paris.jpg',
      'isActive': true,
    },
    {
      'id': '2',
      'name': 'Road Trip Espagne',
      'description': 'Tour de l\'Espagne en voiture',
      'memberCount': 6,
      'startDate': DateTime(2024, 7, 20),
      'endDate': DateTime(2024, 8, 5),
      'imageUrl': 'https://example.com/spain.jpg',
      'isActive': false,
    },
    {
      'id': '3',
      'name': 'Ski à Chamonix',
      'description': 'Semaine de ski dans les Alpes',
      'memberCount': 8,
      'startDate': DateTime(2024, 2, 10),
      'endDate': DateTime(2024, 2, 17),
      'imageUrl': 'https://example.com/chamonix.jpg',
      'isActive': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implémenter la recherche
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Afficher les notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Rafraîchir la liste des groupes
          await Future.delayed(const Duration(seconds: 1));
        },
        child: _groups.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length + 1, // +1 pour le bouton d'ajout
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCreateGroupCard();
                  }
                  
                  final group = _groups[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GroupCard(
                      group: group,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailScreen(group: group),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "groups_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateGroupScreen(),
            ),
          );
        },
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );
          },
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
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
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
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondaryColor,
                  size: 16,
                ),
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
              child: const Icon(
                Icons.group_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun groupe de voyage',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Créez votre premier groupe pour commencer à planifier un voyage avec vos amis',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un groupe'),
            ),
          ],
        ),
      ),
    );
  }
}