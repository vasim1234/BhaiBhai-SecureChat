import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'avatar_builder.dart';

// ============ STATUS SCREEN (Updates / Stories) ============
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // ============ MY STATUS ============
  void _showMyStatusOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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
                  backgroundColor: Color(0xFF667EEA),
                  child: Icon(Icons.text_fields, color: Colors.white),
                ),
                title: const Text('Text Status'),
                subtitle: const Text('Kuch likhein'),
                onTap: () {
                  Navigator.pop(context);
                  _addTextStatus();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Photo Status'),
                subtitle: const Text('Photo bhejein'),
                onTap: () {
                  Navigator.pop(context);
                  _addPhotoStatus();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTextStatus() async {
    final TextEditingController statusController = TextEditingController();
    final List<Color> bgColors = [
      const Color(0xFF667EEA),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    int selectedColor = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Text Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: bgColors[selectedColor],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          statusController.text.isEmpty
                              ? 'Type karein...'
                              : statusController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: statusController,
                    maxLength: 100,
                    maxLines: 3,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Apna status likhein...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(bgColors.length, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedColor = i),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: bgColors[i],
                            shape: BoxShape.circle,
                            border: selectedColor == i
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (statusController.text.trim().isEmpty) return;

                    await _saveStatus(
                      type: 'text',
                      content: statusController.text.trim(),
                      bgColor: bgColors[selectedColor].value.toRadixString(16),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Status add ho gaya!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6CF7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addPhotoStatus() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/status_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 50,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) return;

      final bytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      if (base64Image.length > 900000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo bahut badi hai, chhoti try karein')),
          );
        }
        return;
      }

      await _saveStatus(type: 'image', content: base64Image);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo status add ho gaya!')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _saveStatus({
    required String type,
    required String content,
    String? bgColor,
  }) async {
    // User ka data lo
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!userDoc.exists) return;

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('status').add({
      'userId': currentUserId,
      'username': userData['username'] ?? 'User',
      'avatarUrl': userData['avatarUrl'],
      'type': type,
      'content': content,
      'bgColor': bgColor,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryTime),
      'viewers': [],
    });
  }

  // ============ STATUS VIEWER ============
  void _openStatusViewer(
      List<Map<String, dynamic>> userStatuses, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewer(
          statuses: userStatuses,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Updates'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('status')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Sirf active status (24h ke andar)
          List<Map<String, dynamic>> activeStatuses = snapshot.data!.docs
              .map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                data['docId'] = doc.id;
                return data;
              })
              .where((status) {
                Timestamp? expiresAt = status['expiresAt'];
                return expiresAt != null &&
                    expiresAt.toDate().isAfter(DateTime.now());
              })
              .toList();

          if (activeStatuses.isEmpty) {
            return _buildEmptyState();
          }

          // User-wise group karo
          Map<String, List<Map<String, dynamic>>> groupedStatuses = {};
          for (var status in activeStatuses) {
            String userId = status['userId'];
            groupedStatuses.putIfAbsent(userId, () => []).add(status);
          }

          // Current user ka status alag
          List<Map<String, dynamic>> myStatuses =
              groupedStatuses[currentUserId] ?? [];
          groupedStatuses.remove(currentUserId);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // My Status
              _buildMyStatusTile(myStatuses),
              const SizedBox(height: 15),

              // Recent Updates
              if (groupedStatuses.isNotEmpty) ...[
                const Text(
                  'RECENT UPDATES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ...groupedStatuses.entries.map((entry) {
                  return _buildUserStatusTile(entry.value);
                }).toList(),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667EEA),
        onPressed: _showMyStatusOptions,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.update,
              size: 60,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Abhi koi status nahi hai',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Neeche + dabao aur apna status add karo!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusTile(List<Map<String, dynamic>> myStatuses) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get(),
      builder: (context, snapshot) {
        String username = 'My Status';
        String? avatarUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? 'My Status';
          avatarUrl = data['avatarUrl'];
        }

        bool hasStatus = myStatuses.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(12),
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
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarWidget(
                    avatarUrl: avatarUrl,
                    username: username,
                    size: 55,
                  ),
                  // + icon for adding status
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showMyStatusOptions,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A6CF7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasStatus
                          ? '${myStatuses.length} status • Tap to view'
                          : 'Tap + to add status',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasStatus)
                GestureDetector(
                  onTap: () => _openStatusViewer(myStatuses, 0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Color(0xFF667EEA)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserStatusTile(List<Map<String, dynamic>> userStatuses) {
    var firstStatus = userStatuses.first;
    String username = firstStatus['username'] ?? 'User';
    String? avatarUrl = firstStatus['avatarUrl'];

    return GestureDetector(
      onTap: () => _openStatusViewer(userStatuses, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF10B981)],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: AvatarWidget(
                  avatarUrl: avatarUrl,
                  username: username,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userStatuses.length} update${userStatuses.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ============ STATUS VIEWER ============
class StatusViewer extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final int initialIndex;

  const StatusViewer({
    super.key,
    required this.statuses,
    required this.initialIndex,
  });

  @override
  State<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<StatusViewer> {
  late int _currentIndex;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _markAsViewed();
  }

  Future<void> _markAsViewed() async {
    String docId = widget.statuses[_currentIndex]['docId'];
    try {
      await FirebaseFirestore.instance.collection('status').doc(docId).update({
        'viewers': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e) {
      debugPrint('Error marking viewed: $e');
    }
  }

  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _markAsViewed();
    }
  }

  @override
  Widget build(BuildContext context) {
    var status = widget.statuses[_currentIndex];
    String type = status['type'] ?? 'text';
    String content = status['content'] ?? '';
    String? bgColor = status['bgColor'];
    Timestamp? timestamp = status['timestamp'];

    Color bg = const Color(0xFF667EEA);
    if (bgColor != null) {
      try {
        bg = Color(int.parse('FF$bgColor', radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          if (type == 'image')
            Center(
              child: Image.memory(
                base64Decode(content),
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              color: bg,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Tap areas for next/prev
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _prevStatus,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStatus,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                // Progress bars
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(widget.statuses.length, (i) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _currentIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // User info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      AvatarWidget(
                        avatarUrl: status['avatarUrl'],
                        username: status['username'] ?? 'User',
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status['username'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (timestamp != null)
                              Text(
                                _getTimeAgo(timestamp.toDate()),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
