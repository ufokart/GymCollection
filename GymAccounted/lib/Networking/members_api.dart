import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:intl/intl.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

class MemberService {
  final SupabaseClient supabaseClient;
  MemberService(this.supabaseClient);


  Future<List<Member>> getMembers() async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response = await supabaseClient
        .from('Members')
        .select(
        '*, Memberships(status, renew_plan, expired_date, discounted_amount, TnxId, membership_period, days), Plans(plan_limit), Transaction(amount_type)')
        .eq('gym_id', gymId)
        .order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data.map((json) {
      final membershipJson = json['Memberships'];
      final transaction = json['Transaction'];
      final amountType = transaction[0]['amount_type'];
      return Member.fromJson({
        ...json,
        'status': membershipJson['status'],
        'renew': membershipJson['renew_plan'],
        'expiredAt': membershipJson['expired_date'],
        'discountedAmount': membershipJson['discounted_amount'],
        'trxId': membershipJson['TnxId'],
        'days': membershipJson['days'],
        'membershipPeriod': membershipJson['membership_period'],
        'amount_type': amountType,
      });
    }).toList();
  }

  Future<Map<String, dynamic>> insertMember(
      {required String name,
        required String email,
        required String phone,
        required String address,
        required String gender,
        required String batch,
        required String joining_date,
        required String dob,
        required String gymId,
        required String image,
        required int planId}) async {
    try {
      final response = await supabaseClient.from('Members').insert({
        'name': name,
        'email': email,
        'phone_no': phone,
        'address': address,
        'gender': gender,
        'batch': batch,
        'joining_date': joining_date,
        'dob': dob,
        'gym_id': gymId,
        'image': image,
        'plan_id': planId.toInt()
      }).select();
      // Debug print to inspect the response
      print('Response: $response');

      if (response.isEmpty) {
        return {'success': false, 'message': 'No data returned'};
      }

      Member insertedMember = Member.fromJson(response[0]);
      return {'success': true, 'data': insertedMember};
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  //getMemberById


  Future<List<Member>> getMembersById(List<int> memberIds) async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    String orCondition = memberIds.map((id) => 'id.eq.$id').join(',');

    final response = await supabaseClient
        .from('Members')
        .select(
        '*, Memberships(status, renew_plan, expired_date, discounted_amount, TnxId, membership_period, days), Plans(plan_limit), Transaction(amount_type)')
        .eq('gym_id', gymId)
        .or(orCondition)
        .order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data.map((json) {
      final membershipJson = json['Memberships'];
      final transaction = json['Transaction'];
      final amountType = transaction[0]['amount_type'];
      return Member.fromJson({
        ...json,
        'status': membershipJson['status'],
        'renew': membershipJson['renew_plan'],
        'expiredAt': membershipJson['expired_date'],
        'discountedAmount': membershipJson['discounted_amount'],
        'trxId': membershipJson['TnxId'],
        'days': membershipJson['days'],
        'membershipPeriod': membershipJson['membership_period'],
        'amount_type': amountType,
      });
    }).toList();
  }


  Future<Map<String, dynamic>> getMemberByNameAndPhoneNo({
    required String name,
    required String phone,
  }) async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";
      // Fetching data from the Members table where either name matches, phone matches, or both
      final response = await supabaseClient
          .from('Members')
          .select()
          .eq('gym_id', gymId)
          .or('and(name.eq.$name,phone_no.eq.$phone),name.eq.$name,phone_no.eq.$phone') // Combined OR and AND conditions
          .limit(1)
          .select();
      // Check if the response contains data
      if (response == null || response.isEmpty) {
        // Error from the Supabase query
        return {'success': false};
      } else {
        // If a matching member exists
        return {'success': true, 'message': 'Member phone number or name already exists'};
      }
    } catch (e) {
      // Log and return the error message
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMember({
    required int id,
    required String name,
    required String address,
    required String email,
    required String phone,
    required String batch,
    required String gender,
    required String joiningDate,
    required String dob,
    required String gymId,
    required String image,
    required int planId,
  }) async {
    try {
      final response = await supabaseClient
          .from('Members') // Replace 'members' with your table name
          .update({
        'name': name,
        'address': address,
        'email': email,
        'phone_no': phone,
        'batch': batch,
        'gender': gender,
        'joining_date': joiningDate,
        'dob': dob,
        'gym_id': gymId,
        'image': image,
        'plan_id': planId,
      })
          .eq('id', id)
          .select(); // Update where id matches the member's ID

      print('Response: $response');
      if (response.isEmpty) {
        return {'success': false, 'message': 'No data returned'};
      }
      Member insertedMember = Member.fromJson(response[0]);
      return {'success': true, 'data': insertedMember};
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> renewMembership(Member member) async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response = await supabaseClient
        .from('Memberships')
        .update(member.toJson())
        .eq('member_id', member.id)
        .eq('gym_id', gymId);
    if (response.error != null) {
      throw response.error!;
    }
  }


  Future<Map<String, dynamic>> deleteMember(int id) async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response = await supabaseClient
        .from('Members')
        .delete()
        .eq('id', id)
        .eq('gym_id', gymId);
    return {'success': true, 'message': 'Membership updated successfully.'};
  }
}
// Future<List<Member>> getMembers() async {
//   // Fetch the current user's gym ID
//   final user = await gymUser.User.getUser();
//   final gymId = user?.id ?? "";
//
//   // Step 1: Fetch members from the Members table
//   final membersResponse = await supabaseClient
//       .from('Members')
//       .select('*')
//       .eq('gym_id', gymId);
//
//   final membersData = membersResponse as List<dynamic>;
//
//   // Step 2: Fetch memberships for the members
//   final memberIds = membersData.map((member) => member['id']).toList();
//
//   // Construct the `or` condition string for multiple member IDs
//   final orCondition = memberIds.map((id) => 'member_id.eq.$id').join(',');
//
//   final membershipsResponse = await supabaseClient
//       .from('Memberships')
//       .select('*')
//       .or(orCondition);  // Pass the constructed condition
//
//   final membershipsData = membershipsResponse as List<dynamic>;
//
//   // Step 3: Fetch plans for the members
//   final plansResponse = await supabaseClient
//       .from('Plans')
//       .select('*');
//
//   final plansData = plansResponse as List<dynamic>;
//
//   // Step 4: Combine the data
//   return membersData.map((memberJson) {
//     // Find the corresponding membership for the member
//     final membershipJson = membershipsData.firstWhere(
//           (membership) => membership['member_id'] == memberJson['id'],
//       orElse: () => {'status': null, 'renew_plan': null},
//     );
//
//     // Find the corresponding plan for the member's plan_id
//     final planJson = plansData.firstWhere(
//           (plan) => plan['id'] == memberJson['plan_id'],
//       orElse: () => {'plan_limit': null},
//     );
//
//     // Calculate future date
//     final joiningDate = DateTime.parse(memberJson['joining_date']);
//     final plansLimit = (planJson['plan_limit'] as num?)?.toInt() ?? 0; // Use 0 if plan_limit is null
//     final futureDate = DateTime(
//         joiningDate.year, joiningDate.month + plansLimit, joiningDate.day);
//     final formattedFutureDate = DateFormat('dd-MMMM-yyyy').format(futureDate);
//
//     return Member.fromJson({
//       ...memberJson,
//       'status': membershipJson['status'],
//       'renew': membershipJson['renew_plan'],
//       'expiredAt': formattedFutureDate,
//     });
//   }).toList();
// }

