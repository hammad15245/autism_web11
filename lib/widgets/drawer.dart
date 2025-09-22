import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.1;
          double fontSize = constraints.maxWidth * 0.08;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
            children: [
              _buildDrawerItem(Icons.home, "Dashboard", iconSize, fontSize, () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.person, "Profile", iconSize, fontSize, () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.settings, "Settings", iconSize, fontSize,
                  () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.bar_chart, "Progress", iconSize, fontSize,
                  () {
                Navigator.pop(context);
              }),
              _buildDrawerItem(Icons.logout, "Sign Out", iconSize, fontSize, () {
                Navigator.pop(context);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String text, double iconSize,
      double fontSize, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        size: iconSize,
        color: Colors.teal, 
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color.fromARGB(255, 0, 0, 0), 
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
