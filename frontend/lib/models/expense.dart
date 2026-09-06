import 'user.dart';

class ExpenseSplit {
  final int id;
  final int userId;
  final User user;
  final double shareAmount;

  ExpenseSplit({
    required this.id,
    required this.userId,
    required this.user,
    required this.shareAmount,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      id: json['id'],
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      shareAmount: (json['share_amount'] as num).toDouble(),
    );
  }
}

class Expense {
  final int id;
  final int roomId;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final DateTime expenseDate;
  final int paidById;
  final User paidBy;
  final DateTime? createdAt;
  final List<ExpenseSplit> splits;

  Expense({
    required this.id,
    required this.roomId,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.paidById,
    required this.paidBy,
    this.createdAt,
    this.splits = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    var rawSplits = json['splits'] as List? ?? [];
    List<ExpenseSplit> splitsList =
        rawSplits.map((s) => ExpenseSplit.fromJson(s)).toList();

    return Expense(
      id: json['id'],
      roomId: json['room_id'],
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] ?? 'Groceries',
      expenseDate: DateTime.parse(json['expense_date']),
      paidById: json['paid_by_id'],
      paidBy: User.fromJson(json['paid_by']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      splits: splitsList,
    );
  }
}
