import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/expense.dart';
import '../models/balance.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  BalanceSummary? _balanceSummary;
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  BalanceSummary? get balanceSummary => _balanceSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExpenses(int roomId, {String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get(
        '/rooms/$roomId/expenses',
        queryParameters: category != null ? {'category': category} : null,
      );
      final list = response.data as List;
      _expenses = list.map((e) => Expense.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required int roomId,
    required String title,
    required double amount,
    required String category,
    required DateTime expenseDate,
    int? paidById,
    List<int>? splitUserIds,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'title': title.trim(),
        'amount': amount,
        'category': category,
        'expense_date': "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}",
      };
      if (paidById != null) data['paid_by_id'] = paidById;
      if (splitUserIds != null && splitUserIds.isNotEmpty) {
        data['split_user_ids'] = splitUserIds;
      }
      if (description != null && description.isNotEmpty) {
        data['description'] = description.trim();
      }

      final response = await ApiClient().dio.post(
        '/rooms/$roomId/expenses',
        data: data,
      );

      final newExpense = Expense.fromJson(response.data);
      _expenses.insert(0, newExpense);
      
      // Auto-refresh balances after adding expense
      await fetchBalances(roomId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int roomId, int expenseId) async {
    try {
      await ApiClient().dio.delete('/rooms/$roomId/expenses/$expenseId');
      _expenses.removeWhere((e) => e.id == expenseId);
      await fetchBalances(roomId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchBalances(int roomId) async {
    try {
      final response = await ApiClient().dio.get('/rooms/$roomId/balances');
      _balanceSummary = BalanceSummary.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> recordSettlement({
    required int roomId,
    required int receiverId,
    required double amount,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiClient().dio.post(
        '/rooms/$roomId/settle',
        data: {
          'receiver_id': receiverId,
          'amount': amount,
          'notes': notes ?? 'Debt settlement',
        },
      );
      // Refresh balances and expenses
      await fetchBalances(roomId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = ApiClient().getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
