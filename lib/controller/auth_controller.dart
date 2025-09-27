import 'package:autism_parent_web/dashboard.dart';
import 'package:autism_parent_web/login_screen.dart';
import 'package:autism_parent_web/teacher_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var obscureText = true.obs;
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var roleController = TextEditingController();

  // ✅ Store logged-in user role here (parent/teacher)
  var currentRole = ''.obs;

  var emailError = RxString('');
  var passwordError = RxString('');
  var roleError = RxString('');

  void togglePasswordVisibility() {
    obscureText.value = !obscureText.value;
  }

  void clearErrors() {
    emailError.value = '';
    passwordError.value = '';
    roleError.value = '';
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail); // safer for reauth
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
        });
        Get.snackbar("Success", "Email updated successfully. Verify new email.");
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Failed to update email");
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        Get.snackbar("Success", "Password updated successfully");
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Failed to update password");
    }
  }

  Future<void> updateName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': newName,
        });
        Get.snackbar("Success", "Name updated successfully");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update name");
    }
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = roleController.text.trim().toLowerCase();

    clearErrors();

    if (email.isEmpty) {
      emailError.value = 'Email cannot be empty';
      return;
    }
    if (password.isEmpty) {
      passwordError.value = 'Password cannot be empty';
      return;
    }
    if (role.isEmpty) {
      roleError.value = 'Please select a role';
      return;
    }
    if (role != 'parent' && role != 'teacher') {
      roleError.value = 'Role must be either "parent" or "teacher"';
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      emailError.value = 'Please enter a valid email';
      return;
    }

    try {
      isLoading.value = true;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        passwordError.value = 'Something went wrong. Please try again.';
        return;
      }

      if (role == 'parent') {
        final parentDoc = await _firestore.collection('parents').doc(userId).get();

        if (parentDoc.exists) {
          currentRole.value = 'parent'; // ✅ Store current role
          Navigator.of(Get.context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
            (route) => false,
          );
        } else {
          await _auth.signOut();
          emailError.value = 'This account is not registered as a parent';
          passwordError.value = 'Please check your role selection';
        }
      } else if (role == 'teacher') {
        final teacherDoc = await _firestore.collection('teachers').doc(userId).get();

        if (teacherDoc.exists) {
          currentRole.value = 'teacher'; // ✅ Store current role
          Navigator.of(Get.context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            (route) => false,
          );
        } else {
          await _auth.signOut();
          emailError.value = 'This account is not registered as a teacher';
          passwordError.value = 'Please check your role selection';
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emailError.value = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        passwordError.value = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        emailError.value = 'Invalid email format';
      } else {
        passwordError.value = 'Invalid email or password';
      }
    } catch (e) {
      passwordError.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    await _auth.signOut();
    emailController.clear();
    passwordController.clear();
    roleController.clear();
    currentRole.value = ''; // ✅ clear role
    clearErrors();
    Get.offAll(() => ParentLoginScreen());
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    roleController.dispose();
    super.onClose();
  }
}
