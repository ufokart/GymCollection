import 'package:flutter/material.dart';
import 'package:gymaccounted/Modal/tranaction_dm.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';

class DashboardHeader extends StatelessWidget {
  final DashboardAmount amounts;

  const DashboardHeader({super.key, required this.amounts});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 6, // Adjust the shadow of the card
      margin: EdgeInsets.all(16), // Adjust the margin of the card
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(height: 10, width: 10),
              Padding(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.today,
                          size: 22,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: 5),
                        Text("Today",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.indigo,
                                fontWeight: FontWeight.normal))
                      ])),
              Padding(
                  padding: EdgeInsets.only(left: 5, top: 5),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 25,
                        ),
                        Text("${amounts.todayOnline + amounts.todayCash}",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ))
                      ])),
              SizedBox(height: 10, width: 50)
            ],
          ),
          Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 10),
                Padding(
                    padding: EdgeInsets.only(right: 10, top: 5),
                    child: Row(children: [
                      Text("Online:",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text("₹${amounts.todayOnline.toInt()}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold))
                    ])),
                Padding(
                    padding: EdgeInsets.only(right: 10, top: 10),
                    child: Row(children: [
                      Text("Cash:",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text("₹${amounts.todayCash.toInt()}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ])),
                SizedBox(height: 10),
              ])
        ],
      ),
    );
  }
}
