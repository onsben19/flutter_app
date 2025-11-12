import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/expense.dart';
import '../../providers/expense_providers.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'expenses_analytics_screen.dart';
import '../../services/export_service.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> groupMembers; // Liste des IDs des membres
  final Map<String, String> memberNames; // Map ID -> Nom

  const ExpensesScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
    required this.memberNames,
  });

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedCategory;
  String? _selectedMember;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider(widget.groupId));
    final filterParams = FilterParams(
      groupId: widget.groupId,
      category: _selectedCategory,
      memberId: _selectedMember,
      startDate: _startDate,
      endDate: _endDate,
    );
    final filteredExpensesAsync = ref.watch(filteredExpensesProvider(filterParams));

    // Utiliser les dépenses filtrées si des filtres sont actifs, sinon toutes les dépenses
    final displayExpensesAsync = (_selectedCategory != null ||
            _selectedMember != null ||
            _startDate != null ||
            _endDate != null)
        ? filteredExpensesAsync
        : expensesAsync;
>>>>>>> 8b17762 ( expenses module)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              _showExpensesAnalytics();
=======
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesAnalyticsScreen(
                    groupId: widget.groupId,
                    memberNames: widget.memberNames,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Exporter'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'export') {
                await _showExportDialog(context);
              }
>>>>>>> 8b17762 ( expenses module)
            },
          ),
        ],
      ),
      body: Column(
        children: [
<<<<<<< HEAD
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
=======
          // Filtres
          if (_showFilters) _buildFiltersSection(),

          // Résumé des dépenses
          displayExpensesAsync.when(
            data: (expenses) => _buildSummarySection(expenses),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur: $error'),
>>>>>>> 8b17762 ( expenses module)
            ),
          ),

          // Liste des dépenses
          Expanded(
<<<<<<< HEAD
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
=======
            child: displayExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(expensesProvider(widget.groupId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _buildExpenseCard(expense);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text('Erreur: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(expensesProvider(widget.groupId));
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
>>>>>>> 8b17762 ( expenses module)
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

<<<<<<< HEAD
=======
  Widget _buildFiltersSection() {
    final categoriesAsync = ref.watch(categoriesProvider(widget.groupId));

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedMember = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filtre par catégorie
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ...categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            // Filtre par membre
            DropdownButtonFormField<String>(
              value: _selectedMember,
              decoration: const InputDecoration(
                labelText: 'Payé par',
                prefixIcon: Icon(Icons.person),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                ...widget.groupMembers.map((memberId) => DropdownMenuItem(
                      value: memberId,
                      child: Text(widget.memberNames[memberId] ?? memberId),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // Filtre par date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        prefixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Sélectionner',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date fin',
                        prefixIcon: Icon(Icons.calendar_today),
                        isDense: true,
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Sélectionner',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<Expense> expenses) {
    final totalExpenses = expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final balanceParams = BalanceParams(
      groupId: widget.groupId,
      memberNames: widget.memberNames,
    );
    final balancesAsync = ref.watch(memberBalancesProvider(balanceParams));

    return Container(
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
                  '${expenses.length}',
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
                  expenses.isNotEmpty
                      ? '${(totalExpenses / expenses.length).toStringAsFixed(2)} €'
                      : '0.00 €',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Totaux par personne
          balancesAsync.when(
            data: (balances) {
              if (balances.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  const Divider(color: Colors.white70),
                  const SizedBox(height: 8),
                  const Text(
                    'Totaux par personne',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...balances.values.map((balance) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                balance.memberName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${balance.balance.toStringAsFixed(2)} €',
                              style: TextStyle(
                                color: balance.balance >= 0
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

>>>>>>> 8b17762 ( expenses module)
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

<<<<<<< HEAD
=======
  Widget _buildExpenseCard(Expense expense) {
    final paidByName = widget.memberNames[expense.paidBy] ?? expense.paidBy;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payé par $paidByName'),
            Text(
              '${expense.participants.length} participant(s) • ${DateFormat('dd/MM/yyyy').format(expense.date)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              '${expense.sharePerPerson.toStringAsFixed(2)} €/pers',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(
                expense: expense,
                memberNames: widget.memberNames,
                groupMembers: widget.groupMembers,
              ),
            ),
          ).then((refreshed) {
            if (refreshed == true) {
              ref.invalidate(expensesProvider(widget.groupId));
            }
          });
        },
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
                Icons.receipt_long_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune dépense',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Commencez par ajouter votre première dépense',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

>>>>>>> 8b17762 ( expenses module)
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
<<<<<<< HEAD
=======
      case 'Shopping':
        return Colors.pink;
>>>>>>> 8b17762 ( expenses module)
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
<<<<<<< HEAD
=======
      case 'Shopping':
        return Icons.shopping_bag;
>>>>>>> 8b17762 ( expenses module)
      default:
        return Icons.attach_money;
    }
  }

<<<<<<< HEAD
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
=======
  void _addExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupId: widget.groupId,
          groupMembers: widget.groupMembers,
          memberNames: widget.memberNames,
        ),
      ),
    ).then((refreshed) {
      if (refreshed == true) {
        ref.invalidate(expensesProvider(widget.groupId));
      }
    });
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les dépenses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
          ],
        ),
      ),
    );

    if (format != null) {
      // Récupérer les dépenses depuis le provider
      final expensesAsync = ref.read(expensesProvider(widget.groupId));
      expensesAsync.when(
        data: (expenses) async {
          try {
            final exportService = ExportService();
            if (format == 'pdf') {
              await exportService.exportToPDF(
                expenses,
                widget.memberNames,
                widget.groupId,
              );
            } else {
              await exportService.exportToCSV(
                expenses,
                widget.memberNames,
                widget.groupId,
              );
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export $format réussi')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur lors de l\'export: $e')),
              );
            }
          }
        },
        loading: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chargement des données...')),
          );
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $error')),
          );
        },
      );
    }
  }
}
>>>>>>> 8b17762 ( expenses module)
