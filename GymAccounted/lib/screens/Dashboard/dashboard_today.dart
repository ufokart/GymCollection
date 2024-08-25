import 'package:flutter/material.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';

class DashboardTodayData extends StatelessWidget {
  final DashboardMembershipSummary dashboardMembershipSummary;
  const DashboardTodayData({super.key, required this.dashboardMembershipSummary});
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var orientation = MediaQuery.of(context).orientation;

    final double itemHeight = 100;
    final double itemWidth =
        size.width / (orientation == Orientation.portrait ? 2 : 4);
    return Container(
      child: LayoutBuilder(
        builder: (context, constraints) {
          var crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
          return GridView.count(
            shrinkWrap: true,
            primary: false,
            crossAxisCount: crossAxisCount,
            childAspectRatio: (itemWidth / itemHeight),
            controller: ScrollController(keepScrollOffset: false),
            children: [
              DashboardCardDetailsVertical(
                topText: 'Admissions',
                bottomText: 'Today',
                lineColor: Colors.blue,
                count: dashboardMembershipSummary.todaysNewMembers,
                lineHeight: 50,
                lineWidth: 5,
                textSize: 14,
              ),
              DashboardCardDetailsVertical(
                topText: 'Renewed',
                bottomText: 'Today',
                lineColor: Colors.green,
                count: dashboardMembershipSummary.renewPayments,
                lineHeight: 50,
                lineWidth: 5,
                textSize: 14,
              ),
              DashboardCardDetailsVertical(
                topText: 'Due Paid',
                bottomText: 'Today',
                lineColor: Colors.red,
                count: dashboardMembershipSummary.duePayments,
                lineHeight: 50,
                lineWidth: 5,
                textSize: 14,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardCardDetailsVertical extends StatelessWidget {
  final String topText;
  final String bottomText;
  final Color lineColor;
  final int count;
  final double lineHeight;
  final double lineWidth;
  final double textSize;

  DashboardCardDetailsVertical({
    required this.topText,
    required this.bottomText,
    required this.lineColor,
    required this.count,
    required this.lineHeight,
    required this.lineWidth,
    required this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 12, // Adjust the shadow of the card
        margin: EdgeInsets.all(16), // Adjust the margin of the card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 15), // Adjust spacing between the line and text
                Container(
                  width: lineWidth,
                  height: lineHeight,
                  color: lineColor,
                ),
                SizedBox(width: 15),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            topText,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: textSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            bottomText,
                            style: TextStyle(fontSize: textSize),
                          ),
                        ],
                      ),
                      SizedBox(width: 5),
                      Text(
                        count.toString(),
                        style: TextStyle(
                            fontSize: textSize, fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        Icons.arrow_right_outlined,
                        size: 18,
                      )
                    ]) // Adjust spacing between the line and text
                ,
              ],
            ),
            color: Theme.of(context).cardColor));
  }
}
