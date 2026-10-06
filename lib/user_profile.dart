import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_request.dart';
import 'avatar_builder.dart';

// ============ USER PROFILE SCREEN ============
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isFriend = false;
  bool _requestSent = false;
  bool _requestReceived = false;
  bool _isBlocked = false;
  String _requestId = '';
  String _email = '';
  String _memberSince = 'Oct 2026';
  String? _avatarUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. User data fetch
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _email = userDoc['email'] ?? '';
        _avatarUrl = userDoc['avatarUrl'];
        if (userDoc['createdAt'] != null) {
          Timestamp ts = userDoc['createdAt'];
          _memberSince =
              '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}';
        }
      }

      // 2. Friends check
      bool isFriend = await areFriends(currentUid, widget.userId);

      // 3. Sent requests check
      QuerySnapshot sentRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUid)
          .where('receiverId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      // 4. Received requests check
      QuerySnapshot receivedRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: widget.userId)
          .where('receiverId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .get();

      // 5. Block check
      DocumentSnapshot blockDoc = await FirebaseFirestore.instance
          .collection('blocked')
          .doc('${currentUid}_${widget.userId}')
          .get();

      if (mounted) {
        setState(() {
          _isFriend = isFriend;
          _requestSent = sentRequests.docs.isNotEmpty;
          _requestReceived = receivedRequests.docs.isNotEmpty;
          _isBlocked = blockDoc.exists;
          _avatarUrl = userDoc['avatarUrl'];
          if (receivedRequests.docs.isNotEmpty) {
            _requestId = receivedRequests.docs.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // *** AGAR KOI ERROR AATA HAI ***
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _sendRequest() async {
    String result = await sendFriendRequest(widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == 'success' ? 'Friend request bhej di!' : result),
        ),
      );
      if (result == 'success') {
        setState(() => _requestSent = true);
      }
    }
  }

  Future<void> _acceptRequest() async {
    await acceptFriendRequest(_requestId, widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accept ho gayi!')),
      );
      setState(() {
        _isFriend = true;
        _requestReceived = false;
      });
    }
  }

  Future<void> _unFriend() async {
    await unFriend(widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unfriend kar diya')),
      );
      setState(() {
        _isFriend = false;
        _requestSent = false;
        _requestReceived = false;
      });
    }
  }

  Future<void> _toggleBlock() async {
    String currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (_isBlocked) {
      await FirebaseFirestore.instance
          .collection('blocked')
          .doc('${currentUid}_${widget.userId}')
          .delete();
      setState(() => _isBlocked = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked')),
      );
    } else {
      await FirebaseFirestore.instance
          .collection('blocked')
          .doc('${currentUid}_${widget.userId}')
          .set({
        'blockerId': currentUid,
        'blockedId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _isBlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          'Error: $_errorMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                        ),
                        child: AvatarWidget(
                          avatarUrl: _avatarUrl,
                          username: widget.username,
                          size: 100,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _email,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 15),

                      // Status Badge
                      if (_isFriend)
                        _buildStatusBadge('Aap dono friend hain', Colors.green,
                            Icons.check_circle)
                      else if (_requestSent)
                        _buildStatusBadge('Friend request bhej di hai',
                            Colors.orange, Icons.access_time)
                      else if (_requestReceived)
                        _buildStatusBadge('Isne aapko request bheji hai',
                            Colors.blue, Icons.person_add)
                      else if (_isBlocked)
                        _buildStatusBadge('Aapne is user ko block kiya hai',
                            Colors.red, Icons.block),

                      const SizedBox(height: 30),

                      // === ACTION BUTTONS ===
                      if (_isBlocked)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _toggleBlock,
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Unblock User'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        if (_isFriend) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context, {
                                  'action': 'chat',
                                  'uid': widget.userId,
                                  'name': widget.username,
                                });
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _unFriend,
                              icon: const Icon(Icons.person_remove),
                              label: const Text('Unfriend'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else if (_requestSent) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.access_time),
                              label: const Text('Request Pending'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else if (_requestReceived) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _acceptRequest,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept Friend Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _sendRequest,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Friend'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _toggleBlock,
                            icon: const Icon(Icons.block, color: Colors.red),
                            label: const Text('Block User',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Member Since',
                                    style: TextStyle(color: Colors.grey)),
                                Text(_memberSince,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
