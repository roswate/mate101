import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü için gerekli
import 'screens/intro_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SENİN VERDİĞİN WEB AYARLARI BURADA 👇
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA9jnO_U23p6Bsx8sgZDfTHqxh2oeYk0VQ",
        authDomain: "mate101-77c19.firebaseapp.com",
        projectId: "mate101-77c19",
        storageBucket: "mate101-77c19.firebasestorage.app",
        messagingSenderId: "136675003050",
        appId: "1:136675003050:web:4556bddb50bfcc2a3e5ed3",
        measurementId: "G-BQD0XLEHFM",
      ),
    );
  } else {
    // Android ve iOS için otomatik (dosyadan okur)
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mate101',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainHomeScreen();
          }
          return const IntroScreen();
        },
      ),
    );
  }
}