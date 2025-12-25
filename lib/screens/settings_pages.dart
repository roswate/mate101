import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// 1. ENGELLENENLER EKRANI (AYNI)
// ==========================================
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Engellenenler"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('blocked_users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 15),
                  const Text("Engellenmiş kimse yok.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['img'] ?? "https://i.pravatar.cc/150"),
                  ),
                  title: Text(data['name'] ?? "Kullanıcı", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Mesaj atamaz"),
                  trailing: TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(myUid)
                          .collection('blocked_users')
                          .doc(doc.id)
                          .delete();
                      
                      if(context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Engel kaldırıldı.")));
                      }
                    },
                    child: const Text("Engeli Kaldır", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. YARDIM MERKEZİ (AYNI)
// ==========================================
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yardım Merkezi"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpItem(
            icon: Icons.emoji_events, 
            title: "Puan sistemi nasıl çalışır?", 
            content: "Sohbet ekranında sağ üstteki 🏆 kupa ikonuna tıklayarak maç sonucunu girersen +25 Puan kazanırsın."
          ),
          _HelpItem(
            icon: Icons.verified, 
            title: "Mavi Tik nasıl alırım?", 
            content: "Ayarlar menüsünden 'Öğrenci Doğrulaması'na git. Üniversite mailini gir (.edu.tr uzantılı) ve 'Link Gönder' butonuna bas. Mailine gelen linke tıklayınca Mavi Tik alırsın."
          ),
          _HelpItem(
            icon: Icons.school, 
            title: "Lig sıralaması nedir?", 
            content: "Lig sıralaması, o üniversitedeki ONAYLI (Mavi Tikli) öğrencilerin toplam puanına göre belirlenir."
          ),
          _HelpItem(
            icon: Icons.mark_email_read,
            title: "Mail gelmedi mi?",
            content: "Lütfen 'Spam' veya 'Gereksiz' kutusunu kontrol et. Bazen linkler oraya düşebilir."
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _HelpItem({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF1B5E20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [Padding(padding: const EdgeInsets.all(16), child: Text(content))],
      ),
    );
  }
}

// ==========================================
// 3. ÖĞRENCİ DOĞRULAMA (ESNEK KONTROL) 🎓✅
// ==========================================
class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  State<StudentVerificationScreen> createState() => _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  final _mailCtrl = TextEditingController();
  bool _isLinkSent = false;
  bool _isLoading = false;

  // --- ARTIK SADECE EDU.TR KONTROLÜ YAPIYORUZ ---
  bool _isStudentMail(String email) {
    // "gulsu.celik@deu.edu.tr" gibi formatları kabul etmek için
    // sadece uzantıya bakıyoruz.
    return email.endsWith(".edu.tr");
  }

  // 1. LİNK GÖNDERME
  Future<void> _sendVerificationLink() async {
    final mail = _mailCtrl.text.trim().toLowerCase();
    
    // KONTROL BURADA 👇
    if (!_isStudentMail(mail)) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("Hatalı Mail Formatı"),
        content: const Text("Lütfen geçerli bir üniversite maili giriniz.\n\nMail adresiniz '.edu.tr' ile bitmelidir."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tamam"))],
      ));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firebase Linki Gönder
        await user.verifyBeforeUpdateEmail(mail);
        
        setState(() => _isLinkSent = true);
        
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text("Link Gönderildi! 📨"),
          content: Text("$mail adresine doğrulama linki gönderdik.\n\n1. Maili aç ve linke tıkla.\n2. Sonra buraya dönüp 'DOĞRULADIM' butonuna bas."),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tamam"))],
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: Bir sorun oluştu. Lütfen tekrar dene."), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. SON KONTROL
  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // Son durumu çek
        final updatedUser = FirebaseAuth.instance.currentUser;

        // Mail doğrulanmış mı VE format hala edu.tr mi?
        if (updatedUser!.emailVerified && _isStudentMail(updatedUser.email ?? "")) {
          
          // Firestore'a Mavi Tik Yaz
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'isVerified': true,
            'eduMail': updatedUser.email
          });

          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TEBRİKLER! Öğrenci olduğun doğrulandı. 🎓✅"), backgroundColor: Colors.green));
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Henüz onaylanmamış. Linke tıkladığından emin misin?"), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Öğrenci Doğrulaması"), backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isLinkSent ? Icons.mark_email_read : Icons.security, size: 80, color: const Color(0xFF1B5E20)),
            const SizedBox(height: 20),
            Text(
              _isLinkSent ? "Linke Tıkla" : "Öğrenci Mailini Gir",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _isLinkSent 
                ? "Mail kutuna (ve Spam'e) bak. Linke tıkladıktan sonra butona bas." 
                : "Üniversite tarafından verilen .edu.tr uzantılı mailini gir.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            if (!_isLinkSent)
              TextField(
                controller: _mailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Okul Maili (örn: ad.soyad@deu.edu.tr)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.mail),
                ),
              ),

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20), 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: _isLinkSent ? _checkVerification : _sendVerificationLink,
                    child: Text(_isLinkSent ? "LİNKE TIKLADIM, ONAYLA" : "DOĞRULAMA LİNKİ GÖNDER", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
            ),
            
            if(_isLinkSent)
              TextButton(onPressed: () => setState(() { _isLinkSent = false; }), child: const Text("Mail adresini değiştir"))
          ],
        ),
      ),
    );
  }
}