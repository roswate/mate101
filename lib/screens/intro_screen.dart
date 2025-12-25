import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup_screen.dart';
import 'home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool _isLoading = false;

  // --- GOOGLE GİRİŞ VE YÖNLENDİRME MANTIĞI (AYNEN KORUNDU) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCred.user;

      if (user != null && mounted) {
        // Veritabanı Kontrolü
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileSetupScreen()));
        }
      }
    } catch (e) {
      print("Hata: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM: Koyu Yeşil Premium Tema
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF004D40), // Çok koyu yeşil (Teal)
              Color(0xFF00695C), // Biraz daha açık tonu
              Color(0xFF00251A), // En altta neredeyse siyah yeşil
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // 1. LOGO VE İKON
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2)
                  ),
                  child: const Icon(
                    Icons.groups_3_outlined, // İnsan grubu/Topluluk ikonu
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. BAŞLIK VE SLOGAN
                const Text(
                  "Mate101",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Üniversitende Oyun Arkadaşını Bul.\nTakımını Kur, Eğlenceye Başla.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade300,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 3),

                // 3. GOOGLE İLE DEVAM ET BUTONU
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF004D40), // Yazı rengi koyu yeşil
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          // Google'ın 'G' simgesi yerine sade bir ikon koydum
                          icon: const Icon(Icons.login_rounded, size: 24), 
                          label: const Text(
                            "Google ile Devam Et",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                
                const SizedBox(height: 20),
                
                // 4. ALT BİLGİ
                Text(
                  "Giriş yaparak kullanım koşullarını kabul etmiş olursun.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}