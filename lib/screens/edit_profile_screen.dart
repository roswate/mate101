import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_pages.dart'; // Eğer doğrulanmamışsa yönlendirmek için

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _imgCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  
  String? _selectedCity;
  String? _selectedUni;
  String? _selectedGender;
  bool _isVerified = false;

  List<String> _universities = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Color _mainGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Üniversite Listesini Çek
    final uniSnap = await FirebaseFirestore.instance.collection('universities').get();
    setState(() {
      _universities = uniSnap.docs.map((d) => d['name'].toString()).toList();
      _universities.sort();
    });

    // 2. Kullanıcı Verisini Çek
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      _nameCtrl.text = data['name'] ?? "";
      _imgCtrl.text = data['img'] ?? "";
      _bioCtrl.text = data['bio'] ?? "";
      _selectedCity = data['city'];
      _selectedUni = data['uni'];
      _selectedGender = data['gender'];
      _isVerified = data['isVerified'] ?? false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameCtrl.text.trim(),
      'img': _imgCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'city': _selectedCity,
      'uni': _selectedUni,
      'gender': _selectedGender,
    });

    setState(() => _isSaving = false);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil Güncellendi ✅")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Profili Düzenle"), backgroundColor: _mainGreen, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // FOTOĞRAF ALANI
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(_imgCtrl.text.isNotEmpty ? _imgCtrl.text : "https://i.pravatar.cc/150")),
            const SizedBox(height: 10),
            TextField(controller: _imgCtrl, decoration: const InputDecoration(labelText: "Profil Fotoğrafı Linki", border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
            const SizedBox(height: 20),

            // İSİM ALANI
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 15),

            // ÜNİVERSİTE SEÇİMİ
            DropdownButtonFormField<String>(
              initialValue: _selectedUni,
              decoration: const InputDecoration(labelText: "Üniversite", border: OutlineInputBorder(), prefixIcon: Icon(Icons.school)),
              items: _universities.map((uni) => DropdownMenuItem(value: uni, child: Text(uni, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() => _selectedUni = val),
            ),
            const SizedBox(height: 15),

            // ONAY DURUMU (Sadece Bilgi)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _isVerified ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: _isVerified ? Colors.green : Colors.orange)),
              child: Row(
                children: [
                  Icon(_isVerified ? Icons.verified : Icons.warning_amber_rounded, color: _isVerified ? Colors.green : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isVerified ? "Öğrenci Hesabı Onaylı" : "Onaysız Hesap", style: const TextStyle(fontWeight: FontWeight.bold)),
                        if(!_isVerified)
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentVerificationScreen())),
                            child: const Text("Doğrulamak için tıkla ->", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // DİĞER BİLGİLER
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(labelText: "Cinsiyet", border: OutlineInputBorder(), prefixIcon: Icon(Icons.wc)),
              items: ["Erkek", "Kadın"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val),
            ),
            const SizedBox(height: 15),
            TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Biyografi", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description))),
            
            const SizedBox(height: 30),
            
            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _mainGreen, foregroundColor: Colors.white),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}