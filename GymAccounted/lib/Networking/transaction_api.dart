import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

class TransactionService {
  final SupabaseClient _client;
  TransactionService(this._client);

  Future<List<Transaction>> getTransactions() async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";
      final response = await _client
          .from('Transaction')
          .select()
          .eq('gym_id', gymId)
          .order('created_at', ascending: true);
      final data = response as List<dynamic>;
      return data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      print('Error: $e'); // Optionally log the error for debugging
      return [];
    }
  }

  Future<Map<String, dynamic>> insertTransaction(
      {required String gymId,
      required int planId,
      required String amount,
      required String amountType,
      required int memberId,
      required String date,
      required String planName,
      required String planLimit,
      required String memberName,
      required String memberPhone}) async {
    try {
      final response = await _client.from('Transaction').insert({
        'gym_id': gymId,
        'plan_id': planId,
        'amount': amount,
        'amount_type': amountType,
        'member_id': memberId,
        'date': date,
        'plan_name': planName,
        'plan_limit': planLimit,
        'member_name': memberName,
        'member_phone_no': memberPhone
      }).select();
      // Debug print to inspect the response
      print('Response: $response');
      if (response != null) {
        return {'success': true, 'data': response};
      } else {
        return {'success': false, 'message': 'Unknown error occurred'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateTransaction({
    required int planId,
    required String amount,
    required String amountType,
    required int memberId,
    required String date,
    required String planName,
    required String planLimit,
    required String memberName,
    required String memberPhone,
  }) async {
    try {
      final response = await _client
          .from('Transaction')
          .update({
            'plan_id': planId,
            'amount': amount,
            'amount_type': amountType,
            'date': date,
            'plan_name': planName,
            'plan_limit': planLimit,
            'member_name': memberName,
            'member_phone_no': memberPhone
          })
          .eq('member_id', memberId)
          .select();
      if (response != null) {
        return {'success': true, 'message': 'Membership updated successfully.'};
      } else {
        return {
          'success': false,
          'message': 'Failed to update membership: ${response}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
