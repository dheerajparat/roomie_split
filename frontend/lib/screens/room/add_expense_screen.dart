import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final int roomId;
  const AddExpenseScreen({super.key, required this.roomId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = "Groceries";
  DateTime _selectedDate = DateTime.now();
  int? _selectedPayerId;

  // Split options
  bool _splitAll = true;
  final Set<int> _selectedSplitUserIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final roomProv = Provider.of<RoomProvider>(context, listen: false);
      final room = roomProv.currentRoom;

      setState(() {
        _selectedPayerId = auth.currentUser?.id;
        if (room != null) {
          final activeMembers = room.memberships.where((m) => m.status == 'ACCEPTED').toList();
          for (var m in activeMembers) {
            _selectedSplitUserIds.add(m.userId);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_splitAll && _selectedSplitUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one roommate to split with'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final expProv = Provider.of<ExpenseProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await expProv.addExpense(
      roomId: widget.roomId,
      title: _titleController.text,
      amount: amount,
      category: _selectedCategory,
      expenseDate: _selectedDate,
      paidById: _selectedPayerId,
      splitUserIds: _splitAll ? null : _selectedSplitUserIds.toList(),
      description: _descController.text,
    );

    if (!mounted) return;
    if (success) {
      navigator.pop(true);
    } else if (expProv.errorMessage != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(expProv.errorMessage!), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProv = Provider.of<RoomProvider>(context);
    final room = roomProv.currentRoom;
    final activeMembers = room?.memberships.where((m) => m.status == 'ACCEPTED').toList() ?? [];
    final theme = Theme.of(context);

    // Calculate live share preview
    final double enteredAmount = double.tryParse(_amountController.text) ?? 0.0;
    final int splitCount = _splitAll ? activeMembers.length : _selectedSplitUserIds.length;
    final double perPersonShare = (splitCount > 0 && enteredAmount > 0) ? (enteredAmount / splitCount) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title / Item Name
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'What was bought? (Item / Title) *',
                      hintText: 'e.g. Milk & Eggs, WiFi Bill, Vegetables, Rice',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter what was bought' : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount & Date in Row
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Amount (₹) *',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter amount' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date Bought',
                              prefixIcon: const Icon(Icons.calendar_month_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
                  Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : (cat['color'] as Color),
                        ),
                        label: Text(cat['name'] as String),
                        onSelected: (_) => setState(() => _selectedCategory = cat['name'] as String),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Payer Selector (Who paid)
                  Text('Paid By', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedPayerId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: activeMembers.map((m) {
                      return DropdownMenuItem<int>(
                        value: m.userId,
                        child: Text('${m.user.fullName} (@${m.user.username})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPayerId = val),
                  ),
                  const SizedBox(height: 24),

                  // Split Options (Divide)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Split with Roommates',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    _splitAll ? 'Divided equally among all active members' : 'Custom selected members',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _splitAll,
                                onChanged: (val) {
                                  setState(() {
                                    _splitAll = val;
                                    if (_splitAll) {
                                      _selectedSplitUserIds.clear();
                                      for (var m in activeMembers) {
                                        _selectedSplitUserIds.add(m.userId);
                                      }
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          if (!_splitAll) ...[
                            Text(
                              'Select who shares this expense:',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ...activeMembers.map((m) {
                              final isChecked = _selectedSplitUserIds.contains(m.userId);
                              return CheckboxListTile(
                                value: isChecked,
                                title: Text(m.user.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text('@${m.user.username}'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedSplitUserIds.add(m.userId);
                                    } else {
                                      _selectedSplitUserIds.remove(m.userId);
                                    }
                                  });
                                },
                              );
                            }),
                            const SizedBox(height: 8),
                          ],

                          // Live share calculation badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calculate_outlined, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    splitCount > 0
                                        ? '₹${enteredAmount.toStringAsFixed(0)} ÷ $splitCount person(s) = ₹${perPersonShare.toStringAsFixed(2)} each'
                                        : 'Select at least 1 person',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional Notes
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Notes / Remarks (Optional)',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Record Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
