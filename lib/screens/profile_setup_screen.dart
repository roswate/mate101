import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Dosya okumak için gerekli
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // JSON çevirmek için
import '../services/database_service.dart';
import 'home_screen.dart';
import '../core/constants.dart'; // İller listesi buradan geliyor

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // --- KONTROLCÜLER ---
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  String? _selectedCity;
  String? _selectedUni;
  bool _isSaving = false;

  // --- LİSTELER ---
  List<String> _universities = []; // JSON'dan dolacak
  
  final List<String> _selectedGames = [];
  final List<String> _selectedVibes = []; 
  final List<String> _selectedDrinks = []; 

  final List<String> _gameList = [
    "Okey 101", "Düz Okey", "Tavla", "Batak", "Pişti",
    "Valorant", "LoL", "CS2", "FIFA", "PUBG", "GTA 5", "Minecraft"
  ];

  final List<String> _vibeList = [
    "🏆 Tryhard", "😎 Chill", "🗣️ Sohbet", "🚭 Sigara Yok", "🚬 Sigara Var"
  ];

  final List<String> _drinkList = [
    "☕ Kahve", "🍵 Çay", "🍺 Alkol", "🥤 Kola/Gazoz", "🧉 Nargile"
  ];

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  // --- ÜNİVERSİTELERİ DOSYADAN OKU (CORS YOK, HATA YOK) ---
  Future<void> _loadUniversities() async {
    try {
      final String response = await rootBundle.loadString('assets/universities.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _universities = data.map((e) => e['name'].toString()).toList();
        _universities.sort(); // Alfabetik sırala
      });
    } catch (e) {
      print("Dosya okuma hatası: $e");
    }
  }

  // --- KAYDETME FONKSİYONU ---
  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _selectedCity == null || _selectedUni == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen Ad, Şehir ve Üniversite alanlarını doldur!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseService().saveUser(user.uid, {
          "uid": user.uid,
          "name": _nameCtrl.text.trim(),
          "bio": _bioCtrl.text.trim(),
          "city": _selectedCity,
          "uni": _selectedUni,
          "games": _selectedGames,
          "vibes": _selectedVibes,
          "drinks": _selectedDrinks,
          "email": user.email,
          "createdAt": DateTime.now(),
          "img": user.photoURL ?? "https://i.pravatar.cc/300"
        });

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainHomeScreen()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profilini Oluştur", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTOĞRAF
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null 
                        ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) 
                        : null,
                    child: FirebaseAuth.instance.currentUser?.photoURL == null 
                        ? const Icon(Icons.person, size: 50, color: Color(0xFF6C63FF)) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            // INPUTLAR
            _customTextField(_nameCtrl, "Adın Soyadın", Icons.person),
            const SizedBox(height: 15),
            _customTextField(_bioCtrl, "Biyografi (İsteğe bağlı)", Icons.edit_note, maxLines: 2),
            const SizedBox(height: 15),
            
            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Şehir Seç", Icons.location_on),
              items: iller.map((il) => DropdownMenuItem(value: il, child: Text(il))).toList(),
              onChanged: (val) => setState(() => _selectedCity = val),
            ),
            const SizedBox(height: 15),

            // ÜNİVERSİTE AUTOCOMPLETE (Dosyadan Okuyor)
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return _universities.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) => _selectedUni = selection,
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: _inputDecoration("Üniversiteni Ara (Örn: Dokuz Eylül)", Icons.school),
                );
              },
            ),

            const SizedBox(height: 30),
            
            // OYUNLAR & TARZ
            _sectionTitle("Hangi Oyunlar? 🎮"),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: _gameList.map((g) => _buildChoiceChip(g, _selectedGames)).toList()),

            const SizedBox(height: 20),
            _sectionTitle("Ortamın Nasıl? ✨"),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._vibeList.map((v) => _buildChoiceChip(v, _selectedVibes)),
              ..._drinkList.map((d) => _buildChoiceChip(d, _selectedDrinks)),
            ]),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("KAYDET VE BAŞLA 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI METHODLAR ---
  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  Widget _customTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(controller: ctrl, maxLines: maxLines, decoration: _inputDecoration(hint, icon));
  }
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  Widget _buildChoiceChip(String label, List<String> list) {
    final isSelected = list.contains(label);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) => setState(() => s ? list.add(label) : list.remove(label)),
      selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF6C63FF) : Colors.black),
      side: BorderSide(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300),
    );
  }
}