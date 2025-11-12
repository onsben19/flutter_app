import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/suggestion_card.dart';
import '../../screens/planning/add_suggestion_screen.dart';
import '../../services/database_service.dart';
import '../../models/planification.dart';
import '../../services/weather_service.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _DayState {
  _DayState(this.date);
  final DateTime date;
  final List<Map<String, dynamic>> activities = [];
  int nextMin = 0; // minutes from day start
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  final WeatherService _weatherService = WeatherService();

  List<Planification> _suggestions = [];
  bool _loading = true;
  Map<String, WeatherInfo> _weather = {};
  static const double _tripLat = 48.8566;
  static const double _tripLon = 2.3522;

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
        leading: const AppUserIconButton(), // 👈 user icon now on the LEFT
        title: const Text('Planification'),
        bottom: TabBar(
          controller: _tabController,
          // Improve contrast for selected/unselected states on green AppBar
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.white24;
            }
            return null;
          }),
          tabs: const [
            Tab(icon: Icon(Icons.how_to_vote), text: 'Suggestions'),
            Tab(icon: Icon(Icons.schedule), text: 'Itin\u00E9raire'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            tooltip: 'G\u00E9n\u00E9rer Itin\u00E9raire',
            icon: const Icon(Icons.auto_mode),
            onPressed: () async {
              _generateItinerary();
              await _loadWeatherForItinerary();
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
        label: const Text('Sugg\u00E9rer'),
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
              Container(width: 1, height: 40, color: AppTheme.primaryColor.withOpacity(0.3)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Valid\u00E9es',
                  value: _loading
                      ? '...'
                      : '${_suggestions.where((s) {
                          final total = s.totalMembers;
                          final needed = (total * 0.6).ceil();
                          return s.votes >= (needed == 0 ? 6 : needed);
                        }).length}',
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.primaryColor.withOpacity(0.3)),
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
                      'imageUrl': plan.imageUrls.isNotEmpty ? plan.imageUrls.first : '',
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
        final date = day['date'] as DateTime;
        final wi = _weather[_dateKey(date)];
        final Color? tint = wi == null
            ? null
            : wi.isRainy
                ? Colors.blueGrey.withOpacity(0.06)
                : Colors.orange.withOpacity(0.06);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(color: tint),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'J${day['day']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jour ${day['day']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(_formatDate(day['date'] as DateTime),
                              style: const TextStyle(color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.add), onPressed: () {}),
                  ],
                ),
                if (wi != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        wi.isRainy ? Icons.umbrella : Icons.wb_sunny,
                        color: wi.isRainy ? Colors.blueGrey : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${wi.main} \u00B7 ${wi.temp.toStringAsFixed(0)}\u00B0C \u00B7 ${(wi.pop * 100).round()}% pluie',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                      const Spacer(),
                      if (wi.isRainy && index < _itinerary.length - 1)
                        TextButton(
                          onPressed: () => _swapDays(index),
                          child: const Text('\u00C9changer avec le jour suivant'),
                        ),
                    ],
                  ),
                ],
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
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(activity['time'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(activity['duration'],
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(activity['title'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                        Icon(
                          activity['status'] == 'confirmed' ? Icons.check_circle : Icons.pending,
                          color: activity['status'] == 'confirmed' ? Colors.green : Colors.orange,
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

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
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
      MaterialPageRoute(builder: (_) => AddSuggestionScreen(initial: suggestion)),
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
        content: const Text('\u00CAtes-vous s\u00FBr de vouloir supprimer cette suggestion ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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
      _generateItinerary();
      await _loadWeatherForItinerary();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement suggestions: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadWeatherForItinerary() async {
    try {
      final dates = _itinerary
          .map<DateTime>((d) => d['date'] as DateTime)
          .map((d) => DateTime(d.year, d.month, d.day))
          .toList();
      final Map<String, WeatherInfo> map = {};
      for (final d in dates) {
        final info = await _weatherService.fetchDayForecast(lat: _tripLat, lon: _tripLon, date: d);
        if (info != null) {
          map[_dateKey(d)] = info;
        }
      }
      if (!mounted) return;
      setState(() => _weather = map);
    } catch (_) {
      // ignore
    }
  }

  void _swapDays(int index) {
    if (index < 0 || index >= _itinerary.length - 1) return;
    final tmp = _itinerary[index];
    _itinerary[index] = _itinerary[index + 1];
    _itinerary[index + 1] = tmp;
    for (var i = 0; i < _itinerary.length; i++) {
      _itinerary[i]['day'] = i + 1;
    }
    setState(() {});
  }

  int _parseDurationToMinutes(String value) {
    if (value.isEmpty) return 0;
    final s = value.toLowerCase().trim();

    // HH:MM or H:MM
    final clock = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (clock != null) {
      final h = int.parse(clock.group(1)!);
      final m = int.parse(clock.group(2)!);
      return h * 60 + m;
    }

    final noSpace = s.replaceAll(' ', '');

    // XhYY
    final hm = RegExp(r'^(\d+)h(\d{1,2})$').firstMatch(noSpace);
    if (hm != null) {
      final h = int.parse(hm.group(1)!);
      final m = int.parse(hm.group(2)!);
      return h * 60 + m;
    }

    // Xh
    final hOnly = RegExp(r'^(\d+)h$').firstMatch(noSpace);
    if (hOnly != null) return int.parse(hOnly.group(1)!) * 60;

    // Xm
    final mOnly = RegExp(r'^(\d+)m$').firstMatch(noSpace);
    if (mOnly != null) return int.parse(mOnly.group(1)!);

    // 1.5h
    final dec = RegExp(r'^(\d+(?:\.\d+)?)h$').firstMatch(noSpace);
    if (dec != null) {
      final hours = double.parse(dec.group(1)!);
      return (hours * 60).round();
    }

    // Bare number => minutes
    final bare = RegExp(r'^(\d+)$').firstMatch(noSpace);
    if (bare != null) return int.parse(bare.group(1)!);

    return 0;
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

    int startOfDayMin = dayStartHour * 60;
    String hmFromStart(int minFromStart) {
      final total = startOfDayMin + minFromStart;
      final h = total ~/ 60;
      final m = total % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    // Separate pinned and remaining suggestions
    final all = _suggestions.where((s) => _parseDurationToMinutes(s.duration) > 0).toList();
    final pinned = all.where((s) => (s.tripDay) > 0).toList();
    final remaining = all.where((s) => (s.tripDay) <= 0).toList();

    // Sort remaining by priority (approved first, approval rate, votes, createdAt)
    int priorityCompare(Planification a, Planification b) {
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
    }
    remaining.sort(priorityCompare);

    // Day state helpers
    final Map<int, _DayState> days = {};
    _DayState ensureDay(int dayIndex) {
      return days.putIfAbsent(dayIndex, () {
        final d = DateTime(start.year, start.month, start.day).add(Duration(days: dayIndex - 1));
        return _DayState(d);
      });
    }

    int parseTripTimeToStartMin(String t) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t.trim());
      if (m == null) return -1;
      final h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      final total = h * 60 + min;
      return total - startOfDayMin; // relative to day start
    }
    void placeActivity(_DayState dayState, Planification s, int startMin, int dur) {
      if (startMin < 0) startMin = 0;
      if (startMin + dur > dayCapacityMinutes) {
        // Clamp to fit within capacity if possible
        if (dur <= dayCapacityMinutes) {
          startMin = dayCapacityMinutes - dur;
        } else {
          // If duration longer than capacity, cut at capacity
          dur = dayCapacityMinutes;
          startMin = 0;
        }
      }
      final approved = s.totalMembers > 0 && s.votes >= (s.totalMembers * 0.6).ceil();
      dayState.activities.add({
        'startMin': startMin,
        'time': hmFromStart(startMin),
        'title': s.title,
        'duration': s.duration.isEmpty ? '${(dur / 60).toStringAsFixed(1)}h' : s.duration,
        'status': approved ? 'confirmed' : 'pending',
      });
      if (startMin + dur > dayState.nextMin) dayState.nextMin = startMin + dur;
    }

    // 1) Place pinned items first
    for (final s in pinned) {
      final dur = _parseDurationToMinutes(s.duration);
      if (dur <= 0) continue;
      final dayIdx = s.tripDay;
      final dayState = ensureDay(dayIdx);
      int desiredStart = -1;
      if (s.tripTime.trim().isNotEmpty) {
        desiredStart = parseTripTimeToStartMin(s.tripTime);
      }
      if (desiredStart < 0) desiredStart = dayState.nextMin;
      placeActivity(dayState, s, desiredStart, dur);
    }

    // 2) Fill remaining capacity with the rest
    int dayPtr = days.isEmpty ? 1 : days.keys.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    for (final s in remaining) {
      final dur = _parseDurationToMinutes(s.duration);
      if (dur <= 0) continue;
      while (true) {
        final dayState = ensureDay(dayPtr);
        if (dayState.nextMin + dur <= dayCapacityMinutes) {
          placeActivity(dayState, s, dayState.nextMin, dur);
          break;
        } else {
          dayPtr += 1; // move to next day
        }
      }
    }

    // Build ordered result and sort activities by start time
    final List<Map<String, dynamic>> result = [];
    final orderedDays = days.keys.toList()..sort();
    for (final d in orderedDays) {
      final ds = days[d]!;
      ds.activities.sort((a, b) => (a['startMin'] as int).compareTo(b['startMin'] as int));
      final acts = ds.activities
          .map((a) => {
                'time': a['time'],
                'title': a['title'],
                'duration': a['duration'],
                'status': a['status'],
              })
          .toList();
      result.add({'day': d, 'date': ds.date, 'activities': acts});
    }

    setState(() {
      _itinerary = result;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier',
      'F\u00E9vrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Ao\u00FBt',
      'Septembre',
      'Octobre',
      'Novembre',
      'D\u00E9cembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les suggestions'),
        content: const Text('Filtrage \u00E0 impl\u00E9menter'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
