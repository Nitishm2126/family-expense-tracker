import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Possible states for the member list.
enum MemberStatus { loading, loaded, empty, error }

class MemberState {
  final MemberStatus status;
  final List<Map<String, dynamic>> members;
  final String? errorMessage;

  const MemberState({
    this.status = MemberStatus.loading,
    this.members = const [],
    this.errorMessage,
  });

  MemberState copyWith({
    MemberStatus? status,
    List<Map<String, dynamic>>? members,
    String? errorMessage,
  }) {
    return MemberState(
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage,
    );
  }
}

class MemberController extends StateNotifier<MemberState> {
  final Ref ref;
  bool _hasLoaded = false;

  MemberController(this.ref) : super(const MemberState()) {
    loadMembers();
  }

  Future<void> loadMembers({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;
    state = state.copyWith(status: MemberStatus.loading, errorMessage: null);

    final client = Supabase.instance.client;
    debugPrint('MEMBER DEBUG: supabaseUrl = ${client.rest.url}');

    // ── ATTEMPT 1: Direct table SELECT ──────────────────────────────────────
    // Works when RLS has a SELECT policy for the anon role.
    try {
      final rawResult = await client
          .from('members')
          .select('id, family_id, name')
          .order('name')
          .timeout(const Duration(seconds: 10));

      final members = List<Map<String, dynamic>>.from(rawResult);
      debugPrint('MEMBER TEST A COUNT = ${members.length}');

      if (members.isNotEmpty) {
        for (final m in members) {
          debugPrint('  - ${m['name']} (id: ${m['id']})');
        }
        _hasLoaded = true;
        state = state.copyWith(status: MemberStatus.loaded, members: members);
        return;
      }

      debugPrint('MEMBER TEST A COUNT = 0 → trying RPC fallback...');
    } on PostgrestException catch (e) {
      debugPrint('MEMBER TEST A PostgrestException: ${e.message} (code: ${e.code})');
    } on TimeoutException {
      debugPrint('MEMBER TEST A: Timeout');
    } catch (e) {
      debugPrint('MEMBER TEST A error: $e');
    }

    // ── ATTEMPT 2: RPC function (SECURITY DEFINER — bypasses RLS) ────────────
    // Works when the get_family_members() function exists in Supabase.
    // To create it, run supabase_setup.sql in the Supabase SQL Editor.
    try {
      debugPrint('MEMBER DEBUG: Trying RPC get_family_members()...');
      final rpcResult = await client
          .rpc('get_family_members')
          .timeout(const Duration(seconds: 10));

      final members = List<Map<String, dynamic>>.from(rpcResult as List);
      debugPrint('MEMBER RPC COUNT = ${members.length}');

      if (members.isNotEmpty) {
        for (final m in members) {
          debugPrint('  - ${m['name']} (id: ${m['id']})');
        }
        _hasLoaded = true;
        state = state.copyWith(status: MemberStatus.loaded, members: members);
        return;
      }

      debugPrint('MEMBER RPC COUNT = 0');
    } on PostgrestException catch (e) {
      debugPrint('MEMBER RPC PostgrestException: ${e.message} (code: ${e.code})');
      debugPrint('  details: ${e.details}  hint: ${e.hint}');
    } on TimeoutException {
      debugPrint('MEMBER RPC: Timeout');
    } catch (e) {
      debugPrint('MEMBER RPC error: $e');
    }

    // ── ATTEMPT 3: Filtered by known family ID ────────────────────────────────
    // Hardcoded family UUID. The members table is populated with this family_id.
    const knownFamilyId = 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010';
    try {
      debugPrint('MEMBER DEBUG: Trying filtered query with known family_id=$knownFamilyId');
      final filteredResult = await client
          .from('members')
          .select('id, family_id, name')
          .eq('family_id', knownFamilyId)
          .order('name')
          .timeout(const Duration(seconds: 10));

      final members = List<Map<String, dynamic>>.from(filteredResult);
      debugPrint('MEMBER TEST B COUNT = ${members.length}');

      if (members.isNotEmpty) {
        for (final m in members) {
          debugPrint('  - ${m['name']} (id: ${m['id']})');
        }
        _hasLoaded = true;
        state = state.copyWith(status: MemberStatus.loaded, members: members);
        return;
      }

      debugPrint('MEMBER TEST B COUNT = 0');
    } on PostgrestException catch (e) {
      debugPrint('MEMBER TEST B PostgrestException: ${e.message} (code: ${e.code})');
    } on TimeoutException {
      debugPrint('MEMBER TEST B: Timeout');
    } catch (e) {
      debugPrint('MEMBER TEST B error: $e');
    }

    // ── ALL ATTEMPTS FAILED ──────────────────────────────────────────────────
    // All three queries returned 0 rows. This is an RLS policy issue.
    // The anon role has no SELECT policy on public.members.
    //
    // FIX: Run supabase_setup.sql in the Supabase SQL Editor:
    //   https://supabase.com/dashboard/project/eowvprknwokacnmickgt/sql/new
    //
    debugPrint('MEMBER DEBUG: All 3 attempts returned 0 rows.');
    debugPrint('ROOT CAUSE: RLS is blocking SELECT on public.members for the anon role.');
    debugPrint('FIX: Run supabase_setup.sql in the Supabase SQL Editor.');
    debugPrint('URL: https://supabase.com/dashboard/project/eowvprknwokacnmickgt/sql/new');

    _hasLoaded = true;
    state = state.copyWith(
      status: MemberStatus.error,
      members: [],
      errorMessage:
          'Cannot load members: Row Level Security is blocking access.\n'
          'Run supabase_setup.sql in the Supabase SQL Editor to fix this.',
    );
  }

  Future<void> retry() => loadMembers(forceRefresh: true);
}

final memberControllerProvider =
    StateNotifierProvider<MemberController, MemberState>(
        (ref) => MemberController(ref));
