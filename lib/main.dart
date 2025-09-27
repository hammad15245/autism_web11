import 'package:autism_parent_web/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAyBu6HfVunp76pg6Oxovs2IMNtM1sMkzo",
      authDomain: "autism-f1464.firebaseapp.com",
      projectId: "autism-f1464",
      storageBucket: "autism-f1464.firebasestorage.app",
      messagingSenderId: "892578122648",
      appId: "1:892578122648:web:3e79245d7305b435ba79ed",
    ),
  );

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Autism Parent Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home:  ParentLoginScreen(),
    );
  }
}