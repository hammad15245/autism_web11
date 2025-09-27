import 'package:autism_parent_web/controller/auth_controller.dart';
import 'package:autism_parent_web/widgets/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final authController = Get.find<AuthController>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final parentDoc =
        await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
    final teacherDoc =
        await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();

    final userData = parentDoc.exists ? parentDoc.data() : teacherDoc.data();

    if (userData != null) {
      nameController.text = userData['name'] ?? '';
    }
    emailController.text = user.email ?? '';
  }

  Future<void> _updateName() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Name cannot be empty");
      return;
    }
    setState(() => isLoading = true);
    await authController.updateName(nameController.text.trim());
    setState(() => isLoading = false);
  }

  Future<void> _updateEmail() async {
    final newEmail = emailController.text.trim();
    if (newEmail.isEmpty) {
      Get.snackbar("Error", "Email cannot be empty");
      return;
    }
    setState(() => isLoading = true);
    await authController.updateEmail(newEmail);
    setState(() => isLoading = false);
  }

  Future<void> _updatePassword() async {
    final newPassword = passwordController.text.trim();
    if (newPassword.isEmpty) {
      Get.snackbar("Error", "Password cannot be empty");
      return;
    }
    setState(() => isLoading = true);
    await authController.updatePassword(newPassword);
    passwordController.clear();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Update Name"),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateName,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("Save Name"),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle("Update Email"),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateEmail,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("Save Email"),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle("Update Password"),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: "New Password"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("Save Password"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
