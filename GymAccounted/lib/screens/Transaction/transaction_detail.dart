import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRANSACTION DETAIL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Transaction Summary'),
                _buildDetailRow(
                  icon: Icons.currency_exchange,
                  label: 'Amount:',
                  value: '₹${transaction.amount.toStringAsFixed(2)}',
                  valueStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Member Details'),
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Name:',
                  value: transaction.memberName,
                ),
                _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Phone:',
                  value: transaction.memberPhone,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Plan Details'),
                _buildDetailRow(
                  icon: Icons.fitness_center,
                  label: 'Plan Name:',
                  value: transaction.planName.isEmpty
                      ? 'Not Assigned'
                      : transaction.planName,
                ),
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: transaction.planLimit.isEmpty ? 'Days:' : 'Limit in Month:',
                  value: transaction.planLimit.isEmpty
                      ? '${transaction.days} days'
                      : transaction.planLimit,
                ),
                _buildDetailRow(
                  icon: Icons.money_off,
                  label: 'Plan Amount:',
                  value: '₹${transaction.amount.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label $value',
              style: valueStyle ?? const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
