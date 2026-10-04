import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============ FRIEND REQUEST SYSTEM ============
// Ye file handle karti hai:
// 1. Friend request bhejna
// 2. Request accept/reject karna
// 3. Friends list dikhana

// ============ SEND FRIEND REQUEST ============
Future<String> sendFriendRequest(String receiverUid) async {
  String senderUid = FirebaseAuth.instance.currentUser!.uid;

  if (senderUid == receiverUid) {
    return 'Aap khud ko request nahi bhej sakte';
  }

  // Check karein ki pehle se request hai ya nahi
  QuerySnapshot existing = await FirebaseFirestore.instance
      .collection('friend_requests')
      .where('senderId', isEqualTo: senderUid)
      .where('receiverId', isEqualTo: receiverUid)
      .get();

  if (existing.docs.isNotEmpty) {
    return 'Aapne pehle hi request bhej rakhi hai';
  }

  // Check karein ki wo pehle se friend hai ya nahi
  DocumentSnapshot friendship = await FirebaseFirestore.instance
      .collection('friends')
      .doc('${senderUid}_$receiverUid')
      .get();

  if (friendship.exists) {
    return 'Ye pehle se aapka friend hai';
  }

  // Request bhejein
  await FirebaseFirestore.instance.collection('friend_requests').add({
    'senderId': senderUid,
    'receiverId': receiverUid,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  });

  return 'success';
}

// ============ ACCEPT FRIEND REQUEST ============
Future<void> acceptFriendRequest(String requestId, String senderId) async {
  String currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Request ka status update karein
  await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(requestId)
      .update({'status': 'accepted'});

  // Friends collection mein add karein (dono taraf)
  await FirebaseFirestore.instance
      .collection('friends')
      .doc('${currentUid}_$senderId')
      .set({
    'uid1': currentUid,
    'uid2': senderId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await FirebaseFirestore.instance
      .collection('friends')
      .doc('${senderId}_$currentUid')
      .set({
    'uid1': senderId,
    'uid2': currentUid,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// ============ REJECT FRIEND REQUEST ============
Future<void> rejectFriendRequest(String requestId) async {
  await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(requestId)
      .update({'status': 'rejected'});
}

// ============ CHECK IF FRIENDS ============
Future<bool> areFriends(String uid1, String uid2) async {
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('friends')
      .doc('${uid1}_$uid2')
      .get();
  return doc.exists;
}

// ============ FRIEND REQUESTS SCREEN ============
class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('receiverId', isEqualTo: currentUid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add,
                        size: 60, color: Color(0xFF667EEA)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Koi friend request nahi hai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Search tab se naye users ko add karein!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String senderId = data['senderId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderId)
                    .get(),
                builder: (context, userSnap) {
                  String username = 'User';
                  String email = '';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    username = userSnap.data!['username'] ?? 'User';
                    email = userSnap.data!['email'] ?? '';
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF667EEA),
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                            onPressed: () async {
                              await acceptFriendRequest(doc.id, senderId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Friend request accept ho gayi!')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              await rejectFriendRequest(doc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Friend request reject kar di')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ============ FRIENDS LIST SCREEN ============
class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .where('uid1', isEqualTo: currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people,
                        size: 60, color: Color(0xFF667EEA)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Abhi koi friend nahi hai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Search tab se naye users ko add karein!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String friendId = data['uid2'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, userSnap) {
                  String username = 'User';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    username = userSnap.data!['username'] ?? 'User';
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF667EEA),
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF667EEA)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
// ============ UNFRIEND ============
Future<void> unFriend(String otherUid) async {
  String currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Friends collection se dono documents delete karein
  await FirebaseFirestore.instance
      .collection('friends')
      .doc('${currentUid}_$otherUid')
      .delete();
  await FirebaseFirestore.instance
      .collection('friends')
      .doc('${otherUid}_$currentUid')
      .delete();

  // Friend requests bhi clean kar dein
  QuerySnapshot requests = await FirebaseFirestore.instance
      .collection('friend_requests')
      .where('senderId', whereIn: [currentUid, otherUid])
      .where('receiverId', whereIn: [currentUid, otherUid])
      .get();
  for (var doc in requests.docs) {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(doc.id)
        .delete();
  }
}
