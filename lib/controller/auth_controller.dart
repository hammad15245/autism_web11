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
  var roleController = TextEditingController(); // Add role controller
  
  // Add error state variables
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

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = roleController.text.trim().toLowerCase();

    // Clear previous errors
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

    // Email format validation
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
        // Check if user exists in TEACHERS collection
        final teacherDoc = await _firestore.collection('teachers').doc(userId).get();

        if (teacherDoc.exists) {

          Navigator.of(Get.context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            (route) => false,
          );
        } else {
          // NOT A TEACHER - DENY ACCESS
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