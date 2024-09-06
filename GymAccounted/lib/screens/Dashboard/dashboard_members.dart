import 'package:flutter/material.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';

import 'package:flutter/material.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';

class DashboardMembers extends StatelessWidget {
  final DashboardMembersCounts dashboardMembersCounts;
  final void Function(String cardType) onCardTap; // Update callback to accept a parameter

  const DashboardMembers({
    Key? key,
    required this.dashboardMembersCounts,
    required this.onCardTap, // Pass the callback here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Members",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                InkWell(
                  onTap: () => onCardTap('all'), // Pass the card type or relevant data
                  child: HorizontalCards(
                    title: dashboardMembersCounts.totalCount.toString(),
                    subtitle: "Overall members",
                    iconColor: Colors.blue,
                    textColor: Colors.black,
                  ),
                ),
                InkWell(
                  onTap: () => onCardTap('active'),
                  child: HorizontalCards(
                    title: dashboardMembersCounts.activeCount.toString(),
                    subtitle: "Active Members",
                    iconColor: Colors.green,
                    textColor: Colors.black,
                  ),
                ),
                InkWell(
                  onTap: () => onCardTap('due'),
                  child: HorizontalCards(
                    title: dashboardMembersCounts.inactiveCount.toString(),
                    subtitle: "Due Members",
                    iconColor: Colors.red,
                    textColor: Colors.black,
                  ),
                ),
                InkWell(
                  onTap: () => onCardTap('renewed'),
                  child: HorizontalCards(
                    title: dashboardMembersCounts.newCount.toString(),
                    subtitle: "Renew Members",
                    iconColor: Colors.deepPurple,
                    textColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class HorizontalCards extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color textColor;
  final Color initialCardColor;

  HorizontalCards({
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.textColor,
    this.initialCardColor = Colors.grey,
  });

  @override
  _HorizontalCardsState createState() => _HorizontalCardsState();
}

class _HorizontalCardsState extends State<HorizontalCards> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150.0,
      margin: EdgeInsets.all(8.0),
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 4, // Adjust the shadow of the card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // Center content vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                // Changed to person icon for member representation
                size: 60,
                color: widget.iconColor, // Set icon color
              ),
              SizedBox(height: 8), // Space between icon and text
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                     // color: widget.textColor, // Set text color
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                     // color: widget.textColor, // Set subtitle color
                    ),
                    textAlign: TextAlign.center, // Center align subtitle text
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

