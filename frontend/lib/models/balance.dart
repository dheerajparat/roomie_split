import 'user.dart';

class MemberBalance {
  final int userId;
  final User user;
  final double totalPaid;
  final double totalShare;
  final double netBalance;

  MemberBalance({
    required this.userId,
    required this.user,
    required this.totalPaid,
    required this.totalShare,
    required this.netBalance,
  });

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      userId: json['user_id'],
      user: User.fromJson(json['user']),
      totalPaid: (json['total_paid'] as num).toDouble(),
      totalShare: (json['total_share'] as num).toDouble(),
      netBalance: (json['net_balance'] as num).toDouble(),
    );
  }
}

class DebtTransaction {
  final User fromUser;
  final User toUser;
  final double amount;

  DebtTransaction({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });

  factory DebtTransaction.fromJson(Map<String, dynamic> json) {
    return DebtTransaction(
      fromUser: User.fromJson(json['from_user']),
      toUser: User.fromJson(json['to_user']),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class BalanceSummary {
  final int roomId;
  final double totalRoomExpenses;
  final List<MemberBalance> memberBalances;
  final List<DebtTransaction> suggestedSettlements;

  BalanceSummary({
    required this.roomId,
    required this.totalRoomExpenses,
    required this.memberBalances,
    required this.suggestedSettlements,
  });

  factory BalanceSummary.fromJson(Map<String, dynamic> json) {
    var rawBalances = json['member_balances'] as List? ?? [];
    var rawSettlements = json['suggested_settlements'] as List? ?? [];

    return BalanceSummary(
      roomId: json['room_id'],
      totalRoomExpenses: (json['total_room_expenses'] as num).toDouble(),
      memberBalances: rawBalances.map((b) => MemberBalance.fromJson(b)).toList(),
      suggestedSettlements: rawSettlements.map((s) => DebtTransaction.fromJson(s)).toList(),
    );
  }
}

class Settlement {
  final int id;
  final int roomId;
  final int payerId;
  final User payer;
  final int receiverId;
  final User receiver;
  final double amount;
  final DateTime settledAt;
  final String? notes;

  Settlement({
    required this.id,
    required this.roomId,
    required this.payerId,
    required this.payer,
    required this.receiverId,
    required this.receiver,
    required this.amount,
    required this.settledAt,
    this.notes,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'],
      roomId: json['room_id'],
      payerId: json['payer_id'],
      payer: User.fromJson(json['payer']),
      receiverId: json['receiver_id'],
      receiver: User.fromJson(json['receiver']),
      amount: (json['amount'] as num).toDouble(),
      settledAt: DateTime.parse(json['settled_at']),
      notes: json['notes'],
    );
  }
}
