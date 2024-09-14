import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this dependency in your pubspec.yaml file

class ContactUsPage extends StatelessWidget {
  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'.toUpperCase(),style: TextStyle(fontWeight: FontWeight.bold)),
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
              'We would love to hear from you! Whether you have questions, feedback, or need support, feel free to reach out to us through the following channels:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 24.0),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text('gymcollection@gmail.com'),
              onTap: () => _launchUrl('mailto:gymcollection@gmail.com'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone'),
              subtitle: Text('+91 (800) 592-0523'),
              onTap: () => _launchUrl('tel:+11234567890'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Website'),
              subtitle: Text('www.gymcollection.com'),
              onTap: () => _launchUrl('https://www.gymcollection.com'),
            ),

          ],
        ),
      ),
    );
  }
}


