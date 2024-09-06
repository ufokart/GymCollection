import 'package:flutter/material.dart';
import 'package:gymaccounted/Modal/dahboard_dm.dart';
class CollectionCardDetailsVertical extends StatelessWidget {
  final String topText;
  final String bottomText;
  final Color lineColor;
  final double lineHeight;
  final double lineWidth;
  final double textSize;

  CollectionCardDetailsVertical({
    required this.topText,
    required this.bottomText,
    required this.lineColor,
    required this.lineHeight,
    required this.lineWidth,
    required this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      margin: EdgeInsets.all(8), // Adjusted margin for better fit
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Reduced corner radius
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        // Added padding for better spacing
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: lineWidth,
              height: lineHeight,
              color: lineColor,
            ),
            SizedBox(width: 12), // Adjusted spacing between the line and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    topText,
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                  Text(
                    bottomText,
                    style: TextStyle(fontSize: textSize),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            // Removed the "54" and arrow icon as per request
          ],
        ),
        color:Theme.of(context).cardColor,
      ),
    );
  }
}
class DashboardCollection extends StatelessWidget {
  final DashboardAmount amounts;
  final void Function(String cardType) onCardTap;
  const DashboardCollection({
    Key? key,
    required this.amounts,
    required this.onCardTap, // Pass the callback here
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjusted padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Collections", // Header text for the collections section
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Removed extra SizedBox height to reduce space
      Container(
        margin: const EdgeInsets.only(top: 8.0), // Margin for space between header and items
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns in the grid
            childAspectRatio: 2, // Adjusted to fit your card's aspect ratio
            crossAxisSpacing: 16, // Space between columns
            mainAxisSpacing: 16, // Space between rows
          ),
          itemCount: 3, // Number of items
          shrinkWrap: true, // To fit the height of the container
          physics: NeverScrollableScrollPhysics(), // To prevent scrolling within the grid
          itemBuilder: (context, index) {
            // Function to handle tap on each card
            void handleCardTap(String period) {
              // Perform your desired action here, like navigating or showing a message
              onCardTap(period);
            }

            // Return the card wrapped with GestureDetector to make it tappable
            if (index == 0) {
              return GestureDetector(
                onTap: () => handleCardTap('Yearly'),
                child: CollectionCardDetailsVertical(
                  topText: 'Yearly',
                  bottomText: '₹${amounts.yearAmount.toInt()}',
                  lineColor: Colors.blue,
                  lineHeight: 50,
                  lineWidth: 5,
                  textSize: 14,
                ),
              );
            } else if (index == 1) {
              return GestureDetector(
                onTap: () => handleCardTap('Monthly'),
                child: CollectionCardDetailsVertical(
                  topText: 'Monthly',
                  bottomText: '₹${amounts.monthAmount.toInt()}',
                  lineColor: Colors.green,
                  lineHeight: 50,
                  lineWidth: 5,
                  textSize: 14,
                ),
              );
            } else {
              return GestureDetector(
                onTap: () => handleCardTap('Weekly'),
                child: CollectionCardDetailsVertical(
                  topText: 'Weekly',
                  bottomText: '₹${amounts.weekAmount.toInt()}',
                  lineColor: Colors.red,
                  lineHeight: 50,
                  lineWidth: 5,
                  textSize: 14,
                ),
              );
            }
          },
        ),
      )
        ],
      ),
    );
  }
}