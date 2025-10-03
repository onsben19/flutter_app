import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // Données factices pour les dépenses
  final List<Map<String, dynamic>> _expenses = [
    {
      'id': '1',
      'title': 'Hôtel Paris',
      'amount': 250.0,
      'paidBy': 'Marie',
      'date': DateTime(2024, 6, 15),
      'participants': ['Marie', 'Pierre', 'Julie', 'Thomas'],
      'category': 'Hébergement',
    },
    {
      'id': '2',
      'title': 'Restaurant Le Procope',
      'amount': 85.50,
      'paidBy': 'Pierre',
      'date': DateTime(2024, 6, 16),
      'participants': ['Marie', 'Pierre', 'Julie'],
      'category': 'Restaurant',
    },
    {
      'id': '3',
      'title': 'Transport Metro',
      'amount': 20.0,
      'paidBy': 'Julie',
      'date': DateTime(2024, 6, 16),
      'participants': ['Marie', 'Pierre', 'Julie', 'Thomas'],
      'category': 'Transport',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['amount'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              _showExpensesAnalytics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Résumé des dépenses
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Total des dépenses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${totalExpenses.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Dépenses',
                        '${_expenses.length}',
                        Icons.receipt_long,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Moyenne',
                        '${(totalExpenses / _expenses.length).toStringAsFixed(2)} €',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des dépenses
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(expense['category']),
                      child: Icon(
                        _getCategoryIcon(expense['category']),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      expense['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payé par ${expense['paidBy']}'),
                        Text(
                          '${expense['participants'].length} participants',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${expense['amount']} €',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          _formatDate(expense['date']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showExpenseDetails(expense),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "expenses_fab",
        onPressed: () => _addExpense(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle dépense'),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hébergement':
        return Colors.blue;
      case 'Restaurant':
        return Colors.orange;
      case 'Transport':
        return Colors.green;
      case 'Activité':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hébergement':
        return Icons.hotel;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Activité':
        return Icons.local_activity;
      default:
        return Icons.attach_money;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${expense['amount']} €'),
            Text('Payé par: ${expense['paidBy']}'),
            Text('Date: ${_formatDate(expense['date'])}'),
            const SizedBox(height: 8),
            const Text('Participants:'),
            ...expense['participants'].map<Widget>((participant) => 
              Text('• $participant')).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    // TODO: Navigator vers écran d'ajout de dépense
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'ajout de dépense à implémenter'),
      ),
    );
  }

  void _showExpensesAnalytics() {
    // TODO: Afficher les analytiques
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytiques des dépenses à implémenter'),
      ),
    );
  }
}