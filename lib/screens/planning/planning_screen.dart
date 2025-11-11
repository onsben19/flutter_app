import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/suggestion_card.dart';
import '../../screens/planning/add_suggestion_screen.dart';
import '../../services/database_service.dart';
import '../../models/planification.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  List<Planification> _suggestions = [];
  bool _loading = true;

  List<Map<String, dynamic>> _itinerary = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestions();
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
            Tab(icon: Icon(Icons.how_to_vote), text: 'Suggestions'),
            Tab(icon: Icon(Icons.schedule), text: 'Itinéraire'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            tooltip: 'Générer Itinéraire',
            icon: const Icon(Icons.auto_mode),
            onPressed: () => _generateItinerary(),
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
        heroTag: 'planning_fab',
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSuggestionScreen()),
          );
          if (created == true) {
            await _loadSuggestions();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Suggérer'),
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Column(
      children: [
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
                  value: _loading ? '...' : '${_suggestions.length}',
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.primaryColor.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Validées',
                  value: _loading
                      ? '...'
                      : '${_suggestions.where((s) {
                          final total = s.totalMembers;
                          final needed = (total * 0.6).ceil();
                          return s.votes >= (needed == 0 ? 6 : needed);
                        }).length}',
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.primaryColor.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.pending,
                  label: 'En attente',
                  value: _loading
                      ? '...'
                      : '${_suggestions.where((s) {
                          final total = s.totalMembers;
                          final needed = (total * 0.6).ceil();
                          return s.votes < (needed == 0 ? 6 : needed);
                        }).length}',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final plan = _suggestions[index];
                     final suggestion = {
                       'id': plan.id?.toString() ?? '',
                       'title': plan.title,
                       'description': plan.description,
                       'category': plan.category,
                       'duration': plan.duration,
                       'cost': plan.cost,
                       'votes': plan.votes,
                       'totalMembers': plan.totalMembers,
                       'suggestedBy': plan.suggestedBy,
                       'imageUrl':
                           plan.imageUrls.isNotEmpty ? plan.imageUrls.first : '',
                        'tripDay': plan.tripDay,
                        'tripTime': plan.tripTime,
                       'isVoted': plan.isVoted,
                     };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SuggestionCard(
                        suggestion: suggestion,
                        onVote: () => _toggleVote(plan.id!),
                        onEdit: () => _editSuggestion(plan),
                        onDelete: () => _deleteSuggestion(plan.id!),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('J${day['day']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jour ${day['day']}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(_formatDate(day['date'] as DateTime),
                              style: const TextStyle(
                                  color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.add), onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 16),
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
                              : Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(activity['time'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(activity['duration'],
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Text(activity['title'],
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500))),
                        Icon(
                            activity['status'] == 'confirmed'
                                ? Icons.check_circle
                                : Icons.pending,
                            color: activity['status'] == 'confirmed'
                                ? Colors.green
                                : Colors.orange),
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

  Widget _buildStatItem(
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondaryColor)),
      ],
    );
  }

  Future<void> _toggleVote(int id) async {
    await _db.toggleVote(id);
    await _loadSuggestions();
  }

  Future<void> _editSuggestion(Planification suggestion) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSuggestionScreen(initial: suggestion),
      ),
    );
    if (updated == true) {
      await _loadSuggestions();
    }
  }

  void _deleteSuggestion(int suggestionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la suggestion'),
        content:
            const Text('Êtes-vous sûr de vouloir supprimer cette suggestion ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await _db.deletePlanification(suggestionId);
              if (mounted) Navigator.pop(context);
              await _loadSuggestions();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loading = true);
    try {
      final list = await _db.getAllPlanifications();
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
      // Generate itinerary based on latest suggestions and votes
      _generateItinerary();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur chargement suggestions: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  int _parseDurationToMinutes(String value) {
    if (value.isEmpty) return 0;
    final s = value.toLowerCase().replaceAll(' ', '');
    final hMatch = RegExp(r"(\d+)h").firstMatch(s);
    final mMatch = RegExp(r"(\d+)m").firstMatch(s);
    int minutes = 0;
    if (hMatch != null) minutes += int.parse(hMatch.group(1)!)*60;
    if (mMatch != null) minutes += int.parse(mMatch.group(1)!);
    if (minutes == 0 && RegExp(r'^\d+(\.\d+)?h$').hasMatch(s)) {
      final hours = double.parse(s.replaceAll('h', ''));
      minutes = (hours * 60).round();
    }
    return minutes;
  }

  void _generateItinerary({
    int dayStartHour = 9,
    int dayCapacityMinutes = 8 * 60,
    DateTime? startDate,
    bool approvedFirst = true,
  }) {
    if (_suggestions.isEmpty) {
      setState(() => _itinerary = []);
      return;
    }

    final start = startDate ?? DateTime.now();
    final items = _suggestions
        .where((s) => _parseDurationToMinutes(s.duration) > 0)
        .toList();

    items.sort((a, b) {
      double rateA = (a.totalMembers > 0) ? a.votes / a.totalMembers : 0.0;
      double rateB = (b.totalMembers > 0) ? b.votes / b.totalMembers : 0.0;
      if (approvedFirst) {
        final aApproved = a.totalMembers > 0 && a.votes >= (a.totalMembers * 0.6).ceil();
        final bApproved = b.totalMembers > 0 && b.votes >= (b.totalMembers * 0.6).ceil();
        if (aApproved != bApproved) return (bApproved ? 1 : 0) - (aApproved ? 1 : 0);
      }
      final byRate = rateB.compareTo(rateA);
      if (byRate != 0) return byRate;
      final byVotes = b.votes.compareTo(a.votes);
      if (byVotes != 0) return byVotes;
      return a.createdAt.compareTo(b.createdAt);
    });

    final List<Map<String, dynamic>> result = [];
    int day = 1;
    var currentDate = DateTime(start.year, start.month, start.day);
    int used = 0;
    int curH = dayStartHour;
    int curM = 0;

    result.add({'day': day, 'date': currentDate, 'activities': <Map<String, dynamic>>[]});

    String _hm(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    for (final s in items) {
      final dur = _parseDurationToMinutes(s.duration);
      if (dur <= 0) continue;

      if (used + dur > dayCapacityMinutes) {
        day += 1;
        currentDate = currentDate.add(const Duration(days: 1));
        used = 0;
        curH = dayStartHour;
        curM = 0;
        result.add({'day': day, 'date': currentDate, 'activities': <Map<String, dynamic>>[]});
      }

      final approved = s.totalMembers > 0 && s.votes >= (s.totalMembers * 0.6).ceil();
      result.last['activities'].add({
        'time': _hm(curH, curM),
        'title': s.title,
        'duration': s.duration.isEmpty ? '${(dur / 60).toStringAsFixed(1)}h' : s.duration,
        'status': approved ? 'confirmed' : 'pending',
      });

      final next = curM + dur;
      curH += next ~/ 60;
      curM = next % 60;
      used += dur;
    }

    setState(() {
      _itinerary = result;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les suggestions'),
        content: const Text('Filtrage à implémenter'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }
}
