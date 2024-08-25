import 'package:flutter/material.dart';


class ImageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          _showImageSelectionSheet(context);
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Icon(
            Icons.camera_alt,
            size: 80,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showImageSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Add code to open camera
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Add code to open gallery
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
