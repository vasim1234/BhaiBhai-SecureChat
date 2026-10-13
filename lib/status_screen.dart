import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'avatar_builder.dart';
import 'chat_screen.dart';

// ============ STATUS SCREEN (Updates / Stories) ============
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _showMyStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addTextStatus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667EEA)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.text_fields,
                                    color: Colors.white, size: 40),
                                SizedBox(height: 10),
                                Text(
                                  'Text',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addPhotoStatus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF25D366),
                                  Color(0xFF128C7E)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF25D366)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.photo_camera,
                                    color: Colors.white, size: 40),
                                SizedBox(height: 10),
                                Text(
                                  'Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addTextStatus() async {
    final TextEditingController controller = TextEditingController();
    String selectedColor = '667EEA';

    final List<Map<String, dynamic>> colors = [
      {'value': '667EEA', 'color': const Color(0xFF667EEA)},
      {'value': '8B5CF6', 'color': const Color(0xFF8B5CF6)},
      {'value': 'EC4899', 'color': const Color(0xFFEC4899)},
      {'value': 'EF4444', 'color': const Color(0xFFEF4444)},
      {'value': '10B981', 'color': const Color(0xFF10B981)},
      {'value': 'F59E0B', 'color': const Color(0xFFF59E0B)},
      {'value': '06B6D4', 'color': const Color(0xFF06B6D4)},
      {'value': '1F2937', 'color': const Color(0xFF1F2937)},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.text_fields,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Text Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(int.parse(
                                  'FF$selectedColor', radix: 16)),
                              Color(int.parse(
                                      'FF$selectedColor', radix: 16))
                                  .withOpacity(0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(int.parse(
                                      'FF$selectedColor', radix: 16))
                                  .withOpacity(0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              controller.text.isEmpty
                                  ? 'Type karein...'
                                  : controller.text,
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                    controller.text.isEmpty ? 0.6 : 1.0),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: controller,
                          maxLines: 3,
                          maxLength: 100,
                          onChanged: (val) => setDialogState(() {}),
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Apna status likhein...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(16),
                            counterStyle:
                                TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Background Color',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: colors.length,
                          itemBuilder: (context, index) {
                            final c = colors[index];
                            bool isSelected = selectedColor == c['value'];
                            return GestureDetector(
                              onTap: () {
                                setDialogState(
                                    () => selectedColor = c['value']);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                width: isSelected ? 44 : 40,
                                height: isSelected ? 44 : 40,
                                decoration: BoxDecoration(
                                  color: c['color'],
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.black87, width: 3)
                                      : Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (c['color'] as Color)
                                                .withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (controller.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Status khali nahi ho sakta')),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                await _saveStatus(
                                  type: 'text',
                                  content: controller.text.trim(),
                                  bgColor: selectedColor,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Status add ho gaya! ✅')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Post',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
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
    );
  }

  Future<void> _addPhotoStatus() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image == null) {
        debugPrint('User cancelled image picker');
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/status_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 40,
        minWidth: 720,
        minHeight: 720,
      );

      if (compressedFile == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final bytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      if (base64Image.length > 900000) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo bahut badi hai, chhoti try karein')),
          );
        }
        return;
      }

      await _saveStatus(type: 'image', content: base64Image);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo status add ho gaya! ✅')),
        );
      }
    } catch (e) {
      debugPrint('Photo status error: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveStatus({
    required String type,
    required String content,
    String? bgColor,
  }) async {
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
        title: const Text('Status'),
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

          Map<String, List<Map<String, dynamic>>> groupedStatuses = {};
          for (var status in activeStatuses) {
            String userId = status['userId'];
            groupedStatuses.putIfAbsent(userId, () => []).add(status);
          }

          List<Map<String, dynamic>> myStatuses =
              groupedStatuses[currentUserId] ?? [];
          groupedStatuses.remove(currentUserId);

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildMyStatusTile(myStatuses),
              const SizedBox(height: 12),
              if (groupedStatuses.isNotEmpty) ...[
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

        return InkWell(
          onTap: () {
            if (hasStatus) {
              _openStatusViewer(myStatuses, 0);
            } else {
              _showMyStatusOptions();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Stack(
                  children: [
                    hasStatus
                        ? Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF25D366),
                                width: 2.5,
                              ),
                            ),
                            child: AvatarWidget(
                              avatarUrl: avatarUrl,
                              username: username,
                              size: 52,
                            ),
                          )
                        : AvatarWidget(
                            avatarUrl: avatarUrl,
                            username: username,
                            size: 58,
                          ),
                    if (!hasStatus)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
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
                        hasStatus
                            ? '${myStatuses.length} update${myStatuses.length > 1 ? 's' : ''}'
                            : 'Tap to add status update',
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

  Widget _buildUserStatusTile(List<Map<String, dynamic>> userStatuses) {
    var firstStatus = userStatuses.first;
    String username = firstStatus['username'] ?? 'User';
    String? avatarUrl = firstStatus['avatarUrl'];

    bool allSeen = userStatuses.every((s) {
      List viewers = s['viewers'] ?? [];
      return viewers.contains(currentUserId);
    });

    return InkWell(
      onTap: () => _openStatusViewer(userStatuses, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
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
          ],
        ),
      ),
    );
  }
}

// ============ STATUS VIEWER (Full Screen) ============
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
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _markAsViewed();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
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
      setState(() => _currentIndex++);
      _markAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStatus() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _markAsViewed();
    }
  }

  // ============ VIEWERS LIST ============
  void _showViewersList(List<dynamic> viewers) {
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
              const SizedBox(height: 15),
              Text(
                '${viewers.length} Viewers',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              if (viewers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Abhi tak kisi ne nahi dekha'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewers.length,
                    itemBuilder: (context, index) {
                      String viewerId = viewers[index].toString();
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(viewerId)
                            .get(),
                        builder: (context, snap) {
                          String username = 'User';
                          String? avatarUrl;
                          if (snap.hasData && snap.data!.exists) {
                            username =
                                snap.data!['username'] ?? 'User';
                            avatarUrl = snap.data!['avatarUrl'];
                          }
                          return ListTile(
                            leading: AvatarWidget(
                              avatarUrl: avatarUrl,
                              username: username,
                              size: 45,
                            ),
                            title: Text(username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendReplyToStatus(Map<String, dynamic> status) async {
    String message = _replyController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      String receiverId = status['userId'];
      String receiverName = status['username'] ?? 'User';
      String statusType = status['type'] ?? 'text';
      String statusContent = status['content'] ?? '';

      List<String> uids = [currentUserId, receiverId]..sort();
      String chatId = '${uids[0]}_${uids[1]}';

      String replyMessage;
      if (statusType == 'text' && statusContent.isNotEmpty) {
        replyMessage = '📸 Status reply: "$statusContent"\n\n$message';
      } else {
        replyMessage = '📸 Status reply: [Photo]\n\n$message';
      }

      await FirebaseFirestore.instance.collection('chats').add({
        'chatId': chatId,
        'members': [currentUserId, receiverId],
        'senderId': currentUserId,
        'receiverId': receiverId,
        'message': replyMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24))),
        'isRead': false,
        'isEdited': false,
        'isDeleted': false,
      });

      _replyController.clear();

      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply bhej diya $receiverName ko! ✅'),
            backgroundColor: const Color(0xFF25D366),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteStatus(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('status')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status delete ho gaya! 🗑️')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusMenu(Map<String, dynamic> status) {
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
              const SizedBox(height: 15),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Delete Status',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle:
                    const Text('Ye status hamesha ke liye delete ho jayega'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Status?'),
                      content: const Text(
                          'Kya tum sach mein ye status delete karna chahte ho?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteStatus(status['docId']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var status = widget.statuses[_currentIndex];
    String type = status['type'] ?? 'text';
    String content = status['content'] ?? '';
    String? bgColor = status['bgColor'];
    Timestamp? timestamp = status['timestamp'];
    bool isMyStatus = status['userId'] == currentUserId;

    Color bg = const Color(0xFF667EEA);
    if (bgColor != null && bgColor.isNotEmpty) {
      try {
        bg = Color(int.parse('FF$bgColor', radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (type == 'image')
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.memory(
                base64Decode(content),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Image load nahi ho payi',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bg, bg.withOpacity(0.65)],
                ),
              ),
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

          SafeArea(
            child: Column(
              children: [
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
                      if (isMyStatus)
                        IconButton(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white),
                          onPressed: () => _showStatusMenu(status),
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

          if (isMyStatus)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showViewersList(status['viewers'] ?? []),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_up,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (!isMyStatus)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Reply to status...',
                          hintStyle: TextStyle(
                              color: Colors.white70, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 22),
                            onPressed: () => _sendReplyToStatus(status),
                          ),
                  ],
                ),
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
