import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'avatar_builder.dart';

// ============ STATUS SCREEN (WhatsApp Style) ============
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Status',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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

          // Current user ke status filter karo
          List<Map<String, dynamic>> myStatuses = [];
          Map<String, List<Map<String, dynamic>>> otherStatuses = {};

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['statusId'] = doc.id;

            // Expired check
            if (data['expiresAt'] != null) {
              Timestamp exp = data['expiresAt'];
              if (exp.toDate().isBefore(DateTime.now())) continue;
            }

            if (data['userId'] == currentUserId) {
              myStatuses.add(data);
            } else {
              String uid = data['userId'];
              if (!otherStatuses.containsKey(uid)) {
                otherStatuses[uid] = [];
              }
              otherStatuses[uid]!.add(data);
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ===== MY STATUS TILE =====
              _buildMyStatusTile(myStatuses),

              const SizedBox(height: 12),

              // ===== RECENT UPDATES HEADING =====
              if (otherStatuses.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'Recent Updates',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              // ===== OTHER USERS STATUS =====
              ...otherStatuses.entries.map((entry) {
                return _buildUserStatusTile(entry.key, entry.value);
              }).toList(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667EEA),
        onPressed: () => _showStatusOptions(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ===== EMPTY STATE =====
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
            'Neeche + dabaao aur apna status add karo!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ===== MY STATUS TILE =====
  Widget _buildMyStatusTile(List<Map<String, dynamic>> myStatuses) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, userSnap) {
        String username = 'My Status';
        String? avatarUrl;
        if (userSnap.hasData && userSnap.data!.exists) {
          username = userSnap.data!['username'] ?? 'My Status';
          avatarUrl = userSnap.data!['avatarUrl'];
        }

        return InkWell(
          onTap: () {
            if (myStatuses.isEmpty) {
              _showStatusOptions(context);
            } else {
              // Apna status dekho
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatusViewerScreen(
                    userId: currentUserId,
                    username: username,
                    statuses: myStatuses,
                    isMyStatus: true,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Stack(
                  children: [
                    AvatarWidget(
                      avatarUrl: avatarUrl,
                      username: username,
                      size: 56,
                    ),
                    // Plus icon
                    if (myStatuses.isEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        myStatuses.isEmpty
                            ? 'Tap to add status update'
                            : '${myStatuses.length} update${myStatuses.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== OTHER USER STATUS TILE =====
  Widget _buildUserStatusTile(
      String userId, List<Map<String, dynamic>> statuses) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnap) {
        String username = 'User';
        String? avatarUrl;
        if (userSnap.hasData && userSnap.data!.exists) {
          username = userSnap.data!['username'] ?? 'User';
          avatarUrl = userSnap.data!['avatarUrl'];
        }

        // Sabse recent status lo time ke liye
        statuses.sort((a, b) {
          Timestamp? ta = a['timestamp'];
          Timestamp? tb = b['timestamp'];
          if (ta == null || tb == null) return 0;
          return tb.compareTo(ta);
        });

        Timestamp? latestTime = statuses.first['timestamp'];
        String timeAgo = latestTime != null
            ? _getTimeAgo(latestTime.toDate())
            : '';

        // Check karo ki user ne saare status dekhe ya nahi
        bool allSeen = statuses.every((s) {
          List viewers = s['viewers'] ?? [];
          return viewers.contains(currentUserId);
        });

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatusViewerScreen(
                  userId: userId,
                  username: username,
                  statuses: statuses,
                  isMyStatus: false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Green ring (unseen) ya grey ring (seen)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: allSeen
                          ? Colors.grey[400]!
                          : const Color(0xFF25D366),
                      width: 2.5,
                    ),
                  ),
                  child: AvatarWidget(
                    avatarUrl: avatarUrl,
                    username: username,
                    size: 52,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== TIME AGO =====
  String _getTimeAgo(DateTime date) {
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ===== STATUS OPTIONS (Text / Photo) =====
  void _showStatusOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.text_fields,
                        color: Color(0xFF667EEA)),
                  ),
                  title: const Text('Text Status',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Likh kar status lagao'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTextStatusDialog(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera,
                        color: Color(0xFF25D366)),
                  ),
                  title: const Text('Photo Status',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Photo lagao status mein'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Photo status ka code chat_screen mein hai — wahan se use karo')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== TEXT STATUS DIALOG (Modern) =====
  void _showTextStatusDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    String selectedColor = '667EEA';

    final List<Map<String, String>> colors = [
      {'name': 'Blue', 'value': '667EEA'},
      {'name': 'Purple', 'value': '8B5CF6'},
      {'name': 'Pink', 'value': 'EC4899'},
      {'name': 'Red', 'value': 'EF4444'},
      {'name': 'Green', 'value': '10B981'},
      {'name': 'Orange', 'value': 'F59E0B'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preview box
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(int.parse('FF$selectedColor', radix: 16)),
                            Color(int.parse('FF$selectedColor', radix: 16))
                                .withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            controller.text.isEmpty
                                ? 'Type karein...'
                                : controller.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      maxLength: 100,
                      onChanged: (val) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Apna status likhein...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF667EEA), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Color picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: colors.map((c) {
                        bool isSelected = selectedColor == c['value'];
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = c['value']!);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(
                                  int.parse('FF${c['value']}', radix: 16)),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.black87, width: 2.5)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Status khali nahi ho sakta')),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            await _saveTextStatus(
                                controller.text.trim(), selectedColor);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Post',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveTextStatus(String text, String bgColor) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      String username = userDoc['username'] ?? 'User';
      String? avatarUrl = userDoc['avatarUrl'];

      await FirebaseFirestore.instance.collection('status').add({
        'userId': currentUserId,
        'username': username,
        'avatarUrl': avatarUrl,
        'type': 'text',
        'content': text,
        'bgColor': bgColor,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'viewers': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status lag gaya!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ============ STATUS VIEWER SCREEN (Full Screen) ============
class StatusViewerScreen extends StatefulWidget {
  final String userId;
  final String username;
  final List<Map<String, dynamic>> statuses;
  final bool isMyStatus;

  const StatusViewerScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.statuses,
    required this.isMyStatus,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStatus();
        }
      });
    _startCurrent();
  }

  void _startCurrent() {
    _progressController.reset();
    _progressController.forward();
    _markAsViewed();
  }

  void _nextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() => _currentIndex++);
      _startCurrent();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startCurrent();
    }
  }

  Future<void> _markAsViewed() async {
    if (widget.isMyStatus) return;
    String statusId = widget.statuses[_currentIndex]['statusId'];
    try {
      await FirebaseFirestore.instance
          .collection('status')
          .doc(statusId)
          .update({
        'viewers': FieldValue.arrayUnion([currentUserId]),
      });
    } catch (e) {
      debugPrint('Error marking viewed: $e');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statuses[_currentIndex];
    String type = status['type'] ?? 'text';
    String bgColor = status['bgColor'] ?? '667EEA';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _prevStatus();
          } else {
            _nextStatus();
          }
        },
        child: Stack(
          children: [
            // ===== STATUS CONTENT =====
            Center(
              child: type == 'text'
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(int.parse('FF$bgColor', radix: 16)),
                            Color(int.parse('FF$bgColor', radix: 16))
                                .withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(
                            status['content'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: status['content'] != null
                            ? Image.memory(
                                base64Decode(status['content']),
                                fit: BoxFit.contain,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
            ),

            // ===== PROGRESS BARS =====
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(widget.statuses.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double value;
                          if (index < _currentIndex) {
                            value = 1.0;
                          } else if (index == _currentIndex) {
                            value = _progressController.value;
                          } else {
                            value = 0.0;
                          }
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 3,
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ===== HEADER =====
            Positioned(
              top: MediaQuery.of(context).padding.top + 25,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  AvatarWidget(
                    avatarUrl: status['avatarUrl'],
                    username: widget.username,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (status['timestamp'] != null)
                          Text(
                            _getTimeAgo(
                                (status['timestamp'] as Timestamp).toDate()),
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

            // ===== VIEWERS COUNT (agar mera status hai) =====
            if (widget.isMyStatus)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${(status['viewers'] ?? []).length} viewers',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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
