import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/expense.dart';
import '../../providers/expense_providers.dart';
import '../../services/expense_service.dart';

class ExpensesAnalyticsScreen extends ConsumerWidget {
  final String groupId;
  final Map<String, String> memberNames;

  const ExpensesAnalyticsScreen({
    super.key,
    required this.groupId,
    required this.memberNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(groupId));
    final balanceParams = BalanceParams(
      groupId: groupId,
      memberNames: memberNames,
    );
    final balancesAsync = ref.watch(memberBalancesProvider(balanceParams));
    final debtParams = DebtParams(balanceParams: balanceParams);
    final debtsAsync = ref.watch(debtsProvider(debtParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytiques'),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text('Aucune dépense à analyser'),
            );
          }

          final expenseService = ExpenseService();
          final totalExpenses = expenseService.getTotalExpenses(expenses);
          final totalsByCategory = expenseService.getTotalByCategory(expenses);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Graphique par catégorie
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Répartition par catégorie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...totalsByCategory.entries.map((entry) {
                        final percentage = (entry.value / totalExpenses * 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text(
                                    '${entry.value.toStringAsFixed(2)} € (${percentage.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCategoryColor(entry.key),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Soldes des membres
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Soldes des membres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      balancesAsync.when(
                        data: (balances) {
                          if (balances.isEmpty) {
                            return const Text('Aucun solde disponible');
                          }
                          return Column(
                            children: balances.values.map((balance) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            balance.memberName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Payé: ${balance.totalPaid.toStringAsFixed(2)} € • Dû: ${balance.totalOwed.toStringAsFixed(2)} €',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: balance.balance >= 0
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${balance.balance >= 0 ? '+' : ''}${balance.balance.toStringAsFixed(2)} €',
                                        style: TextStyle(
                                          color: balance.balance >= 0
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dettes à régler
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dettes à régler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      debtsAsync.when(
                        data: (debts) {
                          if (debts.isEmpty) {
                            return const Text(
                              'Tous les comptes sont équilibrés !',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return Column(
                            children: debts.map((debt) {
                              return Card(
                                color: Colors.orange.shade50,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    '${debt.fromMemberName} → ${debt.toMemberName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${debt.amount.toStringAsFixed(2)} €',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Erreur: $error'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            ],
          ),
        ),
      ),
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
      case 'Shopping':
        return Colors.pink;
      default:
        return AppTheme.primaryColor;
    }
  }
}

