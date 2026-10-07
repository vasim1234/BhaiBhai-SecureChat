import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'friend_request.dart';
import 'avatar_builder.dart';

// ============ USER PROFILE SCREEN (Modern Design with Bio/Status/Birthday) ============
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
  String _bio = '';
  String _status = '';
  String _birthday = '';
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        _email = userData?['email'] ?? '';
        _bio = userData?['bio'] ?? '';
        _status = userData?['status'] ?? '';

        _avatarUrl = (userData != null && userData.containsKey('avatarUrl'))
            ? userData['avatarUrl']
            : null;

        if (userData?['birthday'] != null) {
          Timestamp ts = userData!['birthday'];
          _birthday = DateFormat('dd MMM yyyy').format(ts.toDate());
        }

        if (userData?['createdAt'] != null) {
          Timestamp ts = userData!['createdAt'];
          _memberSince =
              '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}';
        }
      }

      bool isFriend = await areFriends(currentUid, widget.userId);

      QuerySnapshot sentRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: currentUid)
          .where('receiverId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      QuerySnapshot receivedRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('senderId', isEqualTo: widget.userId)
          .where('receiverId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .get();

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
          if (receivedRequests.docs.isNotEmpty) {
            _requestId = receivedRequests.docs.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
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
          content:
              Text(result == 'success' ? 'Friend request bhej di!' : result),
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
                  child: Column(
                    children: [
                      // ============ HEADER WITH GRADIENT BANNER ============
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            height: 190,
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
                                Positioned(
                                  top: -30,
                                  right: -30,
                                  child: Container(
                                    width: 140,
                                    height: 140,
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
                                    width: 170,
                                    height: 170,
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
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.arrow_back,
                                                color: Colors.white),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
                            top: 120,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: AvatarWidget(
                                avatarUrl: _avatarUrl,
                                username: widget.username,
                                size: 110,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ============ NAME + EMAIL ============
                      const SizedBox(height: 75),
                      Text(
                        widget.username,
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
                            _email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),

                      // ============ STATUS / QUOTE ============
                      if (_status.isNotEmpty) ...[
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
                            '"$_status"',
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

                      // ============ BIO ============
                      if (_bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            _bio,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // ============ BIRTHDAY ============
                      if (_birthday.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cake,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(
                              _birthday,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],

                      // ============ STATUS BADGE ============
                      const SizedBox(height: 15),
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

                      const SizedBox(height: 25),

                      // ============ ACTION BUTTONS ============
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildActionButtons(context),
                      ),

                      const SizedBox(height: 25),

                      // ============ MEMBER SINCE CARD ============
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today,
                                    color: Color(0xFF8B5CF6), size: 20),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Member Since',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _memberSince,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // ============ ACTION BUTTONS WIDGET ============
  Widget _buildActionButtons(BuildContext context) {
    if (_isBlocked) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _toggleBlock,
          icon: const Icon(Icons.lock_open, color: Colors.white),
          label: const Text('Unblock User',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B7280),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
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
              icon: const Icon(Icons.chat_bubble, color: Colors.white),
              label: const Text('Message',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _unFriend,
              icon: const Icon(Icons.person_remove, color: Color(0xFFEF4444)),
              label: const Text('Unfriend',
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ] else if (_requestSent) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.access_time, color: Colors.white),
              label: const Text('Request Pending',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9CA3AF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ] else if (_requestReceived) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _acceptRequest,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Accept Friend Request',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendRequest,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Add Friend',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],

        const SizedBox(height: 15),

        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _toggleBlock,
            icon: const Icon(Icons.block, color: Color(0xFFEF4444), size: 20),
            label: const Text(
              'Block User',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============ STATUS BADGE WIDGET ============
  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
