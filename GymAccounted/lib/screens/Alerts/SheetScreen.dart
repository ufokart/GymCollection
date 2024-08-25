import 'package:flutter/material.dart';
import 'package:gymaccounted/screens/Members/add_members.dart';
class OptionItem {
  final int id;
  final IconData iconData;
  final String name;

  OptionItem({required this.id, required this.iconData, required this.name});
}

class OptionsSheet extends StatelessWidget {
  final List<OptionItem> options;

  OptionsSheet(this.options);

  @override
  Widget build(BuildContext context) {
    return ListView(


      shrinkWrap: true, // ensure the ListView takes only the space it needs
        children: options.map((option) {
          return ListTile(
            leading: Icon(option.iconData),
            trailing: Icon(Icons.arrow_forward_ios),
            title: Text(option.name),
            onTap: () {
              // Handle the option based on its ID
              handleOption(context, option.id);
            },
          );
        }).toList(),
    );
  }

  void handleOption(BuildContext context, int id) {
    switch (id) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddMembers()),
        );

      case 2:
      // Handle gallery option
        print('Gallery option selected');
        break;
    // Add more cases for additional options
    }
   //Navigator.pop(context);
  }
}
