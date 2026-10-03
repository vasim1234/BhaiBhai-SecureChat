import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhai Bhai Secure Chat',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

// ============ AUTH WRAPPER ============
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Check karein ki user ka username set hai ya nahi
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.hasData &&
                  userSnapshot.data!.exists &&
                  userSnapshot.data!['username'] != null) {
                // Username set hai, HomeScreen par bhejein
                return const HomeScreen();
              }
              // Username set nahi hai, SetUsernameScreen par bhejein
              return SetUsernameScreen(
                uid: snapshot.data!.uid,
                email: snapshot.data!.email ?? '',
              );
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}

// ============ LOGIN / SIGNUP SCREEN ============
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email aur Password dono bharein')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Signup
        UserCredential credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Signup ke baad username set karne ki screen par bhejein
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SetUsernameScreen(uid: credential.user!.uid, email: credential.user!.email!),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error aaya';
      if (e.code == 'user-not-found') message = 'Ye email registered nahi hai';
      if (e.code == 'wrong-password') message = 'Password galat hai';
      if (e.code == 'email-already-in-use') message = 'Ye email pehle se registered hai';
      if (e.code == 'weak-password') message = 'Password kam se kam 6 characters ka hona chahiye';
      if (e.code == 'invalid-email') message = 'Email sahi nahi hai';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Bhai Bhai Secure Chat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '24-hour ephemeral chat & calling app',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? 'Naya account banayein? Sign Up'
                      : 'Pehle se account hai? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SET USERNAME SCREEN ============
class SetUsernameScreen extends StatefulWidget {
  final String uid;
  final String email;

  const SetUsernameScreen({super.key, required this.uid, required this.email});

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveUsername() async {
    String username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username khali nahi ho sakta')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Check karein ki username pehle se exist karta hai ya nahi
    QuerySnapshot existing = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ye username pehle se le liya gaya hai')),
      );
      return;
    }

    // User data save karein
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'uid': widget.uid,
      'email': widget.email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Username')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Apna unique username set karein',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Is username se dusre log aapko dhundh sakte hain',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (jaise: vasim123)',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveUsername,
                    child: const Text('Save Username'),
                  ),
          ],
        ),
      ),
    );
  }
}

// ============ HOME SCREEN ============
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const SearchUserScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============ CHATS LIST ============
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bhai Bhai Chats')),
      body: const Center(
        child: Text('Abhi koi chat nahi hai.\nSearch tab se user dhundhein!'),
      ),
    );
  }
}

// ============ SEARCH USER ============
class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});
  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _searchUser() async {
    String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      _results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((user) => user['uid'] != FirebaseAuth.instance.currentUser!.uid)
          .toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Username se search karein...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: _searchUser),
              ],
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(child: Text('Username daal kar search karein'))
                    : _results.isEmpty
                        ? const Center(child: Text('Koi user nahi mila'))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(user['username'] ?? 'Unknown'),
                                subtitle: Text(user['email'] ?? ''),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        receiverUid: user['uid'],
                                        receiverName: user['username'] ?? 'User',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ============ PROFILE ============
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
        builder: (context, snapshot) {
          String username = 'Loading...';
          if (snapshot.hasData && snapshot.data!.exists) {
            username = snapshot.data!['username'] ?? 'Not set';
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 20),
                Text('@$username',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(user.email ?? 'No Email',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============ CHAT SCREEN ============
class ChatScreen extends StatefulWidget {
  final String receiverUid;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverUid,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String get chatId {
    List<String> uids = [currentUserId, widget.receiverUid];
    uids.sort();
    return uids.join('_');
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('chats').add({
      'chatId': chatId,
      'senderId': currentUserId,
      'receiverId': widget.receiverUid,
      'message': _msgController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryTime),
    });

    _msgController.clear();
  }

  Stream<QuerySnapshot> _getMessages() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling feature jald aa raha hai!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessages(),
              builder: (context, snapshot) {
  if (snapshot.hasError) {
    return Center(
      child: Text('Error: ${snapshot.error}'),
    );
  }
  if (!snapshot.hasData) {
    return const Center(child: CircularProgressIndicator());
  }

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  Timestamp expiresAt = data['expiresAt'];
                  return expiresAt.toDate().isAfter(DateTime.now());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Abhi koi message nahi hai. Hi bhejein!'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['message'] ?? ''),
                            const SizedBox(height: 4),
                            const Text('Auto-delete in 24h',
                                style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Message likhein...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
