import 'package:flutter/material.dart';
import 'add_plans.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/plan_dm.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Networking/subscription_api.dart';

class Plans extends StatefulWidget {
  const Plans({Key? key}) : super(key: key);

  @override
  _PlansState createState() => _PlansState();
}
class _PlansState extends State<Plans> {
  late PlanService planService;
  late Future<List<Plan>> plans;
  late gymUser.User user;
  bool userInitialized = false; // Track if user data is initialized
  late SubscriptionApi _subscriptionApi;
  bool _subscription = false;
  @override
  void initState() {
    super.initState();
    planService = PlanService(Supabase.instance.client);
    plans = planService.getPlans();
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);
    _fetchSubscription();
    _initializeUser();
  }
  Future<void> _fetchSubscription() async {
    try {
      final response = await _subscriptionApi.getActiveSubscription();
      setState(() {
        if (response["success"] == true) {
          _subscription = true;
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching plans: $error')),
      );
    }
  }
  Future<void> _initializeUser() async {
    user = (await gymUser.User.getUser()) ?? gymUser.User(id: '', name: '', email: '', membersLimit: 0, plansLimit: 0,razorPayKey: '');
    setState(() {
      userInitialized = true; // User data is now initialized
    });
  }

  Future<void> _deletePlan(Plan plan) async {
    final response = await planService.deletePlan(plan.id);
    if (response['success']) {
      setState(() {
        plans = planService.getPlans(); // Refresh the plans list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan deleted successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response['message']}')),
      );
    }
  }

  Future<void> _updatePlan(Plan plan) async {
    gymUser.User? user = await gymUser.User.getUser();
    String? id = user?.id ?? "";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlans(plan: plan),
      ),
    ).then((_) {
      setState(() {
        plans = planService.getPlans(); // Refresh the plans list
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Plan>>(
        future: plans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No plans found'));
          }

          final planList = snapshot.data!;

          return ListView.separated(
            itemCount: planList.length,
            itemBuilder: (context, index) {
              final plan = planList[index];
              return Container(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(
                      plan.planName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16),
                        SizedBox(width: 5),
                        Text('${plan.planLimit} Month'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_rupee, size: 16),
                        SizedBox(width: 2),
                        Text(plan.planPrice, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    onTap: () {
                      _updatePlan(plan);
                    },
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => Divider(),
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<Plan>>(
        future: plans,
        builder: (context, snapshot) {
          if (!userInitialized || !snapshot.hasData) {
            return SizedBox.shrink(); // Return an empty widget if user data or plans are not yet available
          }

          final planList = snapshot.data!;
          return (_subscription == true || user.plansLimit > planList.length)
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPlans()),
              ).then((_) {
                setState(() {
                  plans = planService.getPlans(); // Refresh the plans list
                });
              });
            },
            tooltip: 'Add',
            child: Icon(Icons.add),
          )
              : SizedBox.shrink(); // Return an empty widget if the button should not be displayed
        },
      ),
    );
  }
}