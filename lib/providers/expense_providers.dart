import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

// Provider pour le service
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

// Provider pour les dépenses d'un groupe
final expensesProvider = StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final service = ref.watch(expenseServiceProvider);
  return service.getExpensesByGroup(groupId);
});

// Provider pour les soldes des membres
final memberBalancesProvider = FutureProvider.family<Map<String, MemberBalance>, BalanceParams>((ref, params) async {
  final service = ref.watch(expenseServiceProvider);
  final expensesAsync = ref.watch(expensesProvider(params.groupId));
  
  return expensesAsync.when(
    data: (expenses) async {
      return await service.calculateMemberBalances(expenses, params.memberNames);
    },
    loading: () => <String, MemberBalance>{},
    error: (_, __) => <String, MemberBalance>{},
  );
});

// Paramètres pour le calcul des balances
class BalanceParams {
  final String groupId;
  final Map<String, String> memberNames;

  BalanceParams({
    required this.groupId,
    required this.memberNames,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          memberNames.toString() == other.memberNames.toString();

  @override
  int get hashCode => groupId.hashCode ^ memberNames.toString().hashCode;
}

// Provider pour les dettes
final debtsProvider = FutureProvider.family<List<Debt>, DebtParams>((ref, params) async {
  final service = ref.watch(expenseServiceProvider);
  final balancesAsync = ref.watch(memberBalancesProvider(params.balanceParams));
  
  return balancesAsync.when(
    data: (balances) {
      return service.calculateDebts(balances);
    },
    loading: () => <Debt>[],
    error: (_, __) => <Debt>[],
  );
});

// Paramètres pour le calcul des dettes
class DebtParams {
  final BalanceParams balanceParams;

  DebtParams({required this.balanceParams});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtParams &&
          runtimeType == other.runtimeType &&
          balanceParams == other.balanceParams;

  @override
  int get hashCode => balanceParams.hashCode;
}

// Provider pour les dépenses filtrées
final filteredExpensesProvider = StreamProvider.family<List<Expense>, FilterParams>((ref, params) {
  final service = ref.watch(expenseServiceProvider);
  return service.filterExpenses(
    groupId: params.groupId,
    category: params.category,
    memberId: params.memberId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// Paramètres de filtrage
class FilterParams {
  final String groupId;
  final String? category;
  final String? memberId;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterParams({
    required this.groupId,
    this.category,
    this.memberId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          category == other.category &&
          memberId == other.memberId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      groupId.hashCode ^
      category.hashCode ^
      memberId.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;
}

// Provider pour les catégories
final categoriesProvider = FutureProvider.family<List<String>, String>((ref, groupId) async {
  final service = ref.watch(expenseServiceProvider);
  return await service.getCategories(groupId);
});

// Provider pour le total des dépenses
final totalExpensesProvider = Provider.family<double, List<Expense>>((ref, expenses) {
  final service = ref.watch(expenseServiceProvider);
  return service.getTotalExpenses(expenses);
});

// Provider pour les totaux par catégorie
final totalsByCategoryProvider = Provider.family<Map<String, double>, List<Expense>>((ref, expenses) {
  final service = ref.watch(expenseServiceProvider);
  return service.getTotalByCategory(expenses);
});

