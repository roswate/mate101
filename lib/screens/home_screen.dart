import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final Color _mainGreen = const Color(0xFF1B5E20); 

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MasaBulTab(dbService: _dbService, mainColor: _mainGreen),
      LeagueTab(mainColor: _mainGreen),
      MessagesTab(mainColor: _mainGreen),
      ProfileTab(mainColor: _mainGreen),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: _mainGreen.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.travel_explore), selectedIcon: Icon(Icons.travel_explore, color: _mainGreen), label: "Masa Bul"),
          NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: _mainGreen), label: "Lig"),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: _mainGreen), label: "Sohbet"),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: _mainGreen), label: "Profil"),
        ],
      ),
    );
  }
}

// --- 1. MASA BUL ---
class MasaBulTab extends StatefulWidget {
  final DatabaseService dbService;
  final Color mainColor;
  const MasaBulTab({super.key, required this.dbService, required this.mainColor});
  @override
  State<MasaBulTab> createState() => _MasaBulTabState();
}
class _MasaBulTabState extends State<MasaBulTab> {
  bool _showNearby = true;
  String _genderFilter = "Hepsi";
  final List<String> _selectedGamesFilter = [];
  final List<String> _allGames = ["Okey 101", "Düz Okey", "52", "Batak", "LoL", "Valorant"];
  void _showFilterModal() { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) { return StatefulBuilder(builder: (context, setModalState) { return Padding(padding: const EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ const Text("Filtrele", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Divider(), const Text("Cinsiyet", style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 8, children: ["Hepsi", "Kadın", "Erkek"].map((g) => ChoiceChip(label: Text(g), selected: _genderFilter == g, onSelected: (val) => setModalState(() => _genderFilter = g), selectedColor: widget.mainColor.withValues(alpha: 0.2))).toList()), const SizedBox(height: 15), const Text("Oyunlar", style: TextStyle(fontWeight: FontWeight.bold)), Wrap(spacing: 8, children: _allGames.map((game) => FilterChip(label: Text(game), selected: _selectedGamesFilter.contains(game), onSelected: (val) => setModalState(() => val ? _selectedGamesFilter.add(game) : _selectedGamesFilter.remove(game)), selectedColor: widget.mainColor, checkmarkColor: Colors.white)).toList()), const SizedBox(height: 20)])); }); }); }
  @override
  Widget build(BuildContext context) {
    final currentUserIdx = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(backgroundColor: widget.mainColor, title: const Text("Mate101", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), actions: [IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: _showFilterModal)]),
      body: Column(children: [Container(color: widget.mainColor, padding: const EdgeInsets.only(bottom: 15, left: 20, right: 20), child: Container(height: 45, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(25)), child: Row(children: [Expanded(child: GestureDetector(onTap: () => setState(() => _showNearby = true), child: Container(decoration: BoxDecoration(color: _showNearby ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25)), alignment: Alignment.center, child: Text("Yakındakiler", style: TextStyle(fontWeight: FontWeight.bold, color: _showNearby ? widget.mainColor : Colors.white70))))), Expanded(child: GestureDetector(onTap: () => setState(() => _showNearby = false), child: Container(decoration: BoxDecoration(color: !_showNearby ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(25)), alignment: Alignment.center, child: Text("Aktif Oyuncular", style: TextStyle(fontWeight: FontWeight.bold, color: !_showNearby ? widget.mainColor : Colors.white70)))))]))), Expanded(child: StreamBuilder<QuerySnapshot>(stream: widget.dbService.getUsers(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); List<Map<String, dynamic>> allUsers = snapshot.data!.docs.where((doc) => doc['uid'] != currentUserIdx).map((doc) => doc.data() as Map<String, dynamic>).toList(); if (_genderFilter != "Hepsi") allUsers = allUsers.where((u) => u['gender'] == _genderFilter).toList(); if (_selectedGamesFilter.isNotEmpty) allUsers = allUsers.where((u) => (u['games'] as List).any((g) => _selectedGamesFilter.contains(g))).toList(); if (allUsers.isEmpty) return const Center(child: Text("Kimse yok.")); return ListView.builder(itemCount: allUsers.length, padding: const EdgeInsets.all(10), itemBuilder: (context, index) { final user = allUsers[index]; return Card(child: ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(user['img'] ?? "")), title: Text(user['name']), subtitle: Text(user['uni'] ?? ""), trailing: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.mainColor, foregroundColor: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: user))), child: const Text("Oyna")))); }); }))]),
    );
  }
}

// --- 2. LİG SEKMESİ (DÜZELTİLDİ: ESKİ PAKET KALDIRILDI) ---
class LeagueTab extends StatelessWidget {
  final Color mainColor;
  const LeagueTab({super.key, required this.mainColor});

  void _showTeamRankings(BuildContext context, String uniName) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) {
        return DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, scrollController) {
            return Column(children: [
                Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: mainColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Row(children: [const Icon(Icons.school, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text("$uniName Kadrosu", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))])),
                Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').where('uni', isEqualTo: uniName).where('isVerified', isEqualTo: true).snapshots(), builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Bu okulda henüz onaylı oyuncu yok."));
                      var players = snapshot.data!.docs.toList();
                      players.sort((a, b) { int scoreA = int.tryParse(a['playerScore']?.toString() ?? "0") ?? 0; int scoreB = int.tryParse(b['playerScore']?.toString() ?? "0") ?? 0; return scoreB.compareTo(scoreA); });
                      return ListView.builder(controller: scrollController, itemCount: players.length, padding: const EdgeInsets.all(10), itemBuilder: (context, index) {
                          var player = players[index].data() as Map<String, dynamic>;
                          int score = int.tryParse(player['playerScore']?.toString() ?? "0") ?? 0;
                          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Stack(children: [CircleAvatar(backgroundImage: NetworkImage(player['img'] ?? "")), if (index < 3) Positioned(bottom: 0, right: 0, child: Icon(Icons.emoji_events, size: 16, color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey : Colors.brown)))]), title: Text(player['name'] ?? "İsimsiz", style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text("$score Puan", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)), subtitle: Text("#${index + 1}. Sıra")));
                      });
                })),
            ]);
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Üniversite Ligi 🏆", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: mainColor),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          Map<String, int> uniScores = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (data['isVerified'] == true) {
              String uni = data['uni'] ?? "Diğer";
              int score = int.tryParse(data['playerScore']?.toString() ?? "0") ?? 0;
              uniScores[uni] = (uniScores[uni] ?? 0) + score;
            }
          }
          var sortedKeys = uniScores.keys.toList(growable: false)..sort((k1, k2) => uniScores[k2]!.compareTo(uniScores[k1]!));
          return Column(children: [
              Expanded(child: sortedKeys.isEmpty 
                ? const Center(child: Text("Henüz onaylı oyuncu yok. İlk sen ol!"))
                : ListView.builder(padding: const EdgeInsets.all(10), itemCount: sortedKeys.length, itemBuilder: (context, index) {
                    String uniName = sortedKeys[index];
                    int score = uniScores[uniName]!;
                    Color rankColor = index == 0 ? Colors.amber : (index == 1 ? Colors.grey.shade400 : (index == 2 ? Colors.brown.shade300 : Colors.grey.shade300));
                    return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: InkWell(onTap: () => _showTeamRankings(context, uniName), borderRadius: BorderRadius.circular(15), child: ListTile(leading: CircleAvatar(backgroundColor: rankColor, child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))), title: Text(uniName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text("Kadroyu gör"), trailing: Text("$score Puan", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 16)))));
                  })),
              Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(children: [
                  const Text("Okulunu Zirveye Taşı!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: mainColor, foregroundColor: Colors.white, shape: const StadiumBorder()), onPressed: () async {
                     final user = FirebaseAuth.instance.currentUser;
                     final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                     if (userDoc.data()?['isVerified'] == true) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaten takımdasın! 🛡️")));
                     } else {
                       // YÖNLENDİRME EKLENDİ
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Ayarlar > Öğrenci Doğrulaması ekranından doğrulama yap.")));
                     }
                  }, icon: const Icon(Icons.verified), label: const Text("Takıma Katıl (Mail Doğrula)")))
              ]))
          ]);
        },
      ),
    );
  }
}

// --- 3. SOHBETLER ---
class MessagesTab extends StatelessWidget {
  final Color mainColor;
  const MessagesTab({super.key, required this.mainColor});
  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Sohbetler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: mainColor),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: myUid).orderBy('lastMessageTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz mesajın yok."));
          final chats = snapshot.data!.docs;
          return ListView.builder(itemCount: chats.length, itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              List<dynamic> participants = chatData['participants'];
              String otherUid = participants.firstWhere((id) => id != myUid);
              Map<String, dynamic> userNames = chatData['userNames'] ?? {};
              Map<String, dynamic> userImages = chatData['userImages'] ?? {};
              String name = userNames[otherUid] ?? "Kullanıcı";
              String img = userImages[otherUid] ?? "https://i.pravatar.cc/150";
              return ListTile(leading: CircleAvatar(backgroundImage: NetworkImage(img)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(chatData['lastMessage'] ?? ""), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(user: {'uid': otherUid, 'name': name, 'img': img}))));
          });
        },
      ),
    );
  }
}

// --- 4. PROFİL (TEMİZLENDİ) ---
class ProfileTab extends StatefulWidget {
  final Color mainColor;
  const ProfileTab({super.key, required this.mainColor});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final TextEditingController _activityCtrl = TextEditingController();
  bool _isPosting = false; 

  Future<void> _sharePost(Map<String, dynamic>? userData) async {
    if (_activityCtrl.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('activities').add({'userId': user!.uid, 'userName': userData?['name'] ?? "Ben", 'userImg': userData?['img'] ?? "https://i.pravatar.cc/150", 'text': _activityCtrl.text.trim(), 'date': Timestamp.now(), 'likes': 0, 'isAutoMatch': false});
    _activityCtrl.clear();
    if(mounted) { setState(() => _isPosting = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paylaşıldı!"))); }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(), builder: (context, userSnapshot) {
      if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const Center(child: CircularProgressIndicator());
      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
      final playerScore = (userData?['playerScore'] ?? "0").toString();
      final uni = userData?['uni'] ?? "Üniversite Girilmedi";
      final isVerified = userData?['isVerified'] == true;
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: Text(userData?['name'] ?? "Profil", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.white, elevation: 0, actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: Icon(Icons.edit, color: widget.mainColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())))
        ]),
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.mainColor, const Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: widget.mainColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]), child: Row(children: [Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(user?.photoURL ?? ""))), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(userData?['name'] ?? "İsimsiz", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), if(isVerified) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: Colors.white, size: 18))]), Text(uni, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.emoji_events, color: Colors.amber, size: 16), const SizedBox(width: 5), Text("Puan: $playerScore", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]))]))])),
            const SizedBox(height: 25),
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [TextField(controller: _activityCtrl, decoration: const InputDecoration(hintText: "Skorunu paylaş...", border: InputBorder.none, icon: Icon(Icons.edit_square, color: Colors.grey))), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey), onPressed: () {}), _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : ElevatedButton.icon(onPressed: () => _sharePost(userData), style: ElevatedButton.styleFrom(backgroundColor: widget.mainColor, foregroundColor: Colors.white, shape: const StadiumBorder()), icon: const Icon(Icons.send, size: 16), label: const Text("Paylaş"))])])),
            const SizedBox(height: 25),
            StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('activities').where('userId', isEqualTo: user?.uid).snapshots(), builder: (context, snap) {
                if(!snap.hasData) return const SizedBox();
                return Column(children: snap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>; 
                  bool isAutoMatch = data.containsKey('isAutoMatch') ? data['isAutoMatch'] : false;
                  return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['text'] ?? ""), if(isAutoMatch) Padding(padding: const EdgeInsets.only(top: 5), child: Text("🏆 Resmi Maç Sonucu", style: TextStyle(color: Colors.amber.shade800, fontSize: 11, fontWeight: FontWeight.bold)))])));
                }).toList());
            })
        ])),
      );
    });
  }
}