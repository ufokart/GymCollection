import 'package:flutter/material.dart';

class PremiumPopup extends StatelessWidget {
  final VoidCallback onBuyNow;
  final int currentMembers;
  final int currentPlans;
  final int memberLimit;
  final int planLimit;
  final bool subscription;
  final String? planName; // Add this field
  final String? purchaseDate; // Add this field
  final String? expireDate; // Add this field

  const PremiumPopup({
    Key? key,
    required this.onBuyNow,
    required this.currentMembers,
    required this.currentPlans,
    required this.memberLimit,
    required this.planLimit,
    required this.subscription,
    this.planName,
    this.purchaseDate,
    this.expireDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            subscription ? Icons.check_circle : Icons.lock,
            color: subscription ? Colors.green : Colors.orange,
            size: 30,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              subscription
                  ? 'Subscription Details'
                  : 'Unlock Premium Features',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subscription) ...[
              Text(
                'You have an active subscription:',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 10),
              Text(
                'Plan Name: ${planName ?? "N/A"}',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 10),
              Text(
                'Purchase Date: ${purchaseDate ?? "N/A"}',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 10),
              Text(
                'Expires on: ${expireDate ?? "N/A"}',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ] else ...[
              Text(
                'Currently, you have:',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Add up to $memberLimit members',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Create up to $planLimit plans',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Upgrade to Premium to unlock unlimited access!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close', style: TextStyle(color: Colors.grey)),
        ),
        if (!subscription)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBuyNow();
            },
            child: Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.orange,
            ),
          ),
      ],
    );
  }
}
