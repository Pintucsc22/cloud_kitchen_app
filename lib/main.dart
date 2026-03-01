import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/role_screens/admin_screen.dart';
import 'screens/role_screens/kitchen_screen.dart';
import 'screens/role_screens/store_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashWrapper(),
    );
  }
}

// SplashWrapper will handle navigation based on login & role
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    navigateUser();
  }

  Future<void> navigateUser() async {
    await Future.delayed(const Duration(seconds: 2)); // optional splash delay

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // No user logged in → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // User is logged in → fetch role
    final uid = currentUser.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // No Firestore document → fallback to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final role = userDoc['role'] ?? 'customer';

    // Navigate to correct screen
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminScreen()),
      );
    } else if (role == 'kitchen') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const KitchenScreen()),
      );
    } else if (role == 'store') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StoreScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // show your existing splash while checking
  }
}