import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymaccounted/Networking/transaction_api.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/screens/Transaction/transaction_detail.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Transaction> transactions = [];
  List<Transaction> filteredTransactions = [];
  String filter = 'All';
  double totalAmount = 0.0;
  double filteredTotalAmount = 0.0;
  late TransactionService _transactionService;
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService(Supabase.instance.client);
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true; // Show loader
    });

    transactions = await _transactionService.getTransactions();
    totalAmount = transactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    _applyFilter();
    setState(() {
      isLoading = false; // Hide loader
    });
  }

  void _applyFilter() {
    List<Transaction> tempFilteredTransactions;

    if (filter == 'Today') {
      final today = DateTime.now();
      tempFilteredTransactions = transactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction.date);
        return transactionDate.year == today.year &&
            transactionDate.month == today.month &&
            transactionDate.day == today.day;
      }).toList();
    } else if (filter == 'This Month') {
      final now = DateTime.now();
      tempFilteredTransactions = transactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction.date);
        return transactionDate.year == now.year &&
            transactionDate.month == now.month;
      }).toList();
    } else {
      tempFilteredTransactions = transactions;
    }

    setState(() {
      filteredTransactions = tempFilteredTransactions;
      filteredTotalAmount = filteredTransactions.fold(
          0.0, (sum, transaction) => sum + transaction.amount);
    });
  }

  void _navigateToDetailScreen(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader
          : Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                ChoiceChip(
                  label: Text('All'),
                  selected: filter == 'All',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        filter = 'All';
                        _applyFilter();
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text('This Month'),
                  selected: filter == 'This Month',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        filter = 'This Month';
                        _applyFilter();
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text('Today'),
                  selected: filter == 'Today',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        filter = 'Today';
                        _applyFilter();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Total amount
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Total: \₹${filteredTotalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
              child: Text('No transactions found.'),
            ) // Show no transactions message
                : ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      transaction.amountType == 'Cash'
                          ? Colors.green
                          : Colors.blue,
                      child: Icon(
                        transaction.amountType == 'Cash'
                            ? Icons.money
                            : Icons.credit_card,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '\₹${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.amountType),
                        Text(
                          DateFormat('yyyy-MM-dd').format(
                              DateTime.parse(transaction.date)),
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () =>
                        _navigateToDetailScreen(transaction),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
