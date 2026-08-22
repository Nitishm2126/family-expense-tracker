import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _membersCache = [];
  List<Map<String, dynamic>> _categoriesCache = [];
  String? _familyId;

  // The known family UUID — used as fallback when RLS blocks the families table.
  static const String _knownFamilyId = 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010';

  Future<void> initializeCache() async {
    try {
      // Hardcode to the specific family ID as requested
      _familyId = _knownFamilyId;
      debugPrint('[SupabaseService] Using active family_id: $_familyId');

      // Load members — try filtered first, fall back to RPC.
      await _loadMembersCache();

      debugPrint('[CATEGORY DEBUG] Active family ID = $_familyId');
      debugPrint('[CATEGORY DEBUG] Loading categories...');
      debugPrint('[CATEGORY DEBUG] Category family ID = $_familyId');
      
      final categories = await _client
          .from('categories')
          .select()
          .eq('family_id', _familyId!);
      _categoriesCache = List<Map<String, dynamic>>.from(categories);

      debugPrint('[CATEGORY DEBUG] loaded categories count = ${_categoriesCache.length}');
      for (final row in _categoriesCache) {
        debugPrint('[CATEGORY DEBUG] ${row['name']} -> ${row['id']}');
      }

      debugPrint('[SupabaseService] Cache initialized: '
          '${_membersCache.length} members, '
          '${_categoriesCache.length} categories');
    } on PostgrestException catch (e) {
      debugPrint('[CATEGORY ERROR] PostgrestException: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      debugPrint('[CATEGORY ERROR] $e');
      // Still set the fallback family_id so expense inserts can proceed.
      _familyId ??= _knownFamilyId;
    }
  }

  Future<void> _loadMembersCache() async {
    // Attempt 1: direct table SELECT filtered by family.
    try {
      final result = await _client
          .from('members')
          .select('id, family_id, name')
          .eq('family_id', _familyId ?? _knownFamilyId)
          .order('name');
      _membersCache = List<Map<String, dynamic>>.from(result);
      if (_membersCache.isNotEmpty) {
        debugPrint(
            '[SupabaseService] Members loaded via table: ${_membersCache.length}');
        return;
      }
    } catch (e) {
      debugPrint('[SupabaseService] members table query failed: $e');
    }

    // Attempt 2: RPC function (SECURITY DEFINER — bypasses RLS).
    try {
      final rpcResult = await _client.rpc('get_family_members');
      _membersCache = List<Map<String, dynamic>>.from(rpcResult as List);
      if (_membersCache.isNotEmpty) {
        debugPrint(
            '[SupabaseService] Members loaded via RPC: ${_membersCache.length}');
        return;
      }
    } catch (e) {
      debugPrint('[SupabaseService] get_family_members RPC failed: $e');
    }

    debugPrint(
        '[SupabaseService] WARNING: Members cache is empty after all attempts.');
  }

  /// Ensure cache is populated. Called lazily before operations that need IDs.
  Future<void> _ensureCacheReady() async {
    if (_familyId == null || _membersCache.isEmpty) {
      await initializeCache();
    }
  }

  String? get activeFamilyId => _familyId;

  String? getMemberId(String name) {
    for (var m in _membersCache) {
      if (m['name'].toString().toLowerCase() == name.toLowerCase()) {
        return m['id'].toString();
      }
    }
    return null;
  }

  String? getCategoryId(String name) {
    debugPrint('[CATEGORY DEBUG] Resolving category: "$name"');
    debugPrint('[CATEGORY DEBUG] Cache size: ${_categoriesCache.length}');
    for (var c in _categoriesCache) {
      debugPrint('[CATEGORY DEBUG] Cache item: ${c['name']} -> ${c['id']}');
    }
    
    final searchName = name.trim().toLowerCase();
    for (var c in _categoriesCache) {
      if (c['name'].toString().trim().toLowerCase() == searchName) {
        final id = c['id'].toString();
        debugPrint('[CATEGORY DEBUG] $name resolved to: $id');
        return id;
      }
    }
    debugPrint('[CATEGORY DEBUG] FAILED to resolve $name');
    return null;
  }

  // Master Data

  /// Returns all members for the active family, ordered by name.
  /// Returns members for the active family.
  /// Cache is already populated by initializeCache() / _loadMembersCache().
  Future<List<Map<String, dynamic>>> getMembers() async {
    // Ensure cache is ready (triggers initializeCache which calls _loadMembersCache).
    await _ensureCacheReady();

    if (_membersCache.isNotEmpty) {
      return _membersCache;
    }

    // Cache still empty after init — try once more directly.
    await _loadMembersCache();
    return _membersCache;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _client
        .from('categories')
        .select()
        .eq('family_id', _familyId ?? _knownFamilyId);
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

    return await query
        .order('expense_date', ascending: false)
        .order('expense_time', ascending: false);
  }

  Future<Map<String, dynamic>> addExpense(Map<String, dynamic> expense) async {
    await _ensureCacheReady();

    // Auto-resolve IDs if names were passed instead
    if (expense.containsKey('member')) {
      final memberName = expense['member'].toString();
      final mId = getMemberId(memberName);
      if (mId != null) {
        expense['member_id'] = mId;
      } else {
        throw Exception("Member '$memberName' could not be resolved to a member ID.");
      }
      expense.remove('member');
    }
    if (expense.containsKey('category')) {
      final categoryName = expense['category'].toString();
      final cId = getCategoryId(categoryName);
      if (cId != null) {
        expense['category_id'] = cId;
      } else {
        throw Exception("Category '$categoryName' could not be resolved to a category ID.");
      }
      expense.remove('category');
    }

    // Set family_id from cache
    expense['family_id'] = _familyId;

    // Remove fields that don't exist in the DB schema
    expense.remove('member');
    expense.remove('category');

    // Let Supabase generate the UUID — remove the client-side generated id
    expense.remove('id');
    // Also remove fields the DB doesn't have
    expense.remove('remarks');

    // Debug: print the COMPLETE map being sent (all keys + values)
    debugPrint('[SupabaseService] addExpense FULL MAP keys: ${expense.keys.toList()}');
    debugPrint('[SupabaseService] addExpense FULL MAP: $expense');

    try {
      final response =
          await _client.from('expenses').insert(expense).select().single();
      debugPrint(
          '[SupabaseService] Expense saved successfully: ${response['id']}');
      return response;
    } on PostgrestException catch (e) {
      debugPrint('[SupabaseService] PostgrestException:');
      debugPrint('  message: ${e.message}');
      debugPrint('  code: ${e.code}');
      debugPrint('  details: ${e.details}');
      debugPrint('  hint: ${e.hint}');
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Map<String, dynamic> expense) async {
    await _ensureCacheReady();

    if (expense.containsKey('member')) {
      final memberName = expense['member'].toString();
      final mId = getMemberId(memberName);
      if (mId != null) {
        expense['member_id'] = mId;
      } else {
        throw Exception("Member '$memberName' could not be resolved to a member ID.");
      }
      expense.remove('member');
    }
    if (expense.containsKey('category')) {
      final categoryName = expense['category'].toString();
      final cId = getCategoryId(categoryName);
      if (cId != null) {
        expense['category_id'] = cId;
      } else {
        throw Exception("Category '$categoryName' could not be resolved to a category ID.");
      }
      expense.remove('category');
    }

    // Remove fields that don't exist in the DB
    expense.remove('member');
    expense.remove('category');
    expense.remove('remarks');
    expense.remove('id');

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
    await _ensureCacheReady();

    if (income.containsKey('member')) {
      final mId = getMemberId(income['member'].toString());
      if (mId != null) income['member_id'] = mId;
      income.remove('member');
    }
    income['family_id'] = _familyId;

    final response =
        await _client.from('incomes').insert(income).select().single();
    return response;
  }

  Future<void> updateIncome(String id, Map<String, dynamic> income) async {
    await _ensureCacheReady();

    if (income.containsKey('member')) {
      final mId = getMemberId(income['member'].toString());
      if (mId != null) income['member_id'] = mId;
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
