import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Données factices pour les points d'intérêt
  final List<Map<String, dynamic>> _locations = [
    {
      'id': '1',
      'name': 'Tour Eiffel',
      'type': 'Monument',
      'lat': 48.8584,
      'lng': 2.2945,
      'description': 'Monument emblématique de Paris',
      'isVisited': true,
      'isFavorite': true,
    },
    {
      'id': '2',
      'name': 'Louvre',
      'type': 'Musée',
      'lat': 48.8606,
      'lng': 2.3376,
      'description': 'Musée d\'art mondialement connu',
      'isVisited': false,
      'isFavorite': true,
    },
    {
      'id': '3',
      'name': 'Notre-Dame',
      'type': 'Monument',
      'lat': 48.8530,
      'lng': 2.3499,
      'description': 'Cathédrale gothique historique',
      'isVisited': false,
      'isFavorite': false,
    },
  ];

  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Monuments', 'Musées', 'Restaurants', 'Activités'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte Interactive'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => _centerOnCurrentLocation(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Simulation de carte (remplacer par vraie carte plus tard)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade200,
                    Colors.green.shade200,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // Simulation de la carte de Paris
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Carte Interactive de Paris',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Intégration Google Maps/MapBox à venir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Points d'intérêt simulés
                  ..._locations.map((location) => Positioned(
                    left: 50 + (_locations.indexOf(location) * 80.0),
                    top: 100 + (_locations.indexOf(location) * 50.0),
                    child: GestureDetector(
                      onTap: () => _showLocationDetails(location),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: location['isVisited'] ? Colors.green : AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getLocationIcon(location['type']),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (location['isFavorite'])
                              const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 14,
                              ),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
          
          // Liste des lieux
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Filtre
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Lieux d\'intérêt:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _selectedFilter,
                        items: _filters.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Liste des lieux
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: location['isVisited'] 
                                ? Colors.green 
                                : AppTheme.primaryColor,
                            child: Icon(
                              _getLocationIcon(location['type']),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  location['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (location['isFavorite'])
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(location['description']),
                              Text(
                                location['type'],
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (location['isVisited'])
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.directions),
                            ],
                          ),
                          onTap: () => _showLocationDetails(location),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "map_fab",
        onPressed: () => _addCustomLocation(),
        icon: const Icon(Icons.add_location),
        label: const Text('Ajouter lieu'),
      ),
    );
  }

  IconData _getLocationIcon(String type) {
    switch (type) {
      case 'Monument':
        return Icons.account_balance;
      case 'Musée':
        return Icons.museum;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Activité':
        return Icons.local_activity;
      default:
        return Icons.place;
    }
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    location['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    location['isFavorite'] ? Icons.star : Icons.star_outline,
                    color: Colors.amber,
                  ),
                  onPressed: () => _toggleFavorite(location['id']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location['type'],
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(location['description']),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToLocation(location),
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAsVisited(location['id']),
                    icon: Icon(
                      location['isVisited'] ? Icons.check_circle : Icons.circle_outlined,
                    ),
                    label: Text(
                      location['isVisited'] ? 'Visité' : 'Marquer visité',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centrage sur la position actuelle'),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les lieux'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) => RadioListTile<String>(
            title: Text(filter),
            value: filter,
            groupValue: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _addCustomLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ajout de lieu personnalisé à implémenter'),
      ),
    );
  }

  void _toggleFavorite(String locationId) {
    setState(() {
      final location = _locations.firstWhere((l) => l['id'] == locationId);
      location['isFavorite'] = !location['isFavorite'];
    });
    Navigator.pop(context);
  }

  void _markAsVisited(String locationId) {
    setState(() {
      final location = _locations.firstWhere((l) => l['id'] == locationId);
      location['isVisited'] = !location['isVisited'];
    });
    Navigator.pop(context);
  }

  void _navigateToLocation(Map<String, dynamic> location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers ${location['name']}'),
      ),
    );
  }
}