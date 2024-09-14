import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Modal/gym_dm.dart';
import 'package:intl/intl.dart'; // Ensure you have this package imported

class GymService {
  final SupabaseClient _client;

  GymService(this._client);

  Future<DashboardMembershipSummary> getTodaysNewMembersAndDuePayments() async {
    final supabase = Supabase.instance.client;
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";

    // Get the start and end of today in ISO format without time part
    final DateTime now = DateTime.now();
    final String todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final String todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    try {
      // Get today's new members
      final todaysNewMembersResponse = await supabase
          .from('Memberships')
          .select()
          .eq('gym_id', gymId)
          .gte('created_at', todayStart)
          .lte('created_at', todayEnd)
          .eq('status', 1);

      // Parse today's new members count

      // Get due payments (assuming due payments are those with status 0)
      final String formattedToday = DateFormat('dd-MMMM-yyyy').format(DateTime.now());
      final duePaymentsResponse = await supabase
          .from('Memberships')
          .select()
          .eq('gym_id', gymId)
           .eq('expired_date', formattedToday)
          .eq('status', 0); // Assuming due payments are for active memberships

      // Get renew payments (assuming renew_plan is true)
      final renewPaymentsResponse = await supabase
          .from('Memberships')
          .select()
          .eq('gym_id', gymId)
          .gte('created_at', todayStart)
          .lte('created_at', todayEnd)
          .eq('status', 2); // Assuming renew payments are for renewed memberships

      // Return the result as a DashboardMembershipSummary object
      return DashboardMembershipSummary(
        todaysNewMembers: todaysNewMembersResponse,
        duePayments: duePaymentsResponse,
        renewPayments: renewPaymentsResponse,
      );
    } catch (e) {
      // Handle any errors that occur during the database queries
      debugPrint('Error fetching dashboard summary: $e');
      return DashboardMembershipSummary(
        todaysNewMembers: [],
        duePayments: [],
        renewPayments: [],
      );
    }
  }


  Future<List<Transaction>> fetchTransactions() async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response =
        await _client.from('Transaction').select().eq('gym_id', gymId);

    if (response == null) {
      throw Exception('Failed to load transactions');
    }

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  // DashboardAmount calculateAmounts(List<Transaction> transactions) {
  //   int todayCash = 0;
  //   int todayOnline = 0;
  //   int weekAmount = 0;
  //   int monthAmount = 0;
  //   int yearAmount = 0;
  //
  //   DateTime now = DateTime.now();
  //   DateTime today = DateTime(now.year, now.month, now.day);
  //   DateTime startOfWeek = now.subtract(Duration(days: today.weekday - 1));
  //   startOfWeek =
  //       DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  //   DateTime startOfMonth = DateTime(today.year, today.month, 1);
  //   DateTime startOfYear = DateTime(today.year, 1, 1);
  //
  //   for (var transaction in transactions) {
  //     DateTime transactionDate = DateTime.parse(transaction.date);
  //     int amount = transaction.amount;
  //     String amountType = transaction.amountType;
  //
  //     if (transactionDate.isAfter(startOfYear) ||
  //         transactionDate.isAtSameMomentAs(startOfYear)) {
  //       yearAmount += amount;
  //       if (transactionDate.isAfter(startOfMonth) ||
  //           transactionDate.isAtSameMomentAs(startOfMonth)) {
  //         monthAmount += amount;
  //         if (transactionDate.isAfter(startOfWeek) ||
  //             transactionDate.isAtSameMomentAs(startOfWeek)) {
  //           weekAmount += amount;
  //           if (transactionDate.year == today.year &&
  //               transactionDate.month == today.month &&
  //               transactionDate.day == today.day) {
  //             if (amountType == 'Cash') {
  //               todayCash += amount;
  //             } else if (amountType == 'Online') {
  //               todayOnline += amount;
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  //
  //   return DashboardAmount(
  //     todayCash: todayCash,
  //     todayOnline: todayOnline,
  //     weekAmount: weekAmount,
  //     monthAmount: monthAmount,
  //     yearAmount: yearAmount,
  //   );
  // }

  DashboardAmount calculateAmounts(List<Transaction> transactions) {
    int todayCash = 0;
    int todayOnline = 0;
    int weekAmount = 0;
    int monthAmount = 0;
    int yearAmount = 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
    endOfWeek = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

    DateTime startOfMonth = DateTime(today.year, today.month, 1);
    DateTime endOfMonth = (today.month < 12)
        ? DateTime(today.year, today.month + 1, 0, 23, 59, 59)
        : DateTime(today.year + 1, 1, 0, 23, 59, 59);

    DateTime startOfYear = DateTime(today.year, 1, 1);
    DateTime endOfYear = DateTime(today.year, 12, 31, 23, 59, 59);

    for (var transaction in transactions) {
      DateTime transactionDate = transaction.createdAt;//DateTime.parse(transaction.date);
      transactionDate = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
      int amount = transaction.amount;
      String amountType = transaction.amountType;

      // Debugging prints
      print('Transaction Date: $transactionDate');
      print('Start of Week: $startOfWeek');
      print('End of Week: $endOfWeek');
      print('Start of Month: $startOfMonth');
      print('End of Month: $endOfMonth');
      print('Start of Year: $startOfYear');
      print('End of Year: $endOfYear');

      // Check for transactions in the current year
      if ((transactionDate.isAfter(startOfYear) || transactionDate.isAtSameMomentAs(startOfYear)) &&
    (transactionDate.isBefore(endOfYear) || transactionDate.isAtSameMomentAs(endOfYear))) {

        yearAmount += amount;

        // Check for transactions in the current month
        if ((transactionDate.isAfter(startOfMonth) || transactionDate.isAtSameMomentAs(startOfMonth)) &&
            (transactionDate.isBefore(endOfMonth) || transactionDate.isAtSameMomentAs(endOfMonth))) {
          monthAmount += amount;

          // Check for transactions in the current week
          if ((transactionDate.isAfter(startOfWeek) || transactionDate.isAtSameMomentAs(startOfWeek)) &&
              (transactionDate.isBefore(endOfWeek) || transactionDate.isAtSameMomentAs(endOfWeek))) {
            weekAmount += amount;

            // Check for transactions today
            if (transactionDate.isAtSameMomentAs(today)) {
              if (amountType == 'Cash') {
                todayCash += amount;
              } else if (amountType == 'Online') {
                todayOnline += amount;
              }
            }
          }
        }
      }
    }

    return DashboardAmount(
      todayCash: todayCash,
      todayOnline: todayOnline,
      weekAmount: weekAmount,
      monthAmount: monthAmount,
      yearAmount: yearAmount,
    );
  }

  Future<DashboardMembersCounts> getMembersCount() async {
    final supabase = Supabase.instance.client;
    final user = await gymUser.User.getUser();
    // Handle the case where user might be null
    final gymId = user?.id ?? "";
    // Get overall member count
    final totalCountResponse =
        await supabase.from('Memberships').select().eq('gym_id', gymId).count();
    final totalCount = totalCountResponse.count ?? 0;

    // Get active member count (status = 1)
    final activeCountResponse = await supabase
        .from('Memberships')
        .select()
        .eq('gym_id', gymId)
        .eq('status', 1)
        .count();
    final activeCount = activeCountResponse.count ?? 0;
    // Get inactive member count (status = 0)
    final inactiveCountResponse = await supabase
        .from('Memberships')
        .select()
        .eq('gym_id', gymId)
        .eq('status', 0)
        .count();
    final inactiveCount = inactiveCountResponse.count ?? 0;

    final reNewCountResponse = await supabase
        .from('Memberships')
        .select()
        .eq('gym_id', gymId)
        .eq('status', 2)
        .count();
    final reNewCount = reNewCountResponse.count ?? 0;

    final counts = DashboardMembersCounts(
      totalCount: totalCount,
      activeCount: activeCount,
      inactiveCount: inactiveCount,
        newCount: reNewCount
    );

    print(counts);

    return counts;
  }

  Future<Gym?> getGym() async {
    try {
      final user = await gymUser.User.getUser();
      final userId = user?.id ?? "";
      final response =
          await _client.from('Gym').select().eq('user_id', userId).single();
      if (response != null) {
        return Gym.fromJson(response);
      } else {
        print('No gym found for the provided user_id');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> insertGym(
      {required String name,
      required String address,
      required String email,
      required String phoneNo,
      required String uid,
      required String image}) async {
    try {
      final response = await _client.from('Gym').insert({
        'user_id': uid,
        'name': name,
        'address': address,
        'email': email,
        'phone_no': phoneNo,
        'active': true,
        'image': image
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

  Future<Map<String, dynamic>> updateGym(
      {required int id,
      required String name,
      required String address,
      required String email,
      required String phoneNo,
      required String image}) async {
    try {
      final response = await _client
          .from('Gym')
          .update({
            'name': name,
            'address': address,
            'email': email,
            'phone_no': phoneNo,
            'image': image,
          })
          .eq('id', id)
          .select();
      if (response.isEmpty) {
        return {'success': false, 'message': "gym update failed"};
      } else {
        return {'success': true, 'data': response};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
