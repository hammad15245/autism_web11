import 'package:autism_parent_web/controller/auth_controller.dart';
import 'package:autism_parent_web/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
    if (parentDoc.exists) return parentDoc.data();

    final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(user.uid).get();
    if (teacherDoc.exists) return teacherDoc.data();

    return null;
  }

  Future<void> _updateUserName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final parentDoc = FirebaseFirestore.instance.collection('parents').doc(user.uid);
    final teacherDoc = FirebaseFirestore.instance.collection('teachers').doc(user.uid);

    if ((await parentDoc.get()).exists) {
      await parentDoc.update({'name': newName});
    } else if ((await teacherDoc.get()).exists) {
      await teacherDoc.update({'name': newName});
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No profile data found"));
            }

            final userData = snapshot.data!;
            final user = FirebaseAuth.instance.currentUser;
            _nameController.text = userData['name'] ?? '';

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.teal,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Editable Name
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your name",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _updateUserName(value.trim());
                      }
                    },
                  ),

                  Text(
                    user?.email ?? 'No Email',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Role: ${userData['role'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),

                  const Spacer(),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () {
                      authController.logout();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
