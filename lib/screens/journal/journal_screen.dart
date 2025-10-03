import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // Données factices pour le carnet de voyage
  final List<Map<String, dynamic>> _journalEntries = [
    {
      'id': '1',
      'title': 'Arrivée à Paris',
      'content': 'Premier jour à Paris ! L\'ambiance est magique, nous avons pris un café près de Notre-Dame.',
      'date': DateTime(2024, 6, 15, 14, 30),
      'author': 'Marie',
      'type': 'text',
      'location': 'Paris, France',
      'mood': 'excited',
      'photos': ['photo1.jpg', 'photo2.jpg'],
      'likes': 5,
      'comments': 2,
    },
    {
      'id': '2',
      'title': 'Tour Eiffel au coucher du soleil',
      'content': 'Vue incroyable depuis le Trocadéro ! Les photos ne rendent pas justice à la beauté du moment.',
      'date': DateTime(2024, 6, 15, 19, 45),
      'author': 'Pierre',
      'type': 'photo',
      'location': 'Tour Eiffel, Paris',
      'mood': 'amazed',
      'photos': ['eiffel1.jpg', 'eiffel2.jpg', 'eiffel3.jpg'],
      'likes': 8,
      'comments': 3,
    },
    {
      'id': '3',
      'title': 'Dégustation de macarons',
      'content': 'Pause gourmande chez Pierre Hermé. Les saveurs sont exceptionnelles !',
      'date': DateTime(2024, 6, 16, 11, 15),
      'author': 'Julie',
      'type': 'food',
      'location': 'Champs-Élysées, Paris',
      'mood': 'happy',
      'photos': ['macarons.jpg'],
      'likes': 6,
      'comments': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Voyage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchEntries(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportJournal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques du voyage
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.secondaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.book,
                    label: 'Entrées',
                    value: '${_journalEntries.length}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.photo_camera,
                    label: 'Photos',
                    value: '${_getTotalPhotos()}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.favorite,
                    label: 'Likes',
                    value: '${_getTotalLikes()}',
                  ),
                ),
              ],
            ),
          ),

          // Timeline des entrées
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _journalEntries.length,
              itemBuilder: (context, index) {
                final entry = _journalEntries[index];
                return _buildJournalEntry(entry, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "journal_fab",
        onPressed: () => _addJournalEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle entrée'),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildJournalEntry(Map<String, dynamic> entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry['mood']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getEntryTypeIcon(entry['type']),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (index < _journalEntries.length - 1)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Entry content
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Par ${entry['author']} • ${_formatDateTime(entry['date'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _getMoodIcon(entry['mood']),
                          color: _getMoodColor(entry['mood']),
                          size: 24,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry['location'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Content
                    Text(
                      entry['content'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Photos preview
                    if (entry['photos'].isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry['photos'].length,
                          itemBuilder: (context, photoIndex) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_outline),
                          onPressed: () => _likeEntry(entry['id']),
                        ),
                        Text('${entry['likes']}'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () => _showComments(entry),
                        ),
                        Text('${entry['comments']}'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareEntry(entry),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'excited':
        return Colors.orange;
      case 'happy':
        return Colors.green;
      case 'amazed':
        return Colors.purple;
      case 'relaxed':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'excited':
        return Icons.sentiment_very_satisfied;
      case 'happy':
        return Icons.sentiment_satisfied;
      case 'amazed':
        return Icons.sentiment_very_satisfied;
      case 'relaxed':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  IconData _getEntryTypeIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.photo_camera;
      case 'food':
        return Icons.restaurant;
      case 'activity':
        return Icons.local_activity;
      default:
        return Icons.edit;
    }
  }

  int _getTotalPhotos() {
    return _journalEntries.fold(0, (sum, entry) => sum + (entry['photos'] as List).length);
  }

  int _getTotalLikes() {
    return _journalEntries.fold(0, (sum, entry) => sum + (entry['likes'] as int));
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    
    return '${date.day} ${months[date.month - 1]} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _addJournalEntry() {
    // TODO: Navigator vers écran d'ajout d'entrée
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajout d\'entrée de journal à implémenter'),
      ),
    );
  }

  void _likeEntry(String entryId) {
    setState(() {
      final entry = _journalEntries.firstWhere((e) => e['id'] == entryId);
      entry['likes']++;
    });
  }

  void _showComments(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaires - ${entry['title']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Text(
                  'Aucun commentaire pour le moment',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareEntry(Map<String, dynamic> entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de "${entry['title']}"'),
      ),
    );
  }

  void _searchEntries() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recherche dans le journal à implémenter'),
      ),
    );
  }

  void _exportJournal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter le carnet'),
        content: const Text('Choisissez le format d\'export :'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export PDF en cours...'),
                ),
              );
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export Album photo en cours...'),
                ),
              );
            },
            child: const Text('Album'),
          ),
        ],
      ),
    );
  }
}