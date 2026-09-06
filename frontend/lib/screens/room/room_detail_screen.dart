import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import 'add_expense_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _inviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final roomProv = Provider.of<RoomProvider>(context, listen: false);
    final expProv = Provider.of<ExpenseProvider>(context, listen: false);
    await Future.wait([
      roomProv.fetchRoomDetails(widget.roomId),
      expProv.fetchExpenses(widget.roomId),
      expProv.fetchBalances(widget.roomId),
    ]);
  }

  void _showInviteDialog() {
    _inviteController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Roommate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the username or email of your flatmate. They will receive an invitation to approve joining this room.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_inviteController.text.trim().isEmpty) return;
              final roomProv = Provider.of<RoomProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final dialogNav = Navigator.of(ctx);
              final success = await roomProv.inviteUser(widget.roomId, _inviteController.text);
              dialogNav.pop();
              if (!mounted) return;
              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Invitation sent! Waiting for their approval.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (roomProv.errorMessage != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(roomProv.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showSettleUpDialog(int receiverId, String receiverName, double defaultAmount) {
    final amountController = TextEditingController(text: defaultAmount.toStringAsFixed(2));
    final noteController = TextEditingController(text: 'Settled via UPI');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Settle with $receiverName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Payment Note',
                hintText: 'e.g. UPI, Cash, Bank transfer',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text);
              if (amt == null || amt <= 0) return;
              final expProv = Provider.of<ExpenseProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final dialogNav = Navigator.of(ctx);
              final success = await expProv.recordSettlement(
                roomId: widget.roomId,
                receiverId: receiverId,
                amount: amt,
                notes: noteController.text,
              );
              dialogNav.pop();
              if (!mounted) return;
              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Settlement of ₹$amt recorded!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm Settlement'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cat = AppConstants.getCategory(expense.category);
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (cat["color"] as Color).withAlpha(40),
                    child: Icon(cat["icon"] as IconData, color: cat["color"] as Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '${expense.category} • ${DateFormat('dd MMM yyyy').format(expense.expenseDate)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Paid by ${expense.paidBy.fullName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              if (expense.description != null && expense.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(expense.description!, style: TextStyle(color: Colors.grey[700])),
              ],
              const SizedBox(height: 16),
              const Text(
                'Split Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...expense.splits.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.user.fullName, style: const TextStyle(fontSize: 14)),
                        Text('₹${s.shareAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomProv = Provider.of<RoomProvider>(context);
    final expProv = Provider.of<ExpenseProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final room = roomProv.currentRoom;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room?.name ?? 'Room Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (room?.roomCode != null)
              Text('Room Code: ${room!.roomCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Invite Roommate',
            onPressed: _showInviteDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Expenses'),
            Tab(icon: Icon(Icons.calculate_rounded), text: 'Balances'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Roommates'),
          ],
        ),
      ),
      body: room == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: EXPENSES FEED
                _buildExpensesTab(expProv, theme),

                // TAB 2: BALANCES & CALCULATIONS
                _buildBalancesTab(expProv, auth.currentUser?.id, theme),

                // TAB 3: ROOMMATES & INVITES
                _buildRoommatesTab(room, theme),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(roomId: widget.roomId),
            ),
          );
          if (added == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildExpensesTab(ExpenseProvider expProv, ThemeData theme) {
    if (expProv.isLoading && expProv.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expProv.expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No expenses recorded yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Add Expense" below to record groceries, bills, or items bought for the flat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expProv.expenses.length,
        itemBuilder: (ctx, index) {
          final expense = expProv.expenses[index];
          final cat = AppConstants.getCategory(expense.category);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showExpenseDetails(expense),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (cat["color"] as Color).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat["icon"] as IconData, color: cat["color"] as Color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Paid by ${expense.paidBy.fullName} • ${DateFormat('dd MMM').format(expense.expenseDate)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Split with ${expense.splits.length} ${expense.splits.length == 1 ? 'person' : 'people'} (₹${(expense.amount / expense.splits.length).toStringAsFixed(1)} each)',
                              style: TextStyle(color: Colors.grey[700], fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalancesTab(ExpenseProvider expProv, int? currentUserId, ThemeData theme) {
    final summary = expProv.balanceSummary;
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Find current user balance
    final myBalance = summary.memberBalances.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => summary.memberBalances.first,
    );

    final isPositive = myBalance.netBalance >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall summary banner
              Card(
                elevation: 0,
                color: isPositive ? Colors.teal.shade50 : Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isPositive ? Colors.teal.shade300 : Colors.red.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isPositive ? Colors.teal.shade100 : Colors.red.shade100,
                        child: Icon(
                          isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isPositive ? Colors.teal.shade900 : Colors.red.shade900,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPositive ? 'You are owed' : 'You owe',
                              style: TextStyle(
                                fontSize: 13,
                                color: isPositive ? Colors.teal.shade900 : Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${myBalance.netBalance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.teal.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Spent', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          Text(
                            '₹${summary.totalRoomExpenses.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Who Owes Whom (Settlements Guide)
              Text(
                'Simplified Settlements (Who Owes Whom)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (summary.suggestedSettlements.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      const Text(
                        'All settled up! No pending debts in this room.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ...summary.suggestedSettlements.map((trans) {
                  final isMeOwing = trans.fromUser.id == currentUserId;
                  final isMeOwed = trans.toUser.id == currentUserId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: isMeOwing ? 'You' : trans.fromUser.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: ' owe(s) '),
                                  TextSpan(
                                    text: isMeOwed ? 'You' : trans.toUser.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            '₹${trans.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (isMeOwing) ...[
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => _showSettleUpDialog(
                                trans.toUser.id,
                                trans.toUser.fullName,
                                trans.amount,
                              ),
                              child: const Text('Settle'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Roommates Breakdown
              Text(
                'Per Roommate Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.memberBalances.map((mb) {
                final net = mb.netBalance;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(mb.user.fullName.isNotEmpty ? mb.user.fullName[0].toUpperCase() : 'U'),
                    ),
                    title: Text(mb.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Paid ₹${mb.totalPaid.toStringAsFixed(0)} • Share ₹${mb.totalShare.toStringAsFixed(0)}'),
                    trailing: Text(
                      '${net >= 0 ? '+' : ''}₹${net.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoommatesTab(dynamic room, ThemeData theme) {
    final memberships = room.memberships as List;
    final active = memberships.where((m) => m.status == 'ACCEPTED').toList();
    final pending = memberships.where((m) => m.status == 'PENDING').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withAlpha(75),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anyone you invite must accept the notification before expenses are divided with them.',
                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _showInviteDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Active Roommates (${active.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...active.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text(m.user.fullName[0].toUpperCase(), style: TextStyle(color: Colors.green.shade900)),
                      ),
                      title: Text(m.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('@${m.user.username} • ${m.user.email}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )),

              if (pending.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Pending Approvals (${pending.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...pending.map((m) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Text(m.user.fullName[0].toUpperCase(), style: TextStyle(color: Colors.amber.shade900)),
                        ),
                        title: Text(m.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${m.user.username} • Waiting for their approval'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: const Text('Pending', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
