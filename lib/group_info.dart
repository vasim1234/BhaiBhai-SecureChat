import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'avatar_builder.dart';

// ============ GROUP INFO SCREEN (Admin Controls) ============
class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _groupData = data;
          _isAdmin = data['createdBy'] == currentUserId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading group: $e');
      setState(() => _isLoading = false);
    }
  }

  // ============ CHANGE GROUP PHOTO (Admin only) ============
  Future<void> _changeGroupPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/group_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 50,
        minWidth: 800,
        minHeight: 800,
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
            const SnackBar(content: Text('Photo bahut badi hai')),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'groupPhoto': base64Image});

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _groupData?['groupPhoto'] = base64Image;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group photo update ho gayi! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ============ REMOVE MEMBER (Admin only) ============
  Future<void> _removeMember(String memberId, String username) async {
    bool confirm = await _showConfirmDialog(
      'Remove Member',
      '$username ko group se remove karna chahte ho?',
    );

    if (!confirm) return;

    try {
      List<String> members = List<String>.from(_groupData?['members'] ?? []);
      members.remove(memberId);

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'members': members});

      setState(() {
        _groupData?['members'] = members;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$username remove ho gaya')),
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

  // ============ ADD MEMBERS SHEET ============
  void _showAddMembers() {
    List<String> currentMembers =
        List<String>.from(_groupData?['members'] ?? []);
    List<String> selectedUsers = [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Column(
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
                    const Text(
                      'Add Members',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final availableUsers = snapshot.data!.docs
                              .where((doc) =>
                                  !currentMembers.contains(doc.id) &&
                                  doc.id != currentUserId)
                              .toList();

                          if (availableUsers.isEmpty) {
                            return const Center(
                              child: Text('Koi naya user available nahi'),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: availableUsers.length,
                            itemBuilder: (context, index) {
                              final user = availableUsers[index];
                              final data =
                                  user.data() as Map<String, dynamic>;
                              String username = data['username'] ?? 'User';
                              bool isSelected =
                                  selectedUsers.contains(user.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (val) {
                                  setSheetState(() {
                                    if (val == true) {
                                      selectedUsers.add(user.id);
                                    } else {
                                      selectedUsers.remove(user.id);
                                    }
                                  });
                                },
                                secondary: AvatarWidget(
                                  avatarUrl: data['avatarUrl'],
                                  username: username,
                                  size: 45,
                                ),
                                title: Text(username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(data['email'] ?? ''),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (selectedUsers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              List<String> newMembers = [
                                ...currentMembers,
                                ...selectedUsers,
                              ];

                              await FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(widget.groupId)
                                  .update({'members': newMembers});

                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {
                                  _groupData?['members'] = newMembers;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${selectedUsers.length} members add ho gaye!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.person_add),
                            label:
                                Text('Add ${selectedUsers.length} Member(s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A6CF7),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============ CHANGE GROUP NAME (Admin only) ============
  Future<void> _changeGroupName() async {
    final TextEditingController nameController = TextEditingController(
      text: _groupData?['name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Group Name'),
          content: TextField(
            controller: nameController,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: 'Group Name',
              prefixIcon: const Icon(Icons.group),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .update({'name': newName});

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _groupData?['name'] = newName;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Group name update ho gaya! ✅')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ============ CHANGE GROUP BIO (Admin only) ============
  Future<void> _changeGroupBio() async {
    final TextEditingController bioController = TextEditingController(
      text: _groupData?['bio'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Group Bio'),
          content: TextField(
            controller: bioController,
            maxLines: 3,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Group ke baare mein kuch likhein...',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .update({'bio': bioController.text.trim()});

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _groupData?['bio'] = bioController.text.trim();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Group bio update ho gayi! ✅')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ============ LEAVE GROUP ============
  Future<void> _leaveGroup() async {
    bool confirm = await _showConfirmDialog(
      'Leave Group',
      'Kya aap is group se exit karna chahte hain?',
    );

    if (!confirm) return;

    try {
      List<String> members =
          List<String>.from(_groupData?['members'] ?? []);
      members.remove(currentUserId);

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'members': members});

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group se exit ho gaye')),
        );
      }
    } catch (e) {
      debugPrint('Leave group error: $e');
    }
  }

  // ============ DELETE GROUP (Admin only) ============
  Future<void> _deleteGroup() async {
    bool confirm = await _showConfirmDialog(
      'Delete Group',
      'Kya aap is group ko permanently delete karna chahte hain? Ye undo nahi hoga.',
    );

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .delete();

      QuerySnapshot messages = await FirebaseFirestore.instance
          .collection('group_messages')
          .where('groupId', isEqualTo: widget.groupId)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group delete ho gaya')),
        );
      }
    } catch (e) {
      debugPrint('Delete group error: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_groupData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Info')),
        body: const Center(child: Text('Group nahi mila')),
      );
    }

    String groupName = _groupData?['name'] ?? 'Group';
    String groupBio = _groupData?['bio'] ?? '';
    String? groupPhoto = _groupData?['groupPhoto'];
    List<String> members = List<String>.from(_groupData?['members'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============ GROUP AVATAR + NAME ============
            Container(
              padding: const EdgeInsets.all(20),
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
                  GestureDetector(
                    onTap: _isAdmin ? _changeGroupPhoto : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: groupPhoto == null
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF667EEA)
                                    ],
                                  )
                                : null,
                          ),
                          child: groupPhoto != null
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(groupPhoto),
                                    width: 110,
                                    height: 110,
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
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        if (_isAdmin)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A6CF7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
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
                    groupName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (groupBio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        groupBio,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${members.length} members',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ============ MEMBERS LIST (Direct Screen) ============
            Container(
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
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people,
                              color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Members (${members.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        // Add button (admin)
                        if (_isAdmin)
                          GestureDetector(
                            onTap: _showAddMembers,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.person_add,
                                      color: Color(0xFF10B981), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Members list
                  ...members.map((memberId) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberId)
                          .get(),
                      builder: (context, snap) {
                        String username = 'User';
                        String? avatarUrl;
                        if (snap.hasData && snap.data!.exists) {
                          Map<String, dynamic> data =
                              snap.data!.data() as Map<String, dynamic>;
                          username = data['username'] ?? 'User';
                          avatarUrl = data['avatarUrl'];
                        }
                        bool isCreator =
                            memberId == _groupData?['createdBy'];
                        bool isMe = memberId == currentUserId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              AvatarWidget(
                                avatarUrl: avatarUrl,
                                username: username,
                                size: 45,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            isMe
                                                ? '$username (You)'
                                                : username,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCreator) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF59E0B)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Text('👑',
                                                    style: TextStyle(
                                                        fontSize: 10)),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Admin',
                                                  style: TextStyle(
                                                    color:
                                                        Color(0xFFF59E0B),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Remove button (admin can remove others)
                              if (_isAdmin && !isCreator && !isMe)
                                GestureDetector(
                                  onTap: () =>
                                      _removeMember(memberId, username),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ============ ADMIN OPTIONS ============
            Container(
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
                            color: const Color(0xFF8B5CF6).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.settings,
                              color: Color(0xFF8B5CF6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Group Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Change Name (admin only)
                  if (_isAdmin) ...[
                    _buildOption(
                      Icons.edit,
                      'Change Group Name',
                      const Color(0xFF8B5CF6),
                      null,
                      _changeGroupName,
                    ),
                    const Divider(height: 1),

                    // Change Bio (admin only)
                    _buildOption(
                      Icons.info_outline,
                      'Change Group Bio',
                      const Color(0xFFF59E0B),
                      null,
                      _changeGroupBio,
                    ),
                    const Divider(height: 1),
                  ],

                  // Leave Group
                  _buildOption(
                    Icons.exit_to_app,
                    'Exit Group',
                    const Color(0xFFEF4444),
                    null,
                    _leaveGroup,
                    isRed: true,
                  ),

                  // Delete Group (admin only)
                  if (_isAdmin) ...[
                    const Divider(height: 1),
                    _buildOption(
                      Icons.delete_forever,
                      'Delete Group',
                      const Color(0xFFEF4444),
                      null,
                      _deleteGroup,
                      isRed: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    IconData icon,
    String title,
    Color color,
    String? subtitle,
    VoidCallback onTap, {
    bool isRed = false,
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isRed
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
