import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';

class ExpenseService {
  static Database? _database;
  static const String _dbName = 'travel_expenses.db';
  static const String _tableName = 'expenses';

  final Map<String, StreamController<List<Expense>>> _groupControllers = {};

  // Singleton pattern
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date INTEGER NOT NULL,
            paidBy TEXT NOT NULL,
            participants TEXT NOT NULL,
            groupId TEXT NOT NULL,
            description TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER
          )
        ''');
      },
    );
    return _database!;
  }

  String _participantsToString(List<String> p) => p.join(',');
  List<String> _participantsFromString(String s) =>
      s.isEmpty ? <String>[] : s.split(',');

  Expense _fromRow(Map<String, dynamic> row) {
    return Expense(
      id: row['id']?.toString(),
      title: row['title'],
      amount: (row['amount'] as num).toDouble(),
      category: row['category'],
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      paidBy: row['paidBy'],
      participants: _participantsFromString(row['participants'] ?? ''),
      groupId: row['groupId'],
      description: row['description'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      updatedAt: row['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> _toRow(Expense expense) {
    return {
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': expense.date.millisecondsSinceEpoch,
      'paidBy': expense.paidBy,
      'participants': _participantsToString(expense.participants),
      'groupId': expense.groupId,
      'description': expense.description,
      'createdAt': expense.createdAt.millisecondsSinceEpoch,
      'updatedAt': expense.updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Créer une nouvelle dépense
  Future<String> createExpense(Expense expense) async {
    try {
      final db = await _db;
      final id = await db.insert(_tableName, _toRow(expense));
      await _notifyGroup(expense.groupId);
      return id.toString();
    } catch (e) {
      throw Exception('Erreur lors de la création de la dépense: $e');
    }
  }

  // Lire toutes les dépenses d'un groupe
  Stream<List<Expense>> getExpensesByGroup(String groupId) {
    _groupControllers[groupId] ??=
        StreamController<List<Expense>>.broadcast(onListen: () {
      _notifyGroup(groupId);
    });
    return _groupControllers[groupId]!.stream;
  }

  // Lire une dépense par ID
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [int.tryParse(expenseId)],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la dépense: $e');
    }
  }

  // Mettre à jour une dépense
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) throw Exception('ID de dépense manquant');
      final db = await _db;
      await db.update(
        _tableName,
        _toRow(expense.copyWith(updatedAt: DateTime.now())),
        where: 'id = ?',
        whereArgs: [int.tryParse(expense.id!)],
      );
      await _notifyGroup(expense.groupId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la dépense: $e');
    }
  }

  // Supprimer une dépense
  Future<void> deleteExpense(String expenseId) async {
    try {
      final db = await _db;
      // récupérer groupId pour notifier
      final existing = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [int.tryParse(expenseId)],
        limit: 1,
      );
      String? groupId;
      if (existing.isNotEmpty) {
        groupId = existing.first['groupId'] as String?;
      }
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [int.tryParse(expenseId)],
      );
      if (groupId != null) {
        await _notifyGroup(groupId);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la dépense: $e');
    }
  }

  // Filtrer les dépenses
  Stream<List<Expense>> filterExpenses({
    required String groupId,
    String? category,
    String? memberId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getExpensesByGroup(groupId).map((expenses) {
      var result = expenses;
      if (category != null && category.isNotEmpty) {
        result = result.where((e) => e.category == category).toList();
      }
      if (memberId != null && memberId.isNotEmpty) {
        result = result.where((e) => e.paidBy == memberId).toList();
      }
      if (startDate != null) {
        result = result
            .where((e) =>
                e.date.isAtSameMomentAs(startDate) || e.date.isAfter(startDate))
            .toList();
      }
      if (endDate != null) {
        result = result
            .where((e) =>
                e.date.isAtSameMomentAs(endDate) || e.date.isBefore(endDate))
            .toList();
      }
      result.sort((a, b) => b.date.compareTo(a.date));
      return result;
    });
  }

  // Calculer les soldes de chaque membre
  Future<Map<String, MemberBalance>> calculateMemberBalances(
    List<Expense> expenses,
    Map<String, String> memberNames, // Map de memberId -> memberName
  ) async {
    final Map<String, MemberBalance> balances = {};

    // Initialiser les balances pour tous les membres
    for (final memberId in memberNames.keys) {
      balances[memberId] = MemberBalance(
        memberId: memberId,
        memberName: memberNames[memberId] ?? memberId,
      );
    }

    // Calculer les totaux
    for (final expense in expenses) {
      final sharePerPerson = expense.sharePerPerson;

      // Ajouter au total payé par le payeur
      if (balances.containsKey(expense.paidBy)) {
        final current = balances[expense.paidBy]!;
        balances[expense.paidBy] = MemberBalance(
          memberId: current.memberId,
          memberName: current.memberName,
          totalPaid: current.totalPaid + expense.amount,
          totalOwed: current.totalOwed,
        );
      }

      // Ajouter au total dû par chaque participant
      for (final participantId in expense.participants) {
        if (balances.containsKey(participantId)) {
          final current = balances[participantId]!;
          balances[participantId] = MemberBalance(
            memberId: current.memberId,
            memberName: current.memberName,
            totalPaid: current.totalPaid,
            totalOwed: current.totalOwed + sharePerPerson,
          );
        }
      }
    }

    // Calculer les balances finales
    for (final memberId in balances.keys) {
      final balance = balances[memberId]!;
      balances[memberId] = MemberBalance(
        memberId: balance.memberId,
        memberName: balance.memberName,
        totalPaid: balance.totalPaid,
        totalOwed: balance.totalOwed,
        balance: balance.totalPaid - balance.totalOwed,
      );
    }

    return balances;
  }

  // Algorithme de calcul des dettes (simplifié - minimise le nombre de transactions)
  List<Debt> calculateDebts(
    Map<String, MemberBalance> balances,
  ) {
    final List<Debt> debts = [];
    final List<MemberBalance> creditors = []; // Ceux qui ont un solde positif
    final List<MemberBalance> debtors = []; // Ceux qui ont un solde négatif

    // Séparer les créanciers et les débiteurs
    for (final balance in balances.values) {
      if (balance.balance > 0.01) {
        // Tolérance pour les arrondis
        creditors.add(balance);
      } else if (balance.balance < -0.01) {
        debtors.add(balance);
      }
    }

    // Trier par montant décroissant
    creditors.sort((a, b) => b.balance.compareTo(a.balance));
    debtors.sort((a, b) => a.balance.compareTo(b.balance));

    // Algorithme de minimisation des transactions
    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];

      final amountToSettle = creditor.balance.abs() < debtor.balance.abs()
          ? creditor.balance
          : debtor.balance.abs();

      if (amountToSettle > 0.01) {
        debts.add(Debt(
          fromMemberId: debtor.memberId,
          fromMemberName: debtor.memberName,
          toMemberId: creditor.memberId,
          toMemberName: creditor.memberName,
          amount: amountToSettle,
        ));

        // Mettre à jour les balances
        creditors[creditorIndex] = MemberBalance(
          memberId: creditor.memberId,
          memberName: creditor.memberName,
          totalPaid: creditor.totalPaid,
          totalOwed: creditor.totalOwed,
          balance: creditor.balance - amountToSettle,
        );

        debtors[debtorIndex] = MemberBalance(
          memberId: debtor.memberId,
          memberName: debtor.memberName,
          totalPaid: debtor.totalPaid,
          totalOwed: debtor.totalOwed,
          balance: debtor.balance + amountToSettle,
        );
      }

      // Passer au suivant si le solde est réglé
      if (creditors[creditorIndex].balance < 0.01) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].balance > -0.01) {
        debtorIndex++;
      }
    }

    return debts;
  }

  // Obtenir le total général des dépenses
  double getTotalExpenses(List<Expense> expenses) {
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  // Obtenir le total par catégorie
  Map<String, double> getTotalByCategory(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  // Obtenir les catégories uniques
  Future<List<String>> getCategories(String groupId) async {
    final db = await _db;
    final rows = await db.query(
      _tableName,
      columns: ['DISTINCT category'],
      where: 'groupId = ?',
      whereArgs: [groupId],
    );
    final categories = rows
        .map((r) => (r['category'] as String?) ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  Future<void> _notifyGroup(String groupId) async {
    final controller = _groupControllers[groupId];
    if (controller == null) return;
    final db = await _db;
    final rows = await db.query(
      _tableName,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    final items = rows.map(_fromRow).toList();
    if (!controller.isClosed) controller.add(items);
  }
}

