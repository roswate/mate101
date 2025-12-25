import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'intro_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_pages.dart'; // YENİ SAYFALARI İÇEREN DOSYA

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color _mainGreen = const Color(0xFF1B5E20);
  final User? user = FirebaseAuth.instance.currentUser;

  // VERİTABANI AYAR GÜNCELLEME (Bildirim & Online)
  Future<void> _updateSetting(String key, bool value) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({key: value});
    }
  }

  // HESAP SİLME İŞLEMİ
  void _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text("Hesabını silmek istediğine emin misin? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                // Firestore verisini silmek karmaşıktır, şimdilik hesabı siliyoruz.
                await user?.delete(); 
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const IntroScreen()), (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hesap silindi. Hoşçakal!")));
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güvenlik gereği tekrar giriş yapıp silmelisin.")));
              }
            },
            child: const Text("Evet, Sil")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        bool notifEnabled = userData['settings_notifications'] ?? true;
        bool onlineStatus = userData['isOnline'] ?? true;
        bool isVerified = userData['isVerified'] ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: _mainGreen,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader("HESAP & GÜVENLİK"),
              
              // 1. PROFİLİ DÜZENLE
              _settingTile(Icons.edit, "Profili Düzenle", "Fotoğraf, biyografi ve bilgiler", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              
              // 2. ÖĞRENCİ DOĞRULAMASI (YENİ EKRANA GİDİYOR)
              _settingTile(
                isVerified ? Icons.verified : Icons.warning_amber_rounded, 
                isVerified ? "Öğrenci Hesabı Onaylı" : "Öğrenci Doğrulaması", 
                isVerified ? "Mavi Tik Aktif ✅" : "Doğrulamak için tıkla", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentVerificationScreen()))
              ),
              
              // 3. ENGELLENENLER (YENİ EKRANA GİDİYOR)
              _settingTile(Icons.block, "Engellenenler", "Engellediğin kullanıcıları gör", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()))),

              const SizedBox(height: 20),

              _sectionHeader("UYGULAMA TERCİHLERİ"),
              
              // 4. BİLDİRİMLER (SWITCH)
              SwitchListTile(
                activeColor: _mainGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
                secondary: Icon(Icons.notifications, color: Colors.grey.shade700),
                title: const Text("Bildirimler", style: TextStyle(fontWeight: FontWeight.w500)),
                value: notifEnabled,
                onChanged: (val) => _updateSetting('settings_notifications', val),
              ),
              const SizedBox(height: 8),
              
              // 5. ONLİNE DURUMU (SWITCH)
              SwitchListTile(
                activeColor: _mainGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
                secondary: Icon(Icons.visibility, color: Colors.grey.shade700),
                title: const Text("Çevrimiçi Görün"),
                subtitle: const Text("Diğerleri seni aktif görsün"),
                value: onlineStatus,
                onChanged: (val) => _updateSetting('isOnline', val),
              ),

              const SizedBox(height: 20),

              _sectionHeader("DESTEK & DİĞER"),
              
              // 6. YARDIM MERKEZİ (YENİ EKRANA GİDİYOR)
              _settingTile(Icons.help_outline, "Yardım Merkezi", "Sıkça sorulan sorular (SSS)", 
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
              
              _settingTile(Icons.info_outline, "Uygulama Hakkında", "v1.2.0 - Mate101", () {}),

              const SizedBox(height: 30),

              // 7. ÇIKIŞ YAP
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const IntroScreen()), (route) => false);
                },
              ),
              
              // 8. HESABI SİL
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.grey),
                title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.grey)),
                onTap: _deleteAccount,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 5), child: Text(title, style: TextStyle(color: _mainGreen, fontWeight: FontWeight.bold, fontSize: 13)));

  Widget _settingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}