import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'friend_request.dart';
import 'user_profile.dart';
import 'avatar_builder.dart';
import 'dart:typed_data';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  OneSignal.initialize("YOUR_ONESIGNAL_APP_ID");
  OneSignal.Notifications.requestPermission(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhai Bhai Secure Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
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
                return const HomeScreen();
              }
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

// ============ LOGIN SCREEN ============
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SetUsernameScreen(
                uid: credential.user!.uid,
                email: credential.user!.email!,
              ),
            ),
          );
        }
      }

      // *** OneSignal Login (Notification ke liye) ***
      await OneSignal.login(FirebaseAuth.instance.currentUser!.uid);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.code} - ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bhai Bhai',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Secure Community',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667EEA),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Login' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? 'Naya account banayein? Sign Up'
                                : 'Pehle se account hai? Login',
                            style: const TextStyle(color: Color(0xFF667EEA)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

    try {
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
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alternate_email, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Apna Username Set Karein',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Is username se dusre log aapko dhundh sakte hain',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username (jaise: vasim123)',
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveUsername,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667EEA),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Save Username',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ HOME SCREEN (With Online Status) ============
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const UpdatesScreen(),
    const CommunitiesScreen(),
    const CallsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else {
      _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.update), label: 'Updates'),
            BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined), label: 'Communities'),
            BottomNavigationBarItem(
                icon: Icon(Icons.call_outlined), label: 'Calls'),
          ],
        ),
      ),
    );
  }
}

// ============ CHATS LIST SCREEN ============
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<String> _pinnedChats = [];

  @override
  void initState() {
    super.initState();
    _loadPinnedChats();
  }

  Future<void> _loadPinnedChats() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    if (userDoc.exists && userDoc['pinnedChats'] != null) {
      setState(() {
        _pinnedChats = List<String>.from(userDoc['pinnedChats']);
      });
    }
  }

  Future<void> _togglePin(String chatId) async {
    if (_pinnedChats.contains(chatId)) {
      _pinnedChats.remove(chatId);
    } else {
      _pinnedChats.add(chatId);
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'pinnedChats': _pinnedChats});
    setState(() {});
  }

  void _showChatOptions(String chatId, String otherUserId, String username) {
    bool isPinned = _pinnedChats.contains(chatId);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: const Color(0xFF667EEA)),
                title: Text(isPinned ? 'Unpin Chat' : 'Pin Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePin(chatId);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BHAI BHAI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    _buildFilterChip('Unread', false),
                    _buildFilterChip('Favourites', false),
                    _buildFilterChip('Groups', false),
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, Map<String, dynamic>> chats = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String chatId = data['chatId'] ?? '';
            if (chatId.isNotEmpty) {
              if (!chats.containsKey(chatId) ||
                  (data['timestamp'] != null &&
                      (chats[chatId]!['timestamp'] == null ||
                          data['timestamp']
                              .compareTo(chats[chatId]!['timestamp']) > 0))) {
                chats[chatId] = data;
              }
            }
          }

          if (chats.isEmpty) {
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
                    child: const Icon(Icons.chat_bubble_outline,
                        size: 60, color: Color(0xFF667EEA)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Abhi koi chat nahi hai',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Search icon se user dhundhein!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> chatList = chats.values.toList();
          chatList.sort((a, b) {
            String aId = a['chatId'];
            String bId = b['chatId'];
            bool aPin = _pinnedChats.contains(aId);
            bool bPin = _pinnedChats.contains(bId);
            if (aPin && !bPin) return -1;
            if (!aPin && bPin) return 1;
            Timestamp? ta = a['timestamp'];
            Timestamp? tb = b['timestamp'];
            if (ta == null || tb == null) return 0;
            return tb.compareTo(ta);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              var chat = chatList[index];
              String chatId = chat['chatId'];

              List<String> uids = chatId.split('_');
              String otherUserId = '';
              for (String uid in uids) {
                if (uid != currentUserId) {
                  otherUserId = uid;
                  break;
                }
              }

              String lastMessage = chat['message'] ?? '';
              Timestamp? timestamp = chat['timestamp'];
              bool isPinned = _pinnedChats.contains(chatId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  String username = 'User';
                  String? avatarUrl;
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    username = userSnapshot.data!['username'] ?? 'User';
                    avatarUrl = userSnapshot.data!['avatarUrl'];
                  }

                  return GestureDetector(
                    onLongPress: () =>
                        _showChatOptions(chatId, otherUserId, username),
                    child: Card(
                      elevation: 0,
                      margin:
                          const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        leading: AvatarWidget(
                          avatarUrl: avatarUrl,
                          username: username,
                          size: 50,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                username,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isPinned)
                              const Icon(Icons.push_pin,
                                  size: 16, color: Color(0xFF667EEA)),
                          ],
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: timestamp != null
                            ? Text(
                                DateFormat('hh:mm a').format(timestamp.toDate()),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                receiverUid: otherUserId,
                                receiverName: username,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667EEA),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchUserScreen()),
          );
        },
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF667EEA).withOpacity(0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// ============ CREATE GROUP SCREEN ============
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _selectedUsers = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUsers = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((user) =>
              user['uid'] != FirebaseAuth.instance.currentUser!.uid)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group ka naam likhein')),
      );
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek member select karein')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      List<String> members = [currentUserId, ..._selectedUsers];

      DocumentReference groupRef =
          await FirebaseFirestore.instance.collection('groups').add({
        'name': _groupNameController.text.trim(),
        'members': members,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group ban gaya!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: groupRef.id,
              groupName: _groupNameController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const CircularProgressIndicator()
                : const Text('Create',
                    style: TextStyle(
                        color: Color(0xFF667EEA), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group ka naam',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Members select karein:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      String uid = user['uid'];
                      bool isSelected = _selectedUsers.contains(uid);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUsers.add(uid);
                            } else {
                              _selectedUsers.remove(uid);
                            }
                          });
                        },
                        secondary: AvatarWidget(
                          avatarUrl: user['avatarUrl'],
                          username: user['username'] ?? 'User',
                          size: 45,
                        ),
                        title: Text(user['username'] ?? 'Unknown',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user['email'] ?? ''),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ============ GROUP CHAT SCREEN ============
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isUploading = false;

  Future<void> _sendMessage({String? imageBase64}) async {
    if (_msgController.text.trim().isEmpty && imageBase64 == null) return;

    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('group_messages').add({
      'groupId': widget.groupId,
      'senderId': currentUserId,
      'message': _msgController.text.trim(),
      'imageBase64': imageBase64,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryTime),
    });

    _msgController.clear();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 20,
        minWidth: 400,
        minHeight: 400,
      );
      if (compressedFile == null) {
        setState(() => _isUploading = false);
        return;
      }
      final compressedBytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(compressedBytes);
      if (base64Image.length > 900000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo bahut badi hai')),
        );
        setState(() => _isUploading = false);
        return;
      }
      await _sendMessage(imageBase64: base64Image);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isUploading = false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Photo Bhejein'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.group, color: Color(0xFF667EEA)),
            ),
            const SizedBox(width: 10),
            Text(widget.groupName,
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_messages')
                  .where('groupId', isEqualTo: widget.groupId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                  return const Center(child: Text('Group mein message bhejein!'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    String? imageBase64 = data['imageBase64'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(data['senderId'])
                          .get(),
                      builder: (context, userSnap) {
                        String senderName = 'User';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          senderName = userSnap.data!['username'] ?? 'User';
                        }
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2)
                                      ],
                                    )
                                  : null,
                              color: isMe ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: Radius.circular(isMe ? 15 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF667EEA),
                                    ),
                                  ),
                                if (imageBase64 != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(imageBase64),
                                      width: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (data['message'] != null &&
                                    (data['message'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      data['message'],
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Auto-delete in 24h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isMe ? Colors.white70 : Colors.grey,
                                  ),
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
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF667EEA)),
                  onPressed: _isUploading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Message likhein...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ UPDATES SCREEN ============
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: const Center(child: Text('Status updates jald aa rahe hain!')),
    );
  }
}

// ============ COMMUNITIES SCREEN ============
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: const Center(child: Text('Communities feature jald aa raha hai!')),
    );
  }
}

// ============ CALLS SCREEN ============
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: const Center(child: Text('Call history jald aa rahi hai!')),
    );
  }
}

// ============ SEARCH USER SCREEN ============
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
          .where((user) =>
              user['uid'] != FirebaseAuth.instance.currentUser!.uid)
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
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Username se search karein...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _searchUser(),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Text('Username daal kar search karein'))
                    : _results.isEmpty
                        ? const Center(child: Text('Koi user nahi mila'))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: AvatarWidget(
                                    avatarUrl: user['avatarUrl'],
                                    username: user['username'] ?? 'User',
                                    size: 45,
                                  ),
                                  title: Text(
                                    user['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(user['email'] ?? ''),
                                  trailing: const Icon(
                                    Icons.person_add,
                                    color: Color(0xFF667EEA),
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserProfileScreen(
                                          userId: user['uid'],
                                          username:
                                              user['username'] ?? 'User',
                                        ),
                                      ),
                                    );

                                    if (result != null &&
                                        result is Map &&
                                        result['action'] == 'chat') {
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              receiverUid: result['uid'],
                                              receiverName: result['name'],
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ============ PROFILE SCREEN (With Avatar Builder) ============
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarUrl;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && doc['avatarUrl'] != null) {
      setState(() {
        _avatarUrl = doc['avatarUrl'];
        _isLoadingAvatar = false;
      });
    } else {
      setState(() => _isLoadingAvatar = false);
    }
  }

  Future<void> _openAvatarBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AvatarBuilderScreen(),
      ),
    );
    if (result != null) {
      setState(() => _avatarUrl = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          String username = 'Loading...';
          String memberSince = 'Oct 2026';
          if (snapshot.hasData && snapshot.data!.exists) {
            username = snapshot.data!['username'] ?? 'Not set';
            if (snapshot.data!['createdAt'] != null) {
              Timestamp ts = snapshot.data!['createdAt'];
              memberSince = DateFormat('MMM yyyy').format(ts.toDate());
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _openAvatarBuilder,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2)
                                  ],
                                ),
                              ),
                              child: _isLoadingAvatar
                                  ? const CircleAvatar(
                                      radius: 45,
                                      backgroundColor: Colors.white,
                                      child: CircularProgressIndicator(),
                                    )
                                  : AvatarWidget(
                                      avatarUrl: _avatarUrl,
                                      username: username,
                                      size: 90,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF667EEA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            user.email ?? 'No Email',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showQRDialog(context, username, user.uid);
                              },
                              icon: const Icon(Icons.qr_code,
                                  color: Color(0xFF667EEA)),
                              label: const Text('My QR',
                                  style:
                                      TextStyle(color: Color(0xFF667EEA))),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(
                                    color: Color(0xFF667EEA)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  FirebaseAuth.instance.signOut(),
                              icon: const Icon(Icons.logout,
                                  color: Colors.white),
                              label: const Text('Logout',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('receiverId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, reqSnap) {
                    int count = reqSnap.hasData ? reqSnap.data!.docs.length : 0;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FriendRequestsScreen(),
                            ),
                          );
                        },
                        icon: Stack(
                          children: [
                            const Icon(Icons.person_add),
                            if (count > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: Text(
                            'Friend Requests${count > 0 ? ' ($count)' : ''}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                FutureBuilder<Map<String, int>>(
                  future: _loadStats(user.uid),
                  builder: (context, statsSnapshot) {
                    int contacts = 0;
                    int chats = 0;
                    int blocked = 0;

                    if (statsSnapshot.hasData) {
                      contacts = statsSnapshot.data!['contacts'] ?? 0;
                      chats = statsSnapshot.data!['chats'] ?? 0;
                      blocked = statsSnapshot.data!['blocked'] ?? 0;
                    }

                    return Row(
                      children: [
                        _buildStatCard(
                          Icons.people,
                          '$contacts',
                          'Contacts',
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FriendsListScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          Icons.chat_bubble,
                          '$chats',
                          'Chats',
                          Colors.purple,
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          Icons.lock,
                          '$blocked',
                          'Blocked',
                          Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BlockedUsersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildSettingRow('Username', '@$username', Colors.grey),
                      const Divider(),
                      _buildSettingRow(
                          'Account Status', 'Active', Colors.green),
                      const Divider(),
                      _buildSettingRow(
                          'Member Since', memberSince, Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bhai Bhai App v1.0.0 • Secure Community',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _loadStats(String uid) async {
    int contacts = 0;
    int chats = 0;
    int blocked = 0;

    try {
      QuerySnapshot chatsSnap = await FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: uid)
          .get();

      Set<String> contactIds = {};
      for (var doc in chatsSnap.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? chatId = data['chatId'];
        if (chatId != null) {
          List<String> uids = chatId.split('_');
          for (String id in uids) {
            if (id != uid) contactIds.add(id);
          }
        }
      }
      contacts = contactIds.length;
      chats = chatsSnap.docs.length;

      QuerySnapshot blockedSnap = await FirebaseFirestore.instance
          .collection('blocked')
          .where('blockerId', isEqualTo: uid)
          .get();
      blocked = blockedSnap.docs.length;
    } catch (e) {
      // Ignore
    }

    return {'contacts': contacts, 'chats': chats, 'blocked': blocked};
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(BuildContext context, String username, String uid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Your QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: uid,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text('@$username',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              const Text('Scan to connect',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// ============ CONTACTS LIST SCREEN ============
class ContactsListScreen extends StatelessWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Set<String> contactIds = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String? chatId = data['chatId'];
            if (chatId != null) {
              List<String> uids = chatId.split('_');
              for (String id in uids) {
                if (id != currentUserId) contactIds.add(id);
              }
            }
          }

          if (contactIds.isEmpty) {
            return const Center(
              child: Text('Abhi koi contact nahi hai.\nSearch karke chat shuru karein!'),
            );
          }

          return ListView.builder(
            itemCount: contactIds.length,
            itemBuilder: (context, index) {
              String uid = contactIds.elementAt(index);
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnap) {
                  String username = 'User';
                  String? avatarUrl;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    username = userSnap.data!['username'] ?? 'User';
                    avatarUrl = userSnap.data!['avatarUrl'];
                  }
                  return ListTile(
                    leading: AvatarWidget(
                      avatarUrl: avatarUrl,
                      username: username,
                      size: 50,
                    ),
                    title: Text(username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverUid: uid,
                            receiverName: username,
                          ),
                        ),
                      );
                    },
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

// ============ BLOCKED USERS SCREEN ============
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _unblock(String blockedId) async {
    await FirebaseFirestore.instance
        .collection('blocked')
        .doc('${currentUserId}_$blockedId')
        .delete();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User unblocked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blocked')
            .where('blockerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Koi user blocked nahi hai'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String blockedId = data['blockedId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(blockedId).get(),
                builder: (context, userSnap) {
                  String username = 'User';
                  String? avatarUrl;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    username = userSnap.data!['username'] ?? 'User';
                    avatarUrl = userSnap.data!['avatarUrl'];
                  }
                  return ListTile(
                    leading: AvatarWidget(
                      avatarUrl: avatarUrl,
                      username: username,
                      size: 50,
                    ),
                    title: Text(username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: TextButton(
                      onPressed: () => _unblock(blockedId),
                      child: const Text('Unblock',
                          style: TextStyle(color: Color(0xFF667EEA))),
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

// ============ CHAT SCREEN (With Notification + Typing + Reply + Read Receipts) ============
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
  bool _isUploading = false;
  bool _isBlocked = false;
  bool _isBlockedByOther = false;
  bool _areFriends = false;
  bool _isLoadingFriends = true;
  String? _receiverAvatarUrl;
  Map<String, dynamic>? _replyToData;
  bool _isReceiverTyping = false;
  bool _isReceiverOnline = false;

  final Map<String, Uint8List> _imageCache = {};

  // ============ OneSignal Config ============
  static const String ONESIGNAL_APP_ID = 'YOUR_ONESIGNAL_APP_ID';
  static const String ONESIGNAL_REST_API_KEY = 'YOUR_REST_API_KEY';

  String get chatId {
    List<String> uids = [currentUserId, widget.receiverUid];
    uids.sort();
    return uids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
    _checkFriendStatus();
    _loadReceiverAvatar();
    _markMessagesAsRead();
    _listenToTypingStatus();
    _listenToOnlineStatus();
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    super.dispose();
  }

  // ============ NOTIFICATION BHEJEIN ============
  Future<void> _sendNotification(String message) async {
    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $ONESIGNAL_REST_API_KEY',
        },
        body: jsonEncode({
          'app_id': ONESIGNAL_APP_ID,
          'include_aliases': {
            'external_id': [widget.receiverUid],
          },
          'target_channel': 'push',
          'headings': {'en': 'Bhai Bhai'},
          'contents': {
            'en': message.isNotEmpty ? message : 'Photo bheji',
          },
        }),
      );
    } catch (e) {
      // Notification fail ho gayi toh kuch nahi karein
    }
  }

  // ============ TYPING INDICATOR ============
  void _listenToTypingStatus() {
    FirebaseFirestore.instance
        .collection('typing')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        bool isTyping = data[widget.receiverUid] ?? false;
        if (mounted) {
          setState(() => _isReceiverTyping = isTyping);
        }
      }
    });
  }

  Future<void> _setTypingStatus(bool isTyping) async {
    await FirebaseFirestore.instance
        .collection('typing')
        .doc(chatId)
        .set({currentUserId: isTyping}, SetOptions(merge: true));
  }

  // ============ ONLINE STATUS ============
  void _listenToOnlineStatus() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        bool isOnline = snapshot.data()!['isOnline'] ?? false;
        if (mounted) {
          setState(() => _isReceiverOnline = isOnline);
        }
      }
    });
  }

  // ============ BAQI FUNCTIONS ============
  Future<void> _markMessagesAsRead() async {
    await Future.delayed(const Duration(seconds: 1));

    QuerySnapshot messages = await FirebaseFirestore.instance
        .collection('chats')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(doc.id)
          .update({'isRead': true});
    }
  }

  Future<void> _loadReceiverAvatar() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUid)
        .get();
    if (doc.exists && doc['avatarUrl'] != null) {
      setState(() => _receiverAvatarUrl = doc['avatarUrl']);
    }
  }

  Future<void> _checkFriendStatus() async {
    bool isFriend = await areFriends(currentUserId, widget.receiverUid);
    setState(() {
      _areFriends = isFriend;
      _isLoadingFriends = false;
    });
  }

  Future<void> _checkBlockStatus() async {
    DocumentSnapshot myBlock = await FirebaseFirestore.instance
        .collection('blocked')
        .doc('${currentUserId}_${widget.receiverUid}')
        .get();
    DocumentSnapshot otherBlock = await FirebaseFirestore.instance
        .collection('blocked')
        .doc('${widget.receiverUid}_$currentUserId')
        .get();
    setState(() {
      _isBlocked = myBlock.exists;
      _isBlockedByOther = otherBlock.exists;
    });
  }

  Future<void> _toggleBlock() async {
    if (_isBlocked) {
      await FirebaseFirestore.instance
          .collection('blocked')
          .doc('${currentUserId}_${widget.receiverUid}')
          .delete();
      setState(() => _isBlocked = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User unblocked')));
    } else {
      await FirebaseFirestore.instance
          .collection('blocked')
          .doc('${currentUserId}_${widget.receiverUid}')
          .set({
        'blockerId': currentUserId,
        'blockedId': widget.receiverUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _isBlocked = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User blocked')));
    }
  }

  Future<void> _sendMessage(
      {String? imageBase64, Map<String, dynamic>? replyTo}) async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aapne is user ko block kiya hai')),
      );
      return;
    }
    if (!_areFriends) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle friend request accept karwa lein!')),
      );
      return;
    }
    if (_msgController.text.trim().isEmpty && imageBase64 == null) return;

    String messageText = _msgController.text.trim();
    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));

    List<String> members = [currentUserId, widget.receiverUid];
    members.sort();

    await FirebaseFirestore.instance.collection('chats').add({
      'chatId': chatId,
      'members': members,
      'senderId': currentUserId,
      'receiverId': widget.receiverUid,
      'message': messageText,
      'imageBase64': imageBase64,
      'replyTo': replyTo,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryTime),
      'isEdited': false,
      'isDeleted': false,
      'isRead': false,
    });

    // *** Notification bhejein ***
    await _sendNotification(messageText);

    _msgController.clear();
    _setTypingStatus(false);
  }

  Future<void> _deleteMessage(String docId) async {
    await FirebaseFirestore.instance.collection('chats').doc(docId).update({
      'isDeleted': true,
      'message': 'Ye message delete kar diya gaya hai',
      'imageBase64': null,
    });
  }

  Future<void> _editMessage(String docId, String oldMessage) async {
    TextEditingController editController =
        TextEditingController(text: oldMessage);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Naya message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(docId)
                      .update({
                    'message': editController.text.trim(),
                    'isEdited': true,
                  });
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(
      String docId, String message, bool isMe, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.reply, color: Color(0xFF667EEA)),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyToData = {
                      'message': message,
                      'senderName': isMe ? 'Aap' : widget.receiverName,
                      'senderId': data['senderId'],
                    };
                  });
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(docId, message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(docId);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (image == null) return;
    setState(() => _isUploading = true);

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 20,
        minWidth: 400,
        minHeight: 400,
      );

      if (compressedFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      final compressedBytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(compressedBytes);

      if (base64Image.length > 900000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo bahut badi hai, chhoti photo try karein')),
        );
        setState(() => _isUploading = false);
        return;
      }

      await _sendMessage(imageBase64: base64Image, replyTo: _replyToData);
      setState(() => _replyToData = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isUploading = false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Photo Bhejein'),
                subtitle: const Text('Auto compress hokar jayegi'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCachedImage(String base64String) {
    if (_imageCache.containsKey(base64String)) {
      return Image.memory(
        _imageCache[base64String]!,
        width: 200,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    try {
      final bytes = base64Decode(base64String);
      _imageCache[base64String] = bytes;
      return Image.memory(
        bytes,
        width: 200,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } catch (e) {
      return const SizedBox(
        width: 200,
        height: 150,
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }
  }

  Stream<QuerySnapshot> _getMessages() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF667EEA),
        iconTheme: const IconThemeData(color: Colors.white),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: widget.receiverUid,
                  username: widget.receiverName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarWidget(
                    avatarUrl: _receiverAvatarUrl,
                    username: widget.receiverName,
                    size: 40,
                  ),
                  if (_isReceiverOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.receiverName,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  if (_isReceiverTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (_isReceiverOnline)
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling feature jald aa raha hai!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(_isBlocked ? Icons.lock_open : Icons.block,
                        color: _isBlocked ? Colors.green : Colors.red),
                    const SizedBox(width: 10),
                    Text(_isBlocked ? 'Unblock User' : 'Block User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.red.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Aapne is user ko block kiya hua hai',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          if (_isBlockedByOther)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.orange.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text('Is user ne aapko block kiya hua hai',
                      style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          if (!_areFriends && !_isLoadingFriends)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.blue.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text('Pehle friend request accept karwa lein',
                      style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                  return const Center(
                      child: Text('Abhi koi message nahi hai. Hi bhejein!'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    bool isDeleted = data['isDeleted'] ?? false;
                    bool isEdited = data['isEdited'] ?? false;
                    bool isRead = data['isRead'] ?? false;
                    String? imageBase64 = data['imageBase64'];
                    Map<String, dynamic>? replyTo = data['replyTo'];

                    return GestureDetector(
                      onLongPress: isDeleted
                          ? null
                          : () => _showMessageOptions(
                              doc.id, data['message'] ?? '', isMe, data),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: isMe && !isDeleted
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2)
                                    ],
                                  )
                                : null,
                            color: isDeleted
                                ? Colors.grey[200]
                                : (isMe ? null : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(15),
                              topRight: const Radius.circular(15),
                              bottomLeft: Radius.circular(isMe ? 15 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (replyTo != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 5),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: isMe
                                            ? Colors.white
                                            : const Color(0xFF667EEA),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        replyTo['senderName'] ?? 'User',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? Colors.white
                                              : const Color(0xFF667EEA),
                                        ),
                                      ),
                                      Text(
                                        replyTo['message'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (imageBase64 != null && !isDeleted)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildCachedImage(imageBase64),
                                ),
                              if (data['message'] != null &&
                                  (data['message'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    data['message'],
                                    style: TextStyle(
                                      color: isDeleted
                                          ? Colors.grey[600]
                                          : (isMe
                                              ? Colors.white
                                              : Colors.black87),
                                      fontSize: 16,
                                      fontStyle: isDeleted
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEdited && !isDeleted)
                                    Text(
                                      'edited • ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                  Text(
                                    'Auto-delete in 24h',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe && !isDeleted
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                  ),
                                  if (isMe && !isDeleted)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Icon(
                                        isRead ? Icons.done_all : Icons.done,
                                        size: 14,
                                        color: isRead
                                            ? Colors.lightBlue
                                            : Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Column(
              children: [
                if (_replyToData != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                        left: BorderSide(
                          color: Color(0xFF667EEA),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _replyToData!['senderName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              Text(
                                _replyToData!['message'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _replyToData = null);
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file,
                          color: Color(0xFF667EEA)),
                      onPressed: (_isUploading || _isBlocked)
                          ? null
                          : _showAttachmentOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        enabled: !_isBlocked && _areFriends,
                        onChanged: (value) {
                          _setTypingStatus(value.isNotEmpty);
                        },
                        decoration: InputDecoration(
                          hintText: _isBlocked
                              ? 'Aapne is user ko block kiya hai'
                              : (!_areFriends
                                  ? 'Pehle friend request accept karwa lein'
                                  : 'Message likhein...'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (_isBlocked || !_areFriends)
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2)
                                ],
                              ),
                        color:
                            (_isBlocked || !_areFriends) ? Colors.grey : null,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: (_isBlocked || !_areFriends)
                            ? null
                            : () async {
                                await _sendMessage(replyTo: _replyToData);
                                setState(() => _replyToData = null);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
