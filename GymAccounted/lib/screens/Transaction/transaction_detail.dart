import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text(
          'TRANSACTION DETAIL',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: \₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Member Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Name: ${transaction.memberName}'),
            Text('Phone: ${transaction.memberPhone}'),
            SizedBox(height: 16),
            Text(
              'Plan Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Plan Name: ${transaction.planName}'),
            Text('Limit in Month: ${transaction.planLimit}'),
            Text('Plan Amount: \₹${transaction.amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
