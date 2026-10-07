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
import 'friend_request.dart';
import 'user_profile.dart';
import 'dart:typed_data';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'avatar_builder.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

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

// ============ LOGIN SCREEN (Modern Design) ============
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
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
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
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
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
                                setState(() =>
                                    _obscurePassword = !_obscurePassword);
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
                                  content: Text(
                                      'Google Sign-In jald aa raha hai!'),
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
          CommunitiesScreen(),
          CallsScreen(),
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
                    _buildFilterChip('All', true),
                    _buildFilterChip('Unread', false),
                    _buildFilterChip('Favourites', false),
                    _buildFilterChip('Groups', false),
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
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String chatId = data['chatId'] ?? doc.id;
            if (chatId.isNotEmpty) {
              if (!chats.containsKey(chatId) ||
                  (data['timestamp'] != null &&
                      (chats[chatId]!['timestamp'] == null ||
                          data['timestamp']
                                  .compareTo(chats[chatId]!['timestamp']) >
                              0))) {
                chats[chatId] = data;
              }
            }
          }

          List<Map<String, dynamic>> chatList = chats.values.toList();
          chatList.sort((a, b) {
            String aId = a['chatId'] ?? '';
            String bId = b['chatId'] ?? '';
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
              } else if (lastMessage.isEmpty &&
                  chat['imageBase64'] != null) {
                lastMessage = '📷 Photo';
              }
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
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
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
                            onLongPress: () => _showChatOptions(
                                chatId, otherUserId, username),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPinned)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                    left: 4),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
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
                                          constraints: const BoxConstraints(
                                              minWidth: 20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366),
                                            borderRadius:
                                                BorderRadius.circular(10),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isSelected
            ? null
            : Border.all(color: Colors.grey[300]!, width: 1),
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
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
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
        quality: 50,
        minWidth: 800,
        minHeight: 800,
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
                  return const Center(
                      child: Text('Group mein message bhejein!'));
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
                  icon:
                      const Icon(Icons.attach_file, color: Color(0xFF667EEA)),
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
              content: Text('Photo bahut badi hai, chhoti photo try karein')),
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
                              Icons.chat_bubble,
                              '$chats',
                              'Chats',
                              const Color(0xFF8B5CF6),
                              onTap: () {},
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
                          () {
                            _showSimpleSheet(context, 'Privacy',
                                'Privacy settings jald aa rahi hain!');
                          },
                        ),
                        _buildSettingsItem(
                          Icons.notifications,
                          'Notifications',
                          const Color(0xFFF59E0B),
                          () {
                            _showSimpleSheet(context, 'Notifications',
                                'Notification settings jald aa rahi hain!');
                          },
                        ),
                        _buildSettingsItem(
                          Icons.storage,
                          'Storage',
                          const Color(0xFF8B5CF6),
                          () {
                            _showSimpleSheet(context, 'Storage',
                                'Storage info jald aa rahi hai!');
                          },
                        ),
                        _buildSettingsItem(
                          Icons.help_outline,
                          'Help',
                          const Color(0xFF3B82F6),
                          () {
                            _showSimpleSheet(context, 'Help & Support',
                                'Email: support@bhaibhai.com');
                          },
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

  void _showSimpleSheet(BuildContext context, String title, String message) {
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
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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

// ============ CHAT SCREEN (With Voice Message) ============
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

  // ============ VOICE MESSAGE VARIABLES ============
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _isPlayingMap = {};
  final Map<String, Duration> _playPositionMap = {};
  final Map<String, Duration> _playDurationMap = {};

  static const String ONESIGNAL_APP_ID =
      '05bee600-4a45-44e5-b35e-5328544c25c1';
  static const String ONESIGNAL_REST_API_KEY = String.fromEnvironment(
    'ONESIGNAL_REST_API_KEY',
    defaultValue: '',
  );

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
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    super.dispose();
  }

  // ============ VOICE RECORDING ============
  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Microphone permission chahiye voice ke liye')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });
          if (timer.tick >= 300) _stopRecording(send: true);
        }
      });
    } catch (e) {
      debugPrint('Recording error: $e');
    }
  }

  Future<void> _stopRecording({bool send = false}) async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();

      setState(() => _isRecording = false);

      if (path == null || !send) {
        if (path != null) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
        setState(() => _recordDuration = Duration.zero);
        return;
      }

      final file = File(path);
      final fileSize = await file.length();

      if (fileSize > 900000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice bahut lambi hai')),
          );
        }
        await file.delete();
        setState(() => _recordDuration = Duration.zero);
        return;
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      await _sendMessage(voiceBase64: base64Audio);
      await file.delete();

      setState(() => _recordDuration = Duration.zero);
    } catch (e) {
      debugPrint('Stop recording error: $e');
    }
  }

  Future<void> _cancelRecording() async {
    await _stopRecording(send: false);
  }

  // ============ VOICE PLAYBACK ============
  Future<void> _playVoice(String messageId, String base64Audio) async {
    try {
      if (_isPlayingMap[messageId] == true) {
        await _audioPlayers[messageId]?.stop();
        setState(() {
          _isPlayingMap[messageId] = false;
          _playPositionMap[messageId] = Duration.zero;
        });
        return;
      }

      for (var player in _audioPlayers.values) {
        await player.stop();
      }

      final player = AudioPlayer();
      _audioPlayers[messageId] = player;

      final bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/play_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(path);
      await file.writeAsBytes(bytes);

      player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _playDurationMap[messageId] = d);
      });
      player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _playPositionMap[messageId] = p);
      });
      player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlayingMap[messageId] = false;
            _playPositionMap[messageId] = Duration.zero;
          });
        }
        file.delete();
      });

      await player.play(DeviceFileSource(path));
      setState(() => _isPlayingMap[messageId] = true);
    } catch (e) {
      debugPrint('Playback error: $e');
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  // ============ NOTIFICATION ============
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
      debugPrint('OneSignal Error: $e');
    }
  }

  // ============ TYPING + ONLINE ============
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

  // ============ HELPERS ============
  Future<void> _markMessagesAsRead() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
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
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
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

  // ============ SEND MESSAGE ============
  Future<void> _sendMessage({
    String? imageBase64,
    String? voiceBase64,
    Map<String, dynamic>? replyTo,
  }) async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aapne is user ko block kiya hai')),
      );
      return;
    }
    if (!_areFriends) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pehle friend request accept karwa lein!')),
      );
      return;
    }
    if (_msgController.text.trim().isEmpty &&
        imageBase64 == null &&
        voiceBase64 == null) return;

    String messageText = _msgController.text.trim();
    _msgController.clear();
    _setTypingStatus(false);

    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));
    List<String> members = [currentUserId, widget.receiverUid];
    members.sort();

    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'chatId': chatId,
        'members': members,
        'senderId': currentUserId,
        'receiverId': widget.receiverUid,
        'message': messageText,
        'imageBase64': imageBase64,
        'voiceBase64': voiceBase64,
        'replyTo': replyTo,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'isEdited': false,
        'isDeleted': false,
        'isRead': false,
      });

      await _sendNotification(
        messageText.isNotEmpty
            ? messageText
            : (voiceBase64 != null ? '🎤 Voice message' : 'Photo bheji'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message send nahi hua: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(String docId) async {
    await FirebaseFirestore.instance.collection('chats').doc(docId).update({
      'isDeleted': true,
      'message': 'Ye message delete kar diya gaya hai',
      'imageBase64': null,
      'voiceBase64': null,
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
              if (message.isNotEmpty)
                ListTile(
                  leading:
                      const Icon(Icons.reply, color: Color(0xFF667EEA)),
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
              if (isMe && message.isNotEmpty)
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
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
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
        quality: 50,
        minWidth: 800,
        minHeight: 800,
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
              content:
                  Text('Photo bahut badi hai, chhoti photo try karein')),
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

  // ============ VOICE PLAYER WIDGET ============
  Widget _buildVoicePlayer(String messageId, String base64Audio, bool isMe) {
    final isPlaying = _isPlayingMap[messageId] ?? false;
    final position = _playPositionMap[messageId] ?? Duration.zero;
    final duration = _playDurationMap[messageId] ?? Duration.zero;

    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _playVoice(messageId, base64Audio),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isMe ? Colors.white : const Color(0xFF667EEA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: isMe ? const Color(0xFF667EEA) : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(20, (i) {
                  final height = (i % 4) * 3.0 + 4.0;
                  return Container(
                    width: 2.5,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white70
                          : const Color(0xFF667EEA).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                isPlaying
                    ? '${_formatDuration(position)} / ${_formatDuration(duration)}'
                    : _formatDuration(duration),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16)),
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
                const SnackBar(
                    content: Text('Calling feature jald aa raha hai!')),
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
                      child:
                          Text('Abhi koi message nahi hai. Hi bhejein!'));
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
                    String? voiceBase64 = data['voiceBase64'];
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
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
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
                              if (voiceBase64 != null && !isDeleted)
                                _buildVoicePlayer(doc.id, voiceBase64, isMe),
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
                                      padding:
                                          const EdgeInsets.only(left: 5),
                                      child: Icon(
                                        isRead
                                            ? Icons.done_all
                                            : Icons.done,
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
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.red.withOpacity(0.1),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(_recordDuration),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Recording...',
                            style: TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.red),
                          onPressed: _cancelRecording,
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.red),
                          onPressed: () => _stopRecording(send: true),
                        ),
                      ],
                    ),
                  )
                else
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
                            setState(() {});
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
                      GestureDetector(
                        onLongPress: (_isBlocked || !_areFriends)
                            ? null
                            : _startRecording,
                        onLongPressEnd: (_isBlocked || !_areFriends)
                            ? null
                            : (_) => _stopRecording(send: true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                            color: (_isBlocked || !_areFriends)
                                ? Colors.grey
                                : null,
                          ),
                          child: _msgController.text.trim().isEmpty
                              ? const Icon(Icons.mic,
                                  color: Colors.white)
                              : GestureDetector(
                                  onTap: () async {
                                    await _sendMessage(
                                        replyTo: _replyToData);
                                    setState(() => _replyToData = null);
                                  },
                                  child: const Icon(Icons.send,
                                      color: Colors.white),
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
    );
  }
}
