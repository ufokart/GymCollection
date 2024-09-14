import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold)),
    leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
    Navigator.pop(context);
    })
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Gym Collection!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              'Gym Collection is your all-in-one platform designed to simplify your fitness journey. Whether you\'re a fitness enthusiast, a gym owner, or a member, Gym Collection provides a seamless experience to manage memberships, plans, and transactions with ease.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 24.0),
            Text(
              'Our Mission',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'To revolutionize the way you manage fitness and gym memberships, making it simple, hassle-free, and accessible.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 24.0),
            Text(
              'Why Choose Gym Collection?',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            BulletPointList(
              points: [
                'Easy membership management',
                'Seamless plan upgrades and renewals',
                'Quick access to gym-related transactions',
                'User-friendly interface',
                'Dedicated customer support',
              ],
            ),
            SizedBox(height: 24.0),
            Text(
              'Stay fit. Stay organized. Stay ahead with Gym Collection.',
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}

class BulletPointList extends StatelessWidget {
  final List<String> points;

  BulletPointList({required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.fiber_manual_record, size: 12.0, color: Colors.black),
            SizedBox(width: 8.0),
            Expanded(child: Text(point, style: TextStyle(fontSize: 16.0))),
          ],
        );
      }).toList(),
    );
  }
}
