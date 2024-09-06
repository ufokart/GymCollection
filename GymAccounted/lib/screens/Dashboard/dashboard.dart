import 'package:flutter/material.dart';
import 'package:gymaccounted/screens/Alerts/SheetScreen.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard_members.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard_header.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard_today.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard_collection.dart'; // Corrected the name to match the widget
import 'package:gymaccounted/Networking/Apis.dart'; // Ensure GymService is implemented here
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
import 'package:gymaccounted/Networking/users_apis.dart';
import 'package:gymaccounted/screens/Members/members.dart';

class Dashboard extends StatefulWidget {
  final void Function(String cardType) onNavigateToMembers; // Update callback to accept a parameter
  final void Function(String cardType) onNavigateToToday; // Update callback to accept a parameter
  const Dashboard({
    Key? key,
    required this.onNavigateToMembers,
    required this.onNavigateToToday// Pass the callback here
  }) : super(key: key);
  @override
  DashboardState createState() => DashboardState(); // Corrected state class instantiation
}

class DashboardState extends State<Dashboard> {
  late GymService _gymService; // Ensure GymService is properly implemented
  late UserApiService _userApiService;
  late Future<List<dynamic>> allData;

  @override
  void initState() {
    super.initState();
    _userApiService = UserApiService(Supabase.instance.client);
    _gymService = GymService(Supabase.instance.client);
    allData = fetchAllData();
    _userApiService.getData();
  }

  Future<List<dynamic>> fetchAllData() async {
    final amounts = fetchAndCalculateAmounts();
    final membersCount = _gymService.getMembersCount();
    final membershipSummary = _gymService.getTodaysNewMembersAndDuePayments();
    return Future.wait([amounts, membersCount, membershipSummary]);
  }

  Future<DashboardAmount> fetchAndCalculateAmounts() async {
    try {
      List<Transaction> transactions = await _gymService.fetchTransactions();
      return _gymService.calculateAmounts(transactions);
    } catch (e) {
      print('Error fetching amount summary: $e');
      return DashboardAmount(
        todayCash: 0,
        todayOnline: 0,
        weekAmount: 0,
        monthAmount: 0,
        yearAmount: 0,
      );
    }
  }

  // Define the function that handles navigation to "MEMBERS"
  void _navigateToMembers(String value) {
    if (widget.onNavigateToMembers != null) {
      widget.onNavigateToMembers!(value); // Trigger the callback to HomeScreen
    }
  }

  // Define the function that handles navigation to "MEMBERS"
  void _onNavigateToToday(String value) {
    if (widget.onNavigateToToday != null) {
      widget.onNavigateToToday!(value); // Trigger the callback to HomeScreen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: allData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final amounts = snapshot.data![0] as DashboardAmount;
            final membersCount = snapshot.data![1] as DashboardMembersCounts;
            final membershipSummary = snapshot.data![2] as DashboardMembershipSummary;

            return SingleChildScrollView(
              child: Column(
                children: [
                  DashboardHeader( onCardTap: (cardType) {
                    _onNavigateToToday(cardType); // Example: Display the type of card tapped
                    // You can perform actions based on cardType, e.g., navigate to a detailed view
                  },amounts: amounts),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today’s Statistics",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DashboardTodayData(dashboardMembershipSummary: membershipSummary),
                  DashboardCollection(onCardTap: (cardType) {
                    _onNavigateToToday(cardType); // Example: Display the type of card tapped
                    // You can perform actions based on cardType, e.g., navigate to a detailed view
                  },amounts: amounts),
                  // Pass the _navigateToMembers function to onCardTap
                  DashboardMembers(
                    dashboardMembersCounts: membersCount,
                    onCardTap: (cardType) {
                      _navigateToMembers(cardType); // Example: Display the type of card tapped
                      // You can perform actions based on cardType, e.g., navigate to a detailed view
                    }
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
