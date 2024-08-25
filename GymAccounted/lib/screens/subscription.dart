import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/subcription_dm.dart';
import 'package:gymaccounted/Networking/subscription_api.dart';
import 'package:gymaccounted/screens/checkout.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:intl/intl.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Subscription? _selectedPlan;
  late Future<List<Subscription>> _subscriptionsFuture;
  late SubscriptionApi _subscriptionApi;
  late gymUser.User user;

  bool isPaymentComplete = false;
  Razorpay _razorpay = Razorpay();
  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _subscriptionsFuture = SubscriptionApi(Supabase.instance.client).getSubscriptionList();
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);
    _initializeUser();
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }
  Future<void> _initializeUser() async {
    user = (await gymUser.User.getUser()) ?? gymUser.User(id: '', name: '', email: '', membersLimit: 0, plansLimit: 0, razorPayKey: '');
  }
  void _openRazorpay() async {
    var options = {
      'key': user.razorPayKey,
      'amount': int.parse(_selectedPlan?.price ?? "0") * 100,
      'name': 'Gym Collection',
      'description': 'Gym Collection',
      // 'prefill': {
      //   'contact': '8888888888',
      //   'email': 'test@razorpay.com'
      // }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _handlePaymentResponse(
      status: "1",
      paymentId: response.paymentId,
      failedReason: "",
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _handlePaymentResponse(
      status: "0",
      paymentId: "",
      failedReason: response.message,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _handlePaymentResponse(
      status: "1",
      paymentId: "",
      failedReason: response.walletName,
    );
  }

  void _handlePaymentResponse({
    required String? status,
    String? paymentId,
    String? failedReason,
  }) async {
    late String expiredDateString;
    late String todayDate;
    DateTime currentDate = DateTime.now();
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    todayDate = dateFormat.format(currentDate);
    if ((_selectedPlan?.id ?? 0) == 1) {
      // Add 1 month to the current date
      DateTime expiredDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      expiredDateString = dateFormat.format(expiredDate);
    } else if ((_selectedPlan?.id ?? 0) == 2) {
      // Add 6 months to the current date
      DateTime expiredDate = DateTime(currentDate.year, currentDate.month + 6, currentDate.day);
      expiredDateString = dateFormat.format(expiredDate);
    } else if ((_selectedPlan?.id ?? 0) == 3) {
      // Add 1 year to the current date
      DateTime expiredDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
      expiredDateString = dateFormat.format(expiredDate);
    }
    final result = await _subscriptionApi.insertSubscription(
      date: todayDate,
      status: status ?? '',
      failed_reason: failedReason ?? '',
      payment_id: paymentId ?? '',
      subscription_id: (_selectedPlan?.id ?? 0).toString(),
      name: _selectedPlan?.name ?? '',
      price: _selectedPlan?.price ?? '',
        expiredDate: expiredDateString,
    );
    if (result['success'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text( status == "1" ? 'Payment successfully.' : "Payment failed")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Subscription>>(
                future: _subscriptionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No subscription plans available.'));
                  } else {
                    List<Subscription> subscriptions = snapshot.data!;
                    return ListView.builder(
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        Subscription subscription = subscriptions[index];
                        return _buildPlanOption(
                          subscription.name,
                          '₹${subscription.price}',
                          '₹${subscription.actualPrice}',
                            subscription
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: ElevatedButton(
                onPressed: _selectedPlan != null ? _subscribe : null,
                child: Text('Buy Now'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(String title, String price, String actualPrice, Subscription subscription) {
    bool isSelected = _selectedPlan == subscription;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = subscription;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  actualPrice,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white70 : Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              'You Save: ₹${(double.parse(actualPrice.substring(1)) - double.parse(price.substring(1))).toStringAsFixed(2)}!',
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white70 : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe() {
    _openRazorpay();
  }
}
