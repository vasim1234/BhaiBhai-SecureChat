import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ============ CHANGE GROUP NAME (Admin only) ============
  Future<void> _changeGroupName() async {
    final TextEditingController nameController = TextEditingController(
      text: _groupData?['name'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                    const SnackBar(content: Text('Group name update ho gaya!')),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                    const SnackBar(content: Text('Group bio update ho gayi!')),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
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

  // ============ MEMBERS SHEET ============
  void _showMembers() {
    List<String> members =
        List<String>.from(_groupData?['members'] ?? []);

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
                '${members.length} Members',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    String memberId = members[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(memberId)
                          .get(),
                      builder: (context, snap) {
                        String username = 'User';
                        String? avatarUrl;
                        if (snap.hasData && snap.data!.exists) {
                          username = snap.data!['username'] ?? 'User';
                          avatarUrl = snap.data!['avatarUrl'];
                        }
                        bool isCreator = memberId == _groupData?['createdBy'];
                        return ListTile(
                          leading: AvatarWidget(
                            avatarUrl: avatarUrl,
                            username: username,
                            size: 45,
                          ),
                          title: Text(username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          trailing: isCreator
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A6CF7)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Color(0xFF4A6CF7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
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
    List<String> members =
        List<String>.from(_groupData?['members'] ?? []);

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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF667EEA)],
                      ),
                    ),
                    child: Center(
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
                    Text(
                      groupBio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${members.length} members',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  _buildOption(
                    Icons.people,
                    'Members',
                    const Color(0xFF3B82F6),
                    '${members.length} log',
                    () => _showMembers(),
                  ),
                  const Divider(height: 1),
                  if (_isAdmin) ...[
                    _buildOption(
                      Icons.edit,
                      'Change Group Name',
                      const Color(0xFF8B5CF6),
                      null,
                      _changeGroupName,
                    ),
                    const Divider(height: 1),
                    _buildOption(
                      Icons.info_outline,
                      'Change Group Bio',
                      const Color(0xFFF59E0B),
                      null,
                      _changeGroupBio,
                    ),
                    const Divider(height: 1),
                  ],
                  _buildOption(
                    Icons.exit_to_app,
                    'Exit Group',
                    const Color(0xFFEF4444),
                    null,
                    _leaveGroup,
                    isRed: true,
                  ),
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
