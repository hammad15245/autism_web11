import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:autism_parent_web/controller/auth_controller.dart';

class ParentLoginScreen extends StatelessWidget {
  ParentLoginScreen({super.key});
  
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: isMobile
          ? Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("lib/assets/banner.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _loginContainer(context),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("lib/assets/banner.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _loginContainer(context),
                ),
              ],
            ),
    );
  }

  Widget _loginContainer(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            const Text(
              "Login to your account",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            // Role Selection
            Obx(() => DropdownButtonFormField<String>(
              value: authController.roleController.text.isEmpty 
                  ? null 
                  : authController.roleController.text,
              decoration: InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: authController.roleError.value.isEmpty 
                    ? null 
                    : authController.roleError.value,
                errorStyle: TextStyle(color: Colors.red[700]),
              ),
              items: ['parent', 'teacher']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                authController.roleController.text = value ?? '';
                authController.clearErrors();
              },
            )),
            const SizedBox(height: 25),
            
            // Email Field with Error
            Obx(() => TextField(
              controller: authController.emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: authController.emailError.value.isEmpty 
                    ? null 
                    : authController.emailError.value,
                errorStyle: TextStyle(color: Colors.red[700]),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => authController.clearErrors(),
            )),
            const SizedBox(height: 25),
            
            // Password Field with Error
            Obx(() => TextField(
              controller: authController.passwordController,
              obscureText: authController.obscureText.value,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    authController.obscureText.value 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                  ),
                  onPressed: () => authController.togglePasswordVisibility(),
                ),
                errorText: authController.passwordError.value.isEmpty 
                    ? null 
                    : authController.passwordError.value,
                errorStyle: TextStyle(color: Colors.red[700]),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red[700]!),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => authController.clearErrors(),
            )),
            const SizedBox(height: 10),
          
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Add forgot password logic
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Obx(() => authController.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: authController.loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Login"),
                  )),
          ],
        ),
      ),
    );
  }
}