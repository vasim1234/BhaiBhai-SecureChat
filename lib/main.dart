import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'friend_request.dart';
import 'user_profile.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'avatar_builder.dart';
import 'group_info.dart';
import 'status_screen.dart';
import 'khata_screen.dart';
import 'chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  OneSignal.initialize("05bee600-4a45-44e5-b35e-5328544c25c1");
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
  bool _obscurePassword = true;

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

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle email daalein')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link bhej di!')),
      );
    } catch (e) {
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
            colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
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
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 30,
                            left: 20,
                            child: Container(
                              width: 50,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A6CF7),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(2),
                                ),
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 30,
                            right: 20,
                            child: Container(
                              width: 55,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(2),
                                ),
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Bhai Bhai',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Secure Community',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 25,
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
                            hintText: 'you@example.com',
                            labelStyle: const TextStyle(
                              color: Color(0xFF4A6CF7),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(0xFF4A6CF7)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4A6CF7), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4A6CF7), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            labelStyle: const TextStyle(
                              color: Color(0xFF4A6CF7),
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(0xFF4A6CF7)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4A6CF7), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFF4A6CF7), width: 2),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF4A6CF7),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4A6CF7),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Login' : 'Sign Up',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                  color: Colors.grey[300], thickness: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Google Sign-In jald aa raha hai!'),
                                ),
                              );
                            },
                            icon: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 1),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.grey[300]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Login',
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
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
                  const Icon(Icons.alternate_email,
                      size: 80, color: Colors.white),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Save Username',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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

// ============ HOME SCREEN ============
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChatsListScreen(),
          UpdatesScreen(),
          CallsScreen(),
          ProfileScreen(),
        ],
      ),
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
                icon: Icon(Icons.call_outlined), label: 'Calls'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
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
  String _selectedFilter = 'All'; // 👈 FILTER STATE
  Map<String, int> _unreadCounts = {}; // 👈 Unread cache

  @override
  void initState() {
    super.initState();
    _loadPinnedChats();
  }

  Future<void> _loadPinnedChats() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('pinnedChats') && data['pinnedChats'] != null) {
          setState(() {
            _pinnedChats = List<String>.from(data['pinnedChats']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading pinned chats: $e');
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
                leading: Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: const Color(0xFF667EEA),
                ),
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

  Future<int> _getUnreadCount(String chatId) async {
    try {
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      return unreadMessages.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey[500], size: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedFilter == 'All'),
                    _buildFilterChip('Unread', _selectedFilter == 'Unread'),
                    _buildFilterChip(
                        'Favourites', _selectedFilter == 'Favourites'),
                    _buildFilterChip('Groups', _selectedFilter == 'Groups'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('members', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, chatSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('members', arrayContains: currentUserId)
                .snapshots(),
            builder: (context, groupSnapshot) {
              if (chatSnapshot.connectionState == ConnectionState.waiting ||
                  groupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatSnapshot.hasError) {
                return Center(child: Text('Error: ${chatSnapshot.error}'));
              }
              if (groupSnapshot.hasError) {
                return Center(child: Text('Error: ${groupSnapshot.error}'));
              }

              final hasChats =
                  chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty;
              final hasGroups =
                  groupSnapshot.hasData && groupSnapshot.data!.docs.isNotEmpty;

              if (!hasChats && !hasGroups) {
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
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Abhi koi chat nahi hai',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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

              Map<String, Map<String, dynamic>> chats = {};
              if (chatSnapshot.hasData) {
                for (var doc in chatSnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String chatId = data['chatId'] ?? doc.id;
                  if (chatId.isNotEmpty) {
                    if (!chats.containsKey(chatId) ||
                        (data['timestamp'] != null &&
                            (chats[chatId]!['timestamp'] == null ||
                                data['timestamp']
                                        .compareTo(
                                            chats[chatId]!['timestamp']) >
                                    0))) {
                      chats[chatId] = data;
                    }
                  }
                }
              }

              List<Map<String, dynamic>> chatList = chats.values.toList();
              chatList.sort((a, b) {
                Timestamp? ta = a['timestamp'];
                Timestamp? tb = b['timestamp'];
                if (ta == null || tb == null) return 0;
                return tb.compareTo(ta);
              });

              List<Map<String, dynamic>> groupsList = [];
              if (groupSnapshot.hasData) {
                groupsList = groupSnapshot.data!.docs
                    .map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      data['groupId'] = doc.id;
                      return data;
                    })
                    .toList();
                groupsList.sort((a, b) {
                  Timestamp? ta = a['createdAt'];
                  Timestamp? tb = b['createdAt'];
                  if (ta == null || tb == null) return 0;
                  return tb.compareTo(ta);
                });
              }

              // ============ FILTER LOGIC ============

              // 1. GROUPS → sirf groups
              if (_selectedFilter == 'Groups') {
                if (groupsList.isEmpty) {
                  return _emptyState(
                    Icons.group_outlined,
                    'Koi group nahi hai',
                    'Group banane ke liye top-right icon dabayein',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children:
                      groupsList.map((g) => _buildGroupTile(g)).toList(),
                );
              }

              // 2. ALL → sirf single user chats (groups nahi)
              if (_selectedFilter == 'All') {
                if (chatList.isEmpty) {
                  return _emptyState(
                    Icons.chat_bubble_outline,
                    'Koi chat nahi hai',
                    'Search se user dhundh kar chat karein',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children:
                      chatList.map((c) => _buildChatTile(c)).toList(),
                );
              }

              // 3. UNREAD → sirf unread wali chats
              if (_selectedFilter == 'Unread') {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _filterUnreadChats(chatList),
                  builder: (context, unreadSnap) {
                    if (!unreadSnap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    List<Map<String, dynamic>> unreadList = unreadSnap.data!;
                    if (unreadList.isEmpty) {
                      return _emptyState(
                        Icons.mark_chat_read_outlined,
                        'Koi unread chat nahi',
                        'Sab messages padh liye tumne 👍',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(8),
                      children: unreadList
                          .map((c) => _buildChatTile(c))
                          .toList(),
                    );
                  },
                );
              }

              // 4. FAVOURITES → sirf pinned chats
              if (_selectedFilter == 'Favourites') {
                List<Map<String, dynamic>> favList = chatList
                    .where((c) =>
                        _pinnedChats.contains(c['chatId'] ?? ''))
                    .toList();
                if (favList.isEmpty) {
                  return _emptyState(
                    Icons.star_outline,
                    'Koi favourite chat nahi',
                    'Chat pe long press karke pin karein',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children:
                      favList.map((c) => _buildChatTile(c)).toList(),
                );
              }

              // Fallback
              return const SizedBox.shrink();
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

  // 👇 Unread chats nikalne ke liye helper
  Future<List<Map<String, dynamic>>> _filterUnreadChats(
      List<Map<String, dynamic>> chatList) async {
    List<Map<String, dynamic>> result = [];
    for (var chat in chatList) {
      String chatId = chat['chatId'] ?? '';
      if (chatId.isEmpty) continue;
      int unread = await _getUnreadCount(chatId);
      if (unread > 0) {
        result.add(chat);
      }
    }
    return result;
  }

  // 👇 Empty state widget
  Widget _emptyState(IconData icon, String title, String subtitle) {
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
            child: Icon(icon, size: 60, color: const Color(0xFF667EEA)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    String groupId = group['groupId'] ?? '';
    String groupName = group['name'] ?? 'Group';
    List<String> members = List<String>.from(group['members'] ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                  groupId: groupId,
                  groupName: groupName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: group['groupPhoto'] == null
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF667EEA)],
                          )
                        : null,
                  ),
                  child: group['groupPhoto'] != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(group['groupPhoto']),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            groupName.isNotEmpty
                                ? groupName[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${members.length} members',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Group',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    String chatId = chat['chatId'] ?? '';
    List<String> uids = chatId.split('_');
    String otherUserId = uids.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    String lastMessage = chat['message'] ?? '';
    if (lastMessage.isEmpty && chat['voiceBase64'] != null) {
      lastMessage = '🎤 Voice message';
    } else if (lastMessage.isEmpty && chat['imageBase64'] != null) {
      lastMessage = '📷 Photo';
    }
    Timestamp? timestamp = chat['timestamp'];
    bool isPinned = _pinnedChats.contains(chatId);

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String username = 'User';
        String? avatarUrl;

        if (userSnapshot.hasData &&
            userSnapshot.data != null &&
            userSnapshot.data!.exists) {
          Map<String, dynamic>? userData =
              userSnapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            username = userData['username'] ?? 'User';
            avatarUrl = userData.containsKey('avatarUrl')
                ? userData['avatarUrl']
                : null;
          }
        }

        return FutureBuilder<int>(
          future: _getUnreadCount(chatId),
          builder: (context, unreadSnapshot) {
            int unreadCount = unreadSnapshot.data ?? 0;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                  onLongPress: () =>
                      _showChatOptions(chatId, otherUserId, username),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: avatarUrl,
                          username: username,
                          size: 52,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.push_pin,
                                        size: 14,
                                        color: Color(0xFF667EEA),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unreadCount > 0
                                      ? const Color(0xFF1F2937)
                                      : Colors.grey[600],
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (timestamp != null)
                              Text(
                                DateFormat('hh:mm a')
                                    .format(timestamp.toDate()),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: unreadCount > 0
                                      ? const Color(0xFF25D366)
                                      : Colors.grey[500],
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            const SizedBox(height: 6),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                constraints:
                                    const BoxConstraints(minWidth: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border:
              isSelected ? null : Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
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
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
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

// ============ UPDATES SCREEN ============
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatusScreen();
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
                                        builder: (context) =>
                                            UserProfileScreen(
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

// ============ PROFILE SCREEN (Modern) ============
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

  Future<void> _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    setState(() => _isLoadingAvatar = true);

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 50,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) {
        setState(() => _isLoadingAvatar = false);
        return;
      }

      final compressedBytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(compressedBytes);

      if (base64Image.length > 900000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Photo bahut badi hai, chhoti photo try karein')),
        );
        setState(() => _isLoadingAvatar = false);
        return;
      }

      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'avatarUrl': base64Image,
      });

      setState(() {
        _avatarUrl = base64Image;
        _isLoadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo save ho gayi!')),
      );
    } catch (e) {
      setState(() => _isLoadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEditProfileDialog(
      BuildContext context, String currentUsername) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    String existingBio = '';
    String existingStatus = '';
    DateTime? existingBirthday;

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      existingBio = data['bio'] ?? '';
      existingStatus = data['status'] ?? '';
      if (data['birthday'] != null) {
        Timestamp ts = data['birthday'];
        existingBirthday = ts.toDate();
      }
    }

    if (!context.mounted) return;

    final TextEditingController usernameController =
        TextEditingController(text: currentUsername);
    final TextEditingController bioController =
        TextEditingController(text: existingBio);
    final TextEditingController statusController =
        TextEditingController(text: existingStatus);

    DateTime? selectedBirthday = existingBirthday;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: statusController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Status / Quote',
                        hintText: 'Jaise: "Jeena yahan, marna yahan..."',
                        prefixIcon: const Icon(Icons.format_quote),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Apne baare mein kuch likhein...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.info_outline),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedBirthday ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF4A6CF7),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedBirthday = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedBirthday != null
                                    ? '${selectedBirthday!.day}/${selectedBirthday!.month}/${selectedBirthday!.year}'
                                    : 'Birthday select karein',
                                style: TextStyle(
                                  color: selectedBirthday != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today,
                                color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          String newUsername =
                              usernameController.text.trim().toLowerCase();

                          if (newUsername.length < 3 ||
                              newUsername.length > 20) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Username 3-20 characters ka hona chahiye')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            if (newUsername != currentUsername) {
                              QuerySnapshot existing = await FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .where('username', isEqualTo: newUsername)
                                  .get();

                              if (existing.docs.isNotEmpty) {
                                setDialogState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Ye username pehle se le liya gaya hai')),
                                );
                                return;
                              }
                            }

                            String uid =
                                FirebaseAuth.instance.currentUser!.uid;

                            Map<String, dynamic> updateData = {
                              'username': newUsername,
                              'status': statusController.text.trim(),
                              'bio': bioController.text.trim(),
                            };

                            if (selectedBirthday != null) {
                              updateData['birthday'] =
                                  Timestamp.fromDate(selectedBirthday!);
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update(updateData);

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Profile update ho gayi!')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _checkAppUpdate() async {
    final Uri url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.example.bhaibhai_securechat');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Play Store nahi khul paya')),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    String message = '🔥 *Bhai Bhai Secure Chat* download karo!\n\n'
        '📱 WhatsApp jaisa messaging app —\n'
        '✅ 24-hour auto-delete messages\n'
        '✅ Group chat + Status updates\n'
        '✅ Hisaab Kitaab feature\n\n'
        '🔗 Download: https://play.google.com/store/apps/details?id=com.example.bhaibhai_securechat\n\n'
        '_Bhai Bhai — Secure Community_';

    final Uri url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp nahi khul paya')),
        );
      }
    }
  }

  Future<void> _showIPhoneAppDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_iphone, color: Color(0xFF4A6CF7)),
            SizedBox(width: 10),
            Text('iPhone App'),
          ],
        ),
        content: const Text(
            'Bhai Bhai iPhone app jald aa raha hai!\n\nApp Store pe launch hone pe aapko notification milegi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield,
                          color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Privacy Settings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPrivacyOption(
                    Icons.visibility, 'Last Seen', 'Everyone'),
                _buildPrivacyOption(
                    Icons.person, 'Profile Photo', 'Everyone'),
                _buildPrivacyOption(
                    Icons.check_circle, 'Read Receipts', 'ON'),
                _buildPrivacyOption(
                    Icons.block, 'Blocked Users', 'Manage'),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOption(
      IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications,
                              color: Color(0xFFF59E0B), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Notifications',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildNotifSwitch('Message Notifications',
                        'Naye message par notification', true, (val) {}),
                    _buildNotifSwitch('Friend Requests',
                        'Friend request par notification', true, (val) {}),
                    _buildNotifSwitch('Group Messages',
                        'Group message par notification', true, (val) {}),
                    _buildNotifSwitch(
                        'Sound', 'Notification sound', true, (val) {}),
                    _buildNotifSwitch('Vibration',
                        'Notification vibration', true, (val) {}),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotifSwitch(String title, String subtitle, bool value,
      Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4A6CF7),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          String username = 'Loading...';
          String memberSince = 'Oct 2026';
          String bio = '';
          String status = '';
          String birthday = '';

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            username = data['username'] ?? 'Not set';
            bio = data['bio'] ?? '';
            status = data['status'] ?? '';

            if (data['birthday'] != null) {
              Timestamp ts = data['birthday'];
              birthday = DateFormat('dd MMM yyyy').format(ts.toDate());
            }

            if (data['createdAt'] != null) {
              Timestamp ts = data['createdAt'];
              memberSince = DateFormat('MMM yyyy').format(ts.toDate());
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A6CF7), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -40,
                            left: -40,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  const Text(
                                    'BHAI BHAI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.settings,
                                          color: Colors.white),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Settings jald aa raha hai!')),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 130,
                      child: GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: _isLoadingAvatar
                                  ? const CircleAvatar(
                                      radius: 55,
                                      backgroundColor: Colors.white,
                                      child: CircularProgressIndicator(),
                                    )
                                  : AvatarWidget(
                                      avatarUrl: _avatarUrl,
                                      username: username,
                                      size: 110,
                                    ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4A6CF7),
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
                    ),
                  ],
                ),
                const SizedBox(height: 75),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"$status"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4A6CF7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (birthday.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cake, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        birthday,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showQRDialog(context, username, user.uid);
                          },
                          icon: const Icon(Icons.qr_code_2,
                              color: Color(0xFF4A6CF7), size: 20),
                          label: const Text('My QR',
                              style: TextStyle(
                                  color: Color(0xFF4A6CF7),
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: Color(0xFF4A6CF7), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showEditProfileDialog(context, username);
                          },
                          icon: const Icon(Icons.edit,
                              color: Colors.white, size: 18),
                          label: const Text('Edit Profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('friend_requests')
                        .where('receiverId', isEqualTo: user.uid)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, reqSnap) {
                      int count =
                          reqSnap.hasData ? reqSnap.data!.docs.length : 0;
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
                              const Icon(Icons.person_add, size: 20),
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
                              'Friend Requests${count > 0 ? ' ($count)' : ''}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FutureBuilder<Map<String, int>>(
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

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildStatItem(
                              Icons.people,
                              '$contacts',
                              'Contacts',
                              const Color(0xFF3B82F6),
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
                            _buildDivider(),
                            _buildStatItem(
                              Icons.receipt_long,
                              'Hisaab',
                              'Hisaab',
                              const Color(0xFF10B981),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KhataScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              Icons.lock,
                              '$blocked',
                              'Blocked',
                              const Color(0xFFEF4444),
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
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.settings,
                                    color: Color(0xFF8B5CF6), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Account Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        _buildSettingsItem(
                          Icons.shield,
                          'Privacy',
                          const Color(0xFF10B981),
                          () => _showPrivacySheet(context),
                        ),
                        _buildSettingsItem(
                          Icons.notifications,
                          'Notifications',
                          const Color(0xFFF59E0B),
                          () => _showNotificationsSheet(context),
                        ),
                        _buildSettingsItem(
                          Icons.system_update,
                          'App Update',
                          const Color(0xFF8B5CF6),
                          () => _checkAppUpdate(),
                        ),
                        _buildSettingsItem(
                          Icons.share,
                          'App Share',
                          const Color(0xFF3B82F6),
                          () => _shareApp(),
                        ),
                        _buildSettingsItem(
                          Icons.phone_iphone,
                          'iPhone App',
                          const Color(0xFF6B7280),
                          () => _showIPhoneAppDialog(),
                        ),
                        _buildSettingsItem(
                          Icons.logout,
                          'Logout',
                          const Color(0xFFEF4444),
                          () => FirebaseAuth.instance.signOut(),
                          textColor: const Color(0xFFEF4444),
                          showArrow: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bhai Bhai App v1.0.0 • Secure Community',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.grey[200],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    Color? textColor,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? const Color(0xFF1F2937),
                ),
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20)
            else
              Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _loadStats(String uid) async {
    int contacts = 0;
    int chats = 0;
    int blocked = 0;

    try {
      QuerySnapshot friendsSnap = await FirebaseFirestore.instance
          .collection('friends')
          .where('uid1', isEqualTo: uid)
          .get();
      contacts = friendsSnap.docs.length;

      QuerySnapshot chatsSnap = await FirebaseFirestore.instance
          .collection('chats')
          .where('members', arrayContains: uid)
          .get();
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
              child: Text(
                  'Abhi koi contact nahi hai.\nSearch karke chat shuru karein!'),
            );
          }

          return ListView.builder(
            itemCount: contactIds.length,
            itemBuilder: (context, index) {
              String uid = contactIds.elementAt(index);
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
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
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
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
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String blockedId = data['blockedId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(blockedId)
                    .get(),
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
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
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
