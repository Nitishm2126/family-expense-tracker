import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _membersCache = [];
  List<Map<String, dynamic>> _categoriesCache = [];
  String? _familyId;

  Future<void> initializeCache() async {
    final members = await _client.from('members').select();
    _membersCache = List<Map<String, dynamic>>.from(members);

    final categories = await _client.from('categories').select();
    _categoriesCache = List<Map<String, dynamic>>.from(categories);

    final families = await _client.from('families').select().limit(1);
    if (families.isNotEmpty) {
      _familyId = families.first['id']?.toString();
    }
  }

  String? getMemberId(String name) {
    for (var m in _membersCache) {
      if (m['name'].toString().toLowerCase() == name.toLowerCase()) {
        return m['id'].toString();
      }
    }
    return null;
  }

  String? getCategoryId(String name) {
    for (var c in _categoriesCache) {
      if (c['name'].toString().toLowerCase() == name.toLowerCase()) {
        return c['id'].toString();
      }
    }
    return null;
  }

  // Master Data
  Future<List<Map<String, dynamic>>> getMembers() async {
    return await _client.from('members').select();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _client.from('categories').select();
  }

  Future<Map<String, dynamic>?> getFirstFamily() async {
    final response = await _client.from('families').select().limit(1);
    if (response.isNotEmpty) {
      return response.first;
    }
    return null;
  }

  // Expenses
  Future<List<Map<String, dynamic>>> getExpenses({
    String? from,
    String? to,
  }) async {
    var query = _client.from('expenses').select('''
      *,
      members:member_id(name),
      categories:category_id(name)
    ''');
    
    if (from != null) {
      query = query.gte('expense_date', from);
    }
    if (to != null) {
      query = query.lte('expense_date', to);
    }
    
    return await query.order('expense_date', ascending: false).order('expense_time', ascending: false);
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> expense) async {
    if (_familyId == null) await initializeCache();
    
    // Auto-resolve IDs if names were passed instead
    if (expense['member_id'] == null && expense['member'] != null) {
      expense['member_id'] = getMemberId(expense['member'].toString());
      expense.remove('member');
    }
    if (expense['category_id'] == null && expense['category'] != null) {
      expense['category_id'] = getCategoryId(expense['category'].toString());
      expense.remove('category');
    }
    expense['family_id'] = _familyId;

    final response = await _client.from('expenses').insert(expense).select().single();
    return response;
  }

  Future<void> updateExpense(String id, Map<String, dynamic> expense) async {
    if (_familyId == null) await initializeCache();

    if (expense['member_id'] == null && expense['member'] != null) {
      expense['member_id'] = getMemberId(expense['member'].toString());
      expense.remove('member');
    }
    if (expense['category_id'] == null && expense['category'] != null) {
      expense['category_id'] = getCategoryId(expense['category'].toString());
      expense.remove('category');
    }

    await _client.from('expenses').update(expense).eq('id', id);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // Incomes
  Future<List<Map<String, dynamic>>> getIncomes({
    String? from,
    String? to,
  }) async {
    var query = _client.from('incomes').select('''
      *
    ''');

    if (from != null) {
      query = query.gte('date', from);
    }
    if (to != null) {
      query = query.lte('date', to);
    }

    return await query.order('date', ascending: false);
  }

  Future<Map<String, dynamic>> addIncome(Map<String, dynamic> income) async {
    if (_familyId == null) await initializeCache();

    if (income['member_id'] == null && income['member'] != null) {
      income['member_id'] = getMemberId(income['member'].toString());
      income.remove('member');
    }
    income['family_id'] = _familyId;

    final response = await _client.from('incomes').insert(income).select().single();
    return response;
  }

  Future<void> updateIncome(String id, Map<String, dynamic> income) async {
    if (_familyId == null) await initializeCache();

    if (income['member_id'] == null && income['member'] != null) {
      income['member_id'] = getMemberId(income['member'].toString());
      income.remove('member');
    }

    await _client.from('incomes').update(income).eq('id', id);
  }

  Future<void> deleteIncome(String id) async {
    await _client.from('incomes').delete().eq('id', id);
  }

  // Budgets
  Future<List<Map<String, dynamic>>> getBudgets(String month) async {
    return await _client.from('budgets').select('''
      *,
      categories:category_id(name)
    ''').eq('month', month);
  }

  Future<void> setBudget(Map<String, dynamic> budget) async {
    // Upsert budget
    await _client.from('budgets').upsert(budget);
  }

  // Dashboards / Summaries
  Future<Map<String, dynamic>?> getDashboardSummary() async {
    final response = await _client.from('dashboard_summary').select().limit(1);
    if (response.isNotEmpty) return response.first;
    return null;
  }
  
  Future<List<Map<String, dynamic>>> getCategoryExpenseSummary() async {
    return await _client.from('category_expense_summary').select();
  }
  
  Future<List<Map<String, dynamic>>> getMemberExpenseSummary() async {
    return await _client.from('member_expense_summary').select();
  }
}
