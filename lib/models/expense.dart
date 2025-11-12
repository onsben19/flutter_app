class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paidBy; // ID ou nom du membre qui a payé
  final List<String> participants; // IDs ou noms des participants
  final String groupId; // ID du groupe de voyage
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paidBy,
    required this.participants,
    required this.groupId,
    this.description,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculer la part de chaque participant
  double get sharePerPerson {
    if (participants.isEmpty) return 0.0;
    return amount / participants.length;
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'paidBy': paidBy,
      'participants': participants,
      'groupId': groupId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Créer un objet depuis une Map (données Firestore)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? map['documentId'],
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      paidBy: map['paidBy'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      groupId: map['groupId'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is DateTime
              ? map['updatedAt']
              : DateTime.parse(map['updatedAt']))
          : null,
    );
  }

  // Méthode pour créer une copie avec des modifications
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paidBy,
    List<String>? participants,
    String? groupId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Modèle pour les soldes et dettes
class MemberBalance {
  final String memberId;
  final String memberName;
  final double totalPaid; // Total payé par ce membre
  final double totalOwed; // Total dû par ce membre
  final double balance; // Solde (totalPaid - totalOwed)

  MemberBalance({
    required this.memberId,
    required this.memberName,
    this.totalPaid = 0.0,
    this.totalOwed = 0.0,
    double? balance,
  }) : balance = balance ?? (totalPaid - totalOwed);

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'totalPaid': totalPaid,
      'totalOwed': totalOwed,
      'balance': balance,
    };
  }

  factory MemberBalance.fromMap(Map<String, dynamic> map) {
    return MemberBalance(
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      totalOwed: (map['totalOwed'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
    );
  }
}

// Modèle pour les dettes entre membres
class Debt {
  final String fromMemberId; // Qui doit
  final String fromMemberName;
  final String toMemberId; // À qui on doit
  final String toMemberName;
  final double amount;

  Debt({
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromMemberId': fromMemberId,
      'fromMemberName': fromMemberName,
      'toMemberId': toMemberId,
      'toMemberName': toMemberName,
      'amount': amount,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      fromMemberId: map['fromMemberId'] ?? '',
      fromMemberName: map['fromMemberName'] ?? '',
      toMemberId: map['toMemberId'] ?? '',
      toMemberName: map['toMemberName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

