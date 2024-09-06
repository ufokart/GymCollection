import 'package:flutter/material.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard.dart';
import 'Members/members.dart';
import 'Plans/plans.dart';
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:gymaccounted/Modal/gym_dm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/screens/adduser-screen.dart';
import 'package:gymaccounted/screens/Setting.dart';
import 'package:gymaccounted/screens/Login/loginscreen.dart';
import 'package:gymaccounted/screens/Transaction/tansaction.dart';
import 'dart:convert';
import 'package:gymaccounted/screens/subscription.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/screens/Alerts/premium_popup.dart';
import 'package:gymaccounted/Networking/subscription_api.dart';
import 'package:gymaccounted/Networking/membership_api.dart';
import 'package:gymaccounted/Modal/purchased_plans_dm.dart';
class HomeScreen extends StatefulWidget {

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late GymService _gymService;
  String _memberType = 'all';
  String _transactionType = 'all';
  Future<Gym?>? gymFuture;
  late gymUser.User user;
  bool userInitialized = false; //
  late SubscriptionApi _subscriptionApi;
  late MembershipService _membershipService;
  PurchasedPlansDm? activePlan;
  late List<Widget> _widgetOptions;

  bool _subscription = false;
  static const List<String> _pageTitle = <String>[
    "HOME",
    "MEMBERS",
    "PLANS",
    "TRANSACTIONS",
  ];

  void _onNavigateToMembers() {
    setState(() {
      // Update the index or any other logic you have for navigation
      _widgetOptions = _buildWidgetOptions(); // Rebuild options on navigation
      _selectedIndex = 1; // Set the index to the "Members" tab
    });
  }

  void _onNavigateToToday() {
    setState(() {
      // Update the index or any other logic you have for navigation
      _widgetOptions = _buildWidgetOptions(); // Rebuild options on navigation
      _selectedIndex = 3; // Set the index to the "Members" tab
    });
  }
  // static const List<Widget> _widgetOptions = <Widget>[
  //   Dashboard(onNavigateToMembers: _onNavigateToMembers),
  //   Members(),
  //   Plans(),
  //   TransactionScreen(),
  // ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _updateDueMembers();
      _fetchSubscription();
    });
  }



  Future<bool> _onWillPop() async {
    // Show a dialog or perform any other action when the back button is pressed
    return false; // Returning false prevents the navigation
  }
  @override
  void initState() {
    super.initState();
    _gymService = GymService(Supabase.instance.client);
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);
    _membershipService = MembershipService(Supabase.instance.client);
    gymFuture = _gymService.getGym(); // Fetch initial gym data
    _initializeUser();
    _fetchSubscription();
    _updateDueMembers();
    _widgetOptions = _buildWidgetOptions(); // Initialize options with a method
  }
  List<Widget> _buildWidgetOptions() {
    return [
      Dashboard(onNavigateToMembers: (cardType) {
        setState(() {
          _memberType = cardType; // Update member type when navigating
          _onNavigateToMembers(); // Rebuild the widget list
        });
      },onNavigateToToday: (cardType) {
    setState(() {
      _transactionType = cardType;
      _onNavigateToToday(); // Rebuild the widget list
    });
    }),
      Members(memberType: _memberType), // This now always gets the updated type
      Plans(),
      TransactionScreen(transactionType: _transactionType),
    ];
  }
  Future<void> _initializeUser() async {
    user = (await gymUser.User.getUser()) ?? gymUser.User(id: '', name: '', email: '', membersLimit: 0, plansLimit: 0, razorPayKey: '');
    setState(() {
      userInitialized = true; // User data is now initialized
    });
  }

  // Future<void> _fetchPremiumPlan() async {
  //   try {
  //     final response = await _subscriptionApi.fetchSubscriptionByGymIdAndStatus();
  //     setState(() {
  //       if (response["success"] == true) {
  //         //_subscription = true;
  //       }
  //     });
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error fetching plans: $error')),
  //     );
  //   }
  // }

  Future<void> _fetchSubscription() async {
    try {
      activePlan = await _subscriptionApi.fetchSubscriptionByGymIdAndStatus();
      setState(() {
        if (activePlan != null) {
           _subscription = true;
        }
      });
    } catch (error) {
    //  ScaffoldMessenger.of(context).showSnackBar(
       // SnackBar(content: Text('Error fetching plans: $error')),
     // );
    }
  }
  Future<void> _updateDueMembers() async {
    try {
       await _membershipService.updateDueMemberships();
      setState(() {
      });
    } catch (error) {
      //  ScaffoldMessenger.of(context).showSnackBar(
      // SnackBar(content: Text('Error fetching plans: $error')),
      // );
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchGymData(); // Fetch gym data when dependencies change
  }

  Image imageFromBase64String(String base64String) {
    final bytes = base64Decode(base64String);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
    );
  }

  void _fetchGymData() {
    setState(() {
      gymFuture = _gymService.getGym(); // Fetch gym data
    });
  }

  Future<void> _logout(BuildContext context) async {
    await gymUser.User.clearUser();
    // Navigate to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showPremiumPopup(BuildContext context) {
    if (userInitialized) {
      showDialog(
        context: context,
        builder: (context) {
          return PremiumPopup(
            onBuyNow:_subscribe,
            currentMembers: user.membersLimit, // Replace with the actual member count
            currentPlans: user.plansLimit, // Replace with the actual plan count
            memberLimit: user.membersLimit,
            planLimit: user.plansLimit,
            subscription: _subscription,
            planName: activePlan?.name ?? '',
            purchaseDate: activePlan?.date ?? '',
            expireDate: activePlan?.expireDate ?? '',
          );
        },
      );
    }
  }
  void _subscribe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPage(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle[_selectedIndex],
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: _selectedIndex == 0
            ? [
          IconButton(
            icon: Icon(Icons.workspace_premium, color: (_subscription  == true) ? Colors.green : Colors.amber),
            iconSize: 35,
            onPressed: () => _showPremiumPopup(context),
          ),
        ]
            : null,
      ),
      drawer: Drawer(
        child: FutureBuilder<Gym?>(
          future: gymFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No gym data found'));
            }

            final gym = snapshot.data!;

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: gym.image != null
                            ? imageFromBase64String(gym.image!).image
                            : null, // Use default if Base64 is null
                        radius: 30,
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gym.name,
                                  // Replace with actual name from gym data
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  // Adds ellipsis (...) when text overflows
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddUserScreen(gym: gym),
                                ),
                              ).then((_) => _fetchGymData());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(0);
                    _fetchGymData(); // Fetch gym data when going to Home
                  },
                ),
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Members'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(1);
                    _fetchGymData(); // Fetch gym data when going to Members
                  },
                ),
                ListTile(
                  leading: Icon(Icons.list),
                  title: Text('Plan'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(2);
                    _fetchGymData(); // Fetch gym data when going to Plans
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.subscriptions),
                  title: Text('Subscription'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionPage(),
                      ),
                    ); //// Fetch gym data when going to Plans
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Setting'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ),
                    ); // Fetch gym data when going to Plans
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Logout'),
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Transactions',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black, // Color for the selected item icon
        unselectedItemColor: Colors.grey, // Color for unselected items
        selectedLabelStyle: TextStyle(color: Colors.black), // Color for selected label
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        onTap: _onItemTapped,
      ),
    ),
    );
  }
}
