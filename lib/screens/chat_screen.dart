import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user; // Konuştuğun kişinin bilgileri
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color _mainGreen = const Color(0xFF1B5E20);

  late String chatId;
  late String myUid;

  @override
  void initState() {
    super.initState();
    myUid = _auth.currentUser!.uid;
    final otherUid = widget.user['uid'];
    // Benzersiz Chat ID
    chatId = myUid.compareTo(otherUid) < 0 ? "${myUid}_$otherUid" : "${otherUid}_$myUid";
  }

  // --- GÜNCELLENEN MESAJ GÖNDERME ---
  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    
    final msg = _msgCtrl.text.trim();
    _msgCtrl.clear();
    final otherUid = widget.user['uid'];

    // 1. Mesajı Kaydet
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'text': msg,
      'senderId': myUid,
      'date': FieldValue.serverTimestamp(),
    });

    // 2. Sohbet Listesi İçin "Son Mesajı" Güncelle (ÖNEMLİ!)
    // Bu sayede "Sohbetler" sekmesinde bu konuşmayı görebileceğiz.
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [myUid, otherUid], // Kimler konuşuyor?
      'lastMessage': msg,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'userNames': {
        myUid: _auth.currentUser?.displayName ?? "Ben",
        otherUid: widget.user['name'] ?? "Kullanıcı"
      },
      'userImages': {
        myUid: _auth.currentUser?.photoURL ?? "",
        otherUid: widget.user['img'] ?? ""
      }
    }, SetOptions(merge: true));
  }

  // --- MAÇ SONUCU GİRME ---
  void _showMatchResultDialog() {
    String selectedGame = "Okey 101";
    final scoreCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(children: [Icon(Icons.emoji_events, color: Colors.amber), SizedBox(width: 10), Text("Maç Sonucu")]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Sonucu gir, puanı kap!"),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedGame,
                items: ["Okey 101", "Düz Okey", "Batak", "Tavla", "52", "LoL", "Valorant"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => selectedGame = v!,
              ),
              TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: "Skor (Örn: 3-1)", hintText: "Sonucu yaz")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _mainGreen, foregroundColor: Colors.white),
              onPressed: () { _saveMatchResult(selectedGame, scoreCtrl.text); Navigator.pop(context); },
              child: const Text("ONAYLA"),
            )
          ],
        );
      },
    );
  }

  Future<void> _saveMatchResult(String game, String result) async {
    if (result.isEmpty) return;
    try {
      final userRef = _firestore.collection('users').doc(myUid);
      final userSnap = await userRef.get();
      int currentScore = int.tryParse(userSnap.data()?['playerScore']?.toString() ?? "0") ?? 0;
      
      await userRef.update({'playerScore': (currentScore + 25).toString()}); // Puan Ver

      await _firestore.collection('activities').add({
        'userId': myUid,
        'userName': userSnap.data()?['name'] ?? "Ben",
        'userImg': userSnap.data()?['img'] ?? "",
        'text': "🏆 $game maçında ${widget.user['name']} karşısında skor: $result. (+25 Puan)",
        'date': Timestamp.now(),
        'likes': 0,
        'isAutoMatch': true,
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Puanın işlendi! 🚀")));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: _mainGreen,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.user['img'] ?? "https://i.pravatar.cc/150"), radius: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.user['name'], style: const TextStyle(fontSize: 16, color: Colors.white))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.emoji_events, color: Colors.amber), onPressed: _showMatchResultDialog),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chats').doc(chatId).collection('messages').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(color: isMe ? _mainGreen : Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(msgData['text'] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10), color: Colors.white,
            child: Row(children: [
              Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: "Mesaj yaz...", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              CircleAvatar(backgroundColor: _mainGreen, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage))
            ]),
          )
        ],
      ),
    );
  }
}