import 'package:autism_parent_web/controller/auth_controller.dart';
import 'package:autism_parent_web/setting_screen.dart';
import 'package:autism_parent_web/teacher_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:autism_parent_web/dashboard.dart';
import 'package:autism_parent_web/profile_screen.dart'; 

class CustomDrawer extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  CustomDrawer({super.key});

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
              _buildDrawerItem(Icons.home, "Progress", iconSize, fontSize, () {
                Navigator.pop(context);
if (authController.currentRole.value == 'teacher') {
  Get.to(() => const TeacherDashboardScreen());
} else {
  Get.to(() => const ParentDashboardScreen());
}
              }),
              _buildDrawerItem(Icons.person, "Profile", iconSize, fontSize, () {
                Navigator.pop(context);
                Get.to(() =>  ProfileScreen()); 
              }),
             
              _buildDrawerItem(Icons.settings, "Setting", iconSize, fontSize,
                  () {
                Navigator.pop(context);
                Get.to(() =>  SettingsScreen()); 
              }),
              _buildDrawerItem(Icons.logout, "Sign Out", iconSize, fontSize, () {
                Navigator.pop(context);
                authController.logout();
              }),
            ],
          );
        },
      ),
    );
  }


  Widget _buildDrawerItem(
      IconData icon, String text, double iconSize, double fontSize, VoidCallback onTap) {
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
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
