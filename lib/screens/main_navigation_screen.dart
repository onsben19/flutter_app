import 'package:flutter/material.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/planning/planning_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/journal/journal_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GroupsScreen(),
    const PlanningScreen(),
<<<<<<< HEAD
    const ExpensesScreen(),
=======
    ExpensesScreen(
      groupId: 'demo-group',
      groupMembers: ['marie', 'pierre', 'julie', 'thomas'],
      memberNames: {
        'marie': 'Marie',
        'pierre': 'Pierre',
        'julie': 'Julie',
        'thomas': 'Thomas',
      },
    ),
>>>>>>> 8b17762 ( expenses module)
    const MapScreen(),
    const JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groupes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Planification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Dépenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Carnet',
          ),
        ],
      ),
    );
  }
}