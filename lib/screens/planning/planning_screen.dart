import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/suggestion_card.dart';
import 'add_suggestion_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Données factices pour les suggestions
  final List<Map<String, dynamic>> _suggestions = [
    {
      'id': '1',
      'title': 'Tour Eiffel',
      'description': 'Visite de la célèbre tour de Paris',
      'category': 'Monument',
      'duration': '2h',
      'cost': 25.0,
      'votes': 8,
      'totalMembers': 10,
      'suggestedBy': 'Marie',
      'imageUrl': 'https://example.com/tour-eiffel.jpg',
      'isVoted': true,
    },
    {
      'id': '2',
      'title': 'Louvre',
      'description': 'Musée d\'art et d\'histoire',
      'category': 'Musée',
      'duration': '4h',
      'cost': 17.0,
      'votes': 6,
      'totalMembers': 10,
      'suggestedBy': 'Pierre',
      'imageUrl': 'https://example.com/louvre.jpg',
      'isVoted': false,
    },
    {
      'id': '3',
      'title': 'Bateau-mouche',
      'description': 'Croisière sur la Seine',
      'category': 'Activité',
      'duration': '1h30',
      'cost': 15.0,
      'votes': 5,
      'totalMembers': 10,
      'suggestedBy': 'Julie',
      'imageUrl': 'https://example.com/bateau-mouche.jpg',
      'isVoted': true,
    },
  ];

  final List<Map<String, dynamic>> _itinerary = [
    {
      'day': 1,
      'date': DateTime(2024, 6, 15),
      'activities': [
        {
          'time': '09:00',
          'title': 'Tour Eiffel',
          'duration': '2h',
          'status': 'confirmed',
        },
        {
          'time': '14:00',
          'title': 'Bateau-mouche',
          'duration': '1h30',
          'status': 'confirmed',
        },
      ],
    },
    {
      'day': 2,
      'date': DateTime(2024, 6, 16),
      'activities': [
        {
          'time': '10:00',
          'title': 'Louvre',
          'duration': '4h',
          'status': 'pending',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.how_to_vote),
              text: 'Suggestions',
            ),
            Tab(
              icon: Icon(Icons.schedule),
              text: 'Itinéraire',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSuggestionsTab(),
          _buildItineraryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "planning_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSuggestionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Suggérer'),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Column(
      children: [
        // Statistiques des votes
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.how_to_vote,
                  label: 'Suggestions',
                  value: '${_suggestions.length}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Validées',
                  value: '${_suggestions.where((s) => s['votes'] >= 6).length}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.pending,
                  label: 'En attente',
                  value: '${_suggestions.where((s) => s['votes'] < 6).length}',
                ),
              ),
            ],
          ),
        ),

        // Liste des suggestions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SuggestionCard(
                  suggestion: suggestion,
                  onVote: () => _toggleVote(suggestion['id']),
                  onEdit: () => _editSuggestion(suggestion),
                  onDelete: () => _deleteSuggestion(suggestion['id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itinerary.length,
      itemBuilder: (context, index) {
        final day = _itinerary[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du jour
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'J${day['day']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jour ${day['day']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(day['date']),
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // TODO: Ajouter une activité
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Activités du jour
                ...day['activities'].map<Widget>((activity) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activity['status'] == 'confirmed'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activity['status'] == 'confirmed'
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              activity['time'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              activity['duration'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            activity['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          activity['status'] == 'confirmed'
                              ? Icons.check_circle
                              : Icons.pending,
                          color: activity['status'] == 'confirmed'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  void _toggleVote(String suggestionId) {
    setState(() {
      final suggestion = _suggestions.firstWhere((s) => s['id'] == suggestionId);
      if (suggestion['isVoted']) {
        suggestion['votes']--;
        suggestion['isVoted'] = false;
      } else {
        suggestion['votes']++;
        suggestion['isVoted'] = true;
      }
    });
  }

  void _editSuggestion(Map<String, dynamic> suggestion) {
    // TODO: Naviguer vers l'écran d'édition
  }

  void _deleteSuggestion(String suggestionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la suggestion'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette suggestion ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _suggestions.removeWhere((s) => s['id'] == suggestionId);
              });
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les suggestions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Monuments'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Musées'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Activités'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}