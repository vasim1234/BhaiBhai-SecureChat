import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_request.dart';
import 'avatar_builder.dart';

// ============ PROFILE SCREEN (Modern Design) ============
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
          if (snapshot.hasData && snapshot.data!.exists) {
            username = snapshot.data!['username'] ?? 'Not set';
            if (snapshot.data!['createdAt'] != null) {
              Timestamp ts = snapshot.data!['createdAt'];
              memberSince = DateFormat('MMM yyyy').format(ts.toDate());
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ============ HEADER WITH GRADIENT BANNER ============
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Gradient Banner
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A6CF7),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
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
                          // Top Bar (Back + Title + Settings)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back button
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
                                  // Settings button
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
                    // Avatar (overlapping)
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
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

                // ============ NAME + EMAIL ============
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

                // ============ ONLINE BADGE ============
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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

                // ============ QR + EDIT BUTTONS ============
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
                            _pickProfilePhoto();
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

                // ============ FRIEND REQUESTS ============
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
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

                // ============ STATS CARD ============
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

                // ============ ACCOUNT SETTINGS ============
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
                        // Header
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

                        // Privacy
                        _buildSettingsItem(
                          Icons.shield,
                          'Privacy',
                          const Color(0xFF10B981),
                          () {},
                        ),
                        // Notifications
                        _buildSettingsItem(
                          Icons.notifications,
                          'Notifications',
                          const Color(0xFFF59E0B),
                          () {},
                        ),
                        // Storage
                        _buildSettingsItem(
                          Icons.storage,
                          'Storage',
                          const Color(0xFF8B5CF6),
                          () {},
                        ),
                        // Help
                        _buildSettingsItem(
                          Icons.help_outline,
                          'Help',
                          const Color(0xFF3B82F6),
                          () {},
                        ),
                        // Logout
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

  // ============ HELPER WIDGETS ============

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
