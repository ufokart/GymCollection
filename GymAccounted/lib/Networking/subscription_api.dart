import 'package:gymaccounted/Modal/subcription_dm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Modal/purchased_plans_dm.dart';
class SubscriptionApi {
  final SupabaseClient _client;

  SubscriptionApi(this._client);

  Future<List<Subscription>> getSubscriptionList() async {
    final response = await _client.from('Subscription').select();

    if (response == null) {
      throw Exception('Failed to load subscriptions: ${response}');
    }

    final data = response as List<dynamic>;
    return data.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<Map<String, dynamic>> insertSubscription({
    required String date,
    required String status,
    required String failed_reason,
    required String payment_id,
    required String subscription_id,
    required String name,
    required String price,
    required String expiredDate}) async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";
      final response = await _client.from('Premium_Purchased').insert({
        'date': date,
        'status': status,
        'failed_reason': failed_reason,
        'payment_id': payment_id,
        'subscription_id': subscription_id,
        'gym_id': gymId,
        'name': name,
        'price': price,
        'expire_date': expiredDate
      }).select();
      // Debug print to inspect the response
      print('Response: $response');
      if (response == null) {
        return {'success': false, 'message': response};
      } else {
        return {'success': true, 'message': response};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }


  Future<PurchasedPlansDm?> fetchSubscriptionByGymIdAndStatus() async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response = await _client
        .from('Premium_Purchased')
        .select()
        .eq('status', '1')
        .eq('gym_id', gymId)
        .limit(1) // We only want a single result
        .single(); // Ensures that a single object is returned instead of a list
    if (response != null) {
      return PurchasedPlansDm.fromJson(response);
    } else {
      return null; // Return null if no subscription matches the criteria
    }
  }

  Future<Map<String, dynamic>> getActiveSubscription() async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";
      final response = await _client
          .from('Premium_Purchased')
          .select()
          .eq('status', "1")
          .eq('gym_id', gymId)
          .limit(1) // We only want a single result
          .single();
    if (response.isEmpty == true) {
        return {'success': false, 'message': response};
      } else {
        return {'success': true, 'message': response};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}