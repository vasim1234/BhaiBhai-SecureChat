import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'friend_request.dart';
import 'user_profile.dart';
import 'avatar_builder.dart';
import 'group_info.dart';

// ============ CHAT SCREEN ============
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
  bool _isChatMuted = false;

  // ============ WALLPAPER ============
  String? _chatWallpaper;

  final List<Map<String, String>> _presetWallpapers = [
    {'name': 'Default', 'value': 'F5F7FB'},
    {'name': 'Blue', 'value': 'E3F2FD'},
    {'name': 'Green', 'value': 'E8F5E9'},
    {'name': 'Pink', 'value': 'FCE4EC'},
    {'name': 'Purple', 'value': 'F3E5F5'},
    {'name': 'Yellow', 'value': 'FFF9C4'},
    {'name': 'Grey', 'value': 'EEEEEE'},
    {'name': 'Dark', 'value': '37474F'},
  ];

  final Map<String, Uint8List> _imageCache = {};

  // ============ VOICE MESSAGE VARIABLES ============
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _recorderInitialized = false;
  bool _playerInitialized = false;
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
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
    _initRecorder();
    _initPlayer();
    _loadWallpaper();
    _loadMuteStatus();
  }

  Future<void> _initRecorder() async {
    if (_recorderInitialized) return;
    try {
      await _audioRecorder.openRecorder();
      _recorderInitialized = true;
    } catch (e) {
      debugPrint('Recorder init error: $e');
    }
  }

  Future<void> _initPlayer() async {
    if (_playerInitialized) return;
    try {
      await _audioPlayer.openPlayer();
      _playerInitialized = true;
    } catch (e) {
      debugPrint('Player init error: $e');
    }
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _recordTimer?.cancel();
    if (_recorderInitialized) _audioRecorder.closeRecorder();
    if (_playerInitialized) _audioPlayer.closePlayer();
    super.dispose();
  }

  // ============ MUTE ============
  Future<void> _loadMuteStatus() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('muted_chats')
          .doc(chatId)
          .get();
      if (mounted) {
        setState(() => _isChatMuted = doc.exists);
      }
    } catch (e) {
      debugPrint('Mute load error: $e');
    }
  }

  Future<void> _toggleMute() async {
    try {
      if (_isChatMuted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('muted_chats')
            .doc(chatId)
            .delete();
        setState(() => _isChatMuted = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications ON 🔔')),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('muted_chats')
            .doc(chatId)
            .set({'mutedAt': FieldValue.serverTimestamp()});
        setState(() => _isChatMuted = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications MUTE 🔕')),
          );
        }
      }
    } catch (e) {
      debugPrint('Mute toggle error: $e');
    }
  }

  // ============ WALLPAPER ============
  Future<void> _loadWallpaper() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('wallpapers')
          .doc(chatId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _chatWallpaper = doc['wallpaper'];
        });
      }
    } catch (e) {
      debugPrint('Wallpaper load error: $e');
    }
  }

  Future<void> _saveWallpaper(String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('wallpapers')
          .doc(chatId)
          .set({
        'wallpaper': value,
        'updatedAt': FieldValue.serverTimestamp()
      });

      setState(() => _chatWallpaper = value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper change ho gaya! ✅')),
        );
      }
    } catch (e) {
      debugPrint('Save wallpaper error: $e');
    }
  }

  void _showWallpaperPicker() {
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wallpaper,
                          color: Color(0xFF8B5CF6), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chat Wallpaper',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Preset Wallpapers',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetWallpapers.length,
                    itemBuilder: (context, index) {
                      final wp = _presetWallpapers[index];
                      final colorValue =
                          int.parse('FF${wp['value']}', radix: 16);
                      bool isSelected = _chatWallpaper == wp['value'];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _saveWallpaper(wp['value']!);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Color(0xFF667EEA))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _pickWallpaperFromGallery();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.photo_library,
                            color: Color(0xFF667EEA)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gallery se photo choose karo',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Color(0xFF667EEA)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickWallpaperFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (image == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 40,
        minWidth: 720,
        minHeight: 720,
      );

      if (compressedFile == null) return;

      final bytes = await compressedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      if (base64Image.length > 800000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo bahut badi hai, chhoti try karein')),
          );
        }
        return;
      }

      await _saveWallpaper('IMG:$base64Image');
    } catch (e) {
      debugPrint('Wallpaper pick error: $e');
    }
  }

  Widget _buildWallpaperBackground() {
    if (_chatWallpaper == null || _chatWallpaper == 'F5F7FB') {
      return Container(color: const Color(0xFFF5F7FB));
    }

    if (_chatWallpaper!.startsWith('IMG:')) {
      try {
        final base64Str = _chatWallpaper!.substring(4);
        return Positioned.fill(
          child: Image.memory(
            base64Decode(base64Str),
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.35),
          ),
        );
      } catch (e) {
        return Container(color: const Color(0xFFF5F7FB));
      }
    } else {
      try {
        final color = Color(int.parse('FF${_chatWallpaper}', radix: 16));
        return Positioned.fill(child: Container(color: color));
      } catch (e) {
        return Container(color: const Color(0xFFF5F7FB));
      }
    }
  }

  // ============ OPEN LINK ============
  Future<void> _openLink(String url) async {
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http://') &&
          !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }

      final Uri uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link nahi khul paya')),
          );
        }
      }
    } catch (e) {
      debugPrint('Link error: $e');
    }
  }

  // ============ FETCH LINK PREVIEW ============
  Future<Map<String, dynamic>?> _fetchLinkPreview(String text) async {
    final urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final match = urlRegex.firstMatch(text);
    if (match == null) return null;

    String url = match.group(0)!;

    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String? videoId;
        if (url.contains('youtu.be/')) {
          videoId = url.split('youtu.be/').last.split('?').first;
        } else if (url.contains('v=')) {
          videoId = url.split('v=').last.split('&').first;
        } else if (url.contains('/shorts/')) {
          videoId = url.split('/shorts/').last.split('?').first;
        }

        if (videoId != null && videoId.isNotEmpty) {
          try {
            final response = await http.get(
              Uri.parse(
                  'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'),
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              return {
                'linkUrl': url,
                'linkTitle': data['title'] ?? 'YouTube Video',
                'linkThumbnail':
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                'linkType': 'youtube',
              };
            }
          } catch (e) {
            debugPrint('YouTube oEmbed error: $e');
          }

          return {
            'linkUrl': url,
            'linkTitle': 'YouTube Video',
            'linkThumbnail':
                'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            'linkType': 'youtube',
          };
        }
      }

      if (url.contains('instagram.com')) {
        return {
          'linkUrl': url,
          'linkTitle': 'Instagram Post',
          'linkThumbnail': null,
          'linkType': 'instagram',
        };
      }

      return {
        'linkUrl': url,
        'linkTitle': url,
        'linkThumbnail': null,
        'linkType': 'other',
      };
    } catch (e) {
      debugPrint('Link preview error: $e');
      return null;
    }
  }

  // ============ BUILD MESSAGE WITH CLICKABLE LINKS (Manual Regex) ============
  Widget _buildMessageWithLinks(String text, bool isMe, bool isDeleted) {
    final urlRegex = RegExp(
      r'(https?://[^\s]+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isDeleted
              ? Colors.grey[600]
              : (isMe ? Colors.white : Colors.black87),
          fontSize: 16,
          fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
        ),
      );
    }

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: isDeleted
                ? Colors.grey[600]
                : (isMe ? Colors.white : Colors.black87),
            fontSize: 16,
            fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
          ),
        ));
      }

      final linkText = match.group(0)!;
      spans.add(TextSpan(
        text: linkText,
        style: TextStyle(
          color: isMe ? Colors.white : const Color(0xFF2196F3),
          decoration: TextDecoration.underline,
          decorationColor: isMe ? Colors.white : const Color(0xFF2196F3),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openLink(linkText),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: isDeleted
              ? Colors.grey[600]
              : (isMe ? Colors.white : Colors.black87),
          fontSize: 16,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ============ BUILD LINK PREVIEW ============
  Widget _buildLinkPreview({
    required String url,
    required String title,
    String? thumbnail,
    required String type,
    required bool isMe,
  }) {
    return GestureDetector(
      onTap: () => _openLink(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color:
              isMe ? Colors.white.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMe
                ? Colors.white.withOpacity(0.2)
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null && thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  thumbnail,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      color: isMe
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          type == 'youtube'
                              ? Icons.play_circle_fill
                              : Icons.link,
                          color: type == 'youtube'
                              ? Colors.red
                              : Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    type == 'youtube'
                        ? Icons.play_circle_fill
                        : type == 'instagram'
                            ? Icons.camera_alt
                            : Icons.link,
                    color: type == 'youtube'
                        ? Colors.red
                        : type == 'instagram'
                            ? const Color(0xFFE1306C)
                            : (isMe ? Colors.white70 : Colors.grey[600]),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'youtube'
                              ? 'YouTube'
                              : type == 'instagram'
                                  ? 'Instagram'
                                  : 'Link',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white70
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // ============ VOICE RECORDING ============
  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() => _isRecording = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Mic permission denied')),
          );
        }
        return;
      }

      await _initRecorder();
      if (!_recorderInitialized) {
        setState(() => _isRecording = false);
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacMP4,
      );

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordDuration = Duration(seconds: timer.tick);
          });
          if (timer.tick >= 300) _stopRecording(send: true);
        }
      });
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording({bool send = false}) async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stopRecorder();

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

  Future<void> _playVoice(String messageId, String base64Audio) async {
    try {
      if (_isPlayingMap[messageId] == true) {
        await _audioPlayer.stopPlayer();
        setState(() {
          _isPlayingMap[messageId] = false;
          _playPositionMap[messageId] = Duration.zero;
        });
        return;
      }

      await _audioPlayer.stopPlayer();
      await _initPlayer();

      final bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/play_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File(path);
      await file.writeAsBytes(bytes);

      _audioPlayer.setSubscriptionDuration(const Duration(milliseconds: 100));

      _audioPlayer.onProgress?.listen((e) {
        if (mounted) {
          setState(() {
            _playPositionMap[messageId] = e.position;
            _playDurationMap[messageId] = e.duration;
          });
        }
      });

      await _audioPlayer.startPlayer(
        fromURI: path,
        codec: Codec.aacMP4,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlayingMap[messageId] = false;
              _playPositionMap[messageId] = Duration.zero;
            });
          }
          file.delete();
        },
      );

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

    Map<String, dynamic>? linkPreview;
    if (messageText.isNotEmpty &&
        (messageText.contains('http://') ||
            messageText.contains('https://'))) {
      linkPreview = await _fetchLinkPreview(messageText);
    }

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
        'linkUrl': linkPreview?['linkUrl'],
        'linkTitle': linkPreview?['linkTitle'],
        'linkThumbnail': linkPreview?['linkThumbnail'],
        'linkType': linkPreview?['linkType'],
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'isEdited': false,
        'isDeleted': false,
        'isRead': false,
        'isStarred': false,
      });

      DocumentSnapshot mutedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUid)
          .collection('muted_chats')
          .doc(chatId)
          .get();

      if (!mutedDoc.exists) {
        await _sendNotification(
          messageText.isNotEmpty
              ? messageText
              : (voiceBase64 != null ? '🎤 Voice message' : 'Photo bheji'),
        );
      }
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

  Future<void> _toggleStarMessage(String docId, bool isStarred) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(docId)
        .update({'isStarred': !isStarred});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isStarred ? 'Star hata diya' : 'Message star kar diya ⭐'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
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
              ListTile(
                leading: Icon(
                  (data['isStarred'] ?? false)
                      ? Icons.star
                      : Icons.star_border,
                  color: const Color(0xFFF59E0B),
                ),
                title: Text(
                  (data['isStarred'] ?? false)
                      ? 'Unstar Message'
                      : 'Star Message',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleStarMessage(docId, data['isStarred'] ?? false);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.forward, color: Color(0xFF10B981)),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardPicker(message, data);
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

  // ============ FORWARD PICKER ============
  void _showForwardPicker(String message, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
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
                  'Forward to...',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final users = userSnap.data!.docs.where((doc) {
                        return doc.id != currentUserId;
                      }).toList();

                      if (users.isEmpty) {
                        return const Center(
                            child: Text('Koi dusra user nahi hai'));
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          String username =
                              userData['username'] ?? 'User';
                          String? avatarUrl = userData['avatarUrl'];
                          String otherUid = userDoc.id;

                          return ListTile(
                            leading: AvatarWidget(
                              avatarUrl: avatarUrl,
                              username: username,
                              size: 45,
                            ),
                            title: Text(username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(userData['email'] ?? ''),
                            trailing: const Icon(Icons.send,
                                color: Color(0xFF10B981)),
                            onTap: () async {
                              Navigator.pop(context);
                              await _forwardMessage(
                                  otherUid, message, data);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _forwardMessage(String receiverUid, String message,
      Map<String, dynamic> data) async {
    try {
      List<String> uids = [currentUserId, receiverUid]..sort();
      String newChatId = '${uids[0]}_${uids[1]}';

      String forwardedText = message;
      if (forwardedText.isEmpty) {
        if (data['imageBase64'] != null) {
          forwardedText = '📷 Forwarded photo';
        } else if (data['voiceBase64'] != null) {
          forwardedText = '🎤 Forwarded voice message';
        } else if (data['linkUrl'] != null) {
          forwardedText = data['linkUrl'];
        }
      }

      await FirebaseFirestore.instance.collection('chats').add({
        'chatId': newChatId,
        'members': uids,
        'senderId': currentUserId,
        'receiverId': receiverUid,
        'message': '↪️ Forwarded\n\n$forwardedText',
        'imageBase64': data['imageBase64'],
        'voiceBase64': data['voiceBase64'],
        'linkUrl': data['linkUrl'],
        'linkTitle': data['linkTitle'],
        'linkThumbnail': data['linkThumbnail'],
        'linkType': data['linkType'],
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'isEdited': false,
        'isDeleted': false,
        'isRead': false,
        'isStarred': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message forward ho gaya! ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forward error: $e')),
        );
      }
    }
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
            icon: Icon(
              _isChatMuted
                  ? Icons.notifications_off
                  : Icons.notifications_active,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
          ),
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
              if (value == 'wallpaper') _showWallpaperPicker();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'wallpaper',
                child: Row(
                  children: [
                    Icon(Icons.wallpaper, color: Color(0xFF8B5CF6)),
                    SizedBox(width: 10),
                    Text('Wallpaper'),
                  ],
                ),
              ),
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
            child: Stack(
              children: [
                _buildWallpaperBackground(),
                StreamBuilder<QuerySnapshot>(
                  stream: _getMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    var docs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp expiresAt = data['expiresAt'];
                      return expiresAt.toDate().isAfter(DateTime.now());
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text(
                              'Abhi koi message nahi hai. Hi bhejein!'));
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
                        String? linkUrl = data['linkUrl'];
                        bool isStarred = data['isStarred'] ?? false;

                        return GestureDetector(
                          onLongPress: isDeleted
                              ? null
                              : () => _showMessageOptions(
                                  doc.id,
                                  data['message'] ?? '',
                                  isMe,
                                  data),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context)
                                        .size
                                        .width *
                                    0.75,
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
                                    : (isMe
                                        ? null
                                        : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft:
                                      Radius.circular(isMe ? 15 : 0),
                                  bottomRight:
                                      Radius.circular(isMe ? 0 : 15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (replyTo != null)
                                    Container(
                                      padding:
                                          const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(
                                          bottom: 5),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white
                                                .withOpacity(0.2)
                                            : Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border(
                                          left: BorderSide(
                                            color: isMe
                                                ? Colors.white
                                                : const Color(
                                                    0xFF667EEA),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            replyTo['senderName'] ??
                                                'User',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: isMe
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF667EEA),
                                            ),
                                          ),
                                          Text(
                                            replyTo['message'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow
                                                .ellipsis,
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

                                  if (linkUrl != null && !isDeleted)
                                    _buildLinkPreview(
                                      url: linkUrl,
                                      title:
                                          data['linkTitle'] ?? '',
                                      thumbnail:
                                          data['linkThumbnail'],
                                      type: data['linkType'] ??
                                          'other',
                                      isMe: isMe,
                                    ),

                                  if (imageBase64 != null &&
                                      !isDeleted)
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: _buildCachedImage(
                                          imageBase64),
                                    ),
                                  if (voiceBase64 != null &&
                                      !isDeleted)
                                    _buildVoicePlayer(
                                        doc.id, voiceBase64, isMe),

                                  if (data['message'] != null &&
                                      (data['message'] as String)
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5),
                                      child: _buildMessageWithLinks(
                                        data['message'],
                                        isMe,
                                        isDeleted,
                                      ),
                                    ),
                                  if (isStarred && !isDeleted)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Color(0xFFF59E0B),
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
                                          padding: const EdgeInsets
                                                  .only(
                                              left: 5),
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
              ],
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                    fontSize: 12,
                                    color: Colors.black54),
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
                          icon: const Icon(Icons.close,
                              color: Colors.red),
                          onPressed: _cancelRecording,
                        ),
                        IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.red),
                          onPressed: () =>
                              _stopRecording(send: true),
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
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTapDown: (_isBlocked ||
                                !_areFriends ||
                                _msgController.text
                                    .trim()
                                    .isNotEmpty)
                            ? null
                            : (_) => _startRecording(),
                        onTapUp: (_isBlocked ||
                                !_areFriends ||
                                _msgController.text
                                    .trim()
                                    .isNotEmpty)
                            ? null
                            : (_) => _stopRecording(send: true),
                        onTapCancel: (_isBlocked ||
                                !_areFriends ||
                                _msgController.text
                                    .trim()
                                    .isNotEmpty)
                            ? null
                            : () => _cancelRecording(),
                        onTap: (_isBlocked ||
                                !_areFriends ||
                                _msgController.text.trim().isEmpty)
                            ? null
                            : () async {
                                await _sendMessage(
                                    replyTo: _replyToData);
                                setState(
                                    () => _replyToData = null);
                              },
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
                          child:
                              _msgController.text.trim().isEmpty
                                  ? const Icon(Icons.mic,
                                      color: Colors.white)
                                  : const Icon(Icons.send,
                                      color: Colors.white),
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
  String? _groupPhoto;
  Map<String, dynamic>? _groupReplyToData;
  final Map<String, String> _senderNameCache = {};
  final Map<String, String?> _senderAvatarCache = {};
  final Map<String, Color> _senderColorCache = {};

  static const String ONESIGNAL_APP_ID =
      '05bee600-4a45-44e5-b35e-5328544c25c1';
  static const String ONESIGNAL_REST_API_KEY = String.fromEnvironment(
    'ONESIGNAL_REST_API_KEY',
    defaultValue: '',
  );

  final List<Color> _senderColors = [
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFF3F51B5),
    const Color(0xFF009688),
    const Color(0xFFFF5722),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
    const Color(0xFFE65100),
    const Color(0xFF4CAF50),
    const Color(0xFFF44336),
  ];

  @override
  void initState() {
    super.initState();
    _loadGroupPhoto();
    _markGroupAsRead();
  }

  // ============ GROUP READ MARK ============
  Future<void> _markGroupAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .set({
        'lastRead': {currentUserId: FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Mark group read error: $e');
    }
  }

  Future<void> _loadGroupPhoto() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _groupPhoto = doc['groupPhoto'];
        });
      }
    } catch (e) {
      debugPrint('Error loading group photo: $e');
    }
  }

  Future<void> _loadSenderInfo(String senderId) async {
    if (_senderNameCache.containsKey(senderId)) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      if (doc.exists) {
        _senderNameCache[senderId] = doc['username'] ?? 'User';
        _senderAvatarCache[senderId] = doc['avatarUrl'];
        int colorIndex = senderId.hashCode.abs() % _senderColors.length;
        _senderColorCache[senderId] = _senderColors[colorIndex];
      }
    } catch (e) {
      debugPrint('Error loading sender: $e');
    }
  }

  // ============ GROUP MESSAGE OPTIONS ============
  void _showGroupMessageOptions(
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
                      _groupReplyToData = {
                        'message': message,
                        'senderName': data['senderName'] ?? 'User',
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
                    _editGroupMessage(docId, message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGroupMessage(docId);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editGroupMessage(String docId, String oldMessage) async {
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
                      .collection('group_messages')
                      .doc(docId)
                      .update({
                    'message': editController.text.trim(),
                    'isEdited': true,
                  });
                }
                if (mounted) Navigator.pop(context);
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

  Future<void> _deleteGroupMessage(String docId) async {
    await FirebaseFirestore.instance
        .collection('group_messages')
        .doc(docId)
        .update({
      'isDeleted': true,
      'message': 'Ye message delete kar diya gaya hai',
      'imageBase64': null,
    });
  }

  // ============ GROUP NOTIFICATION ============
  Future<void> _sendGroupNotification({
    required String memberId,
    required String groupName,
    required String senderName,
    required String message,
    required bool hasImage,
  }) async {
    try {
      String body;
      if (message.isNotEmpty) {
        body = '$senderName: $message';
      } else if (hasImage) {
        body = '$senderName: 📷 Photo';
      } else {
        body = '$senderName: Naya message';
      }

      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $ONESIGNAL_REST_API_KEY',
        },
        body: jsonEncode({
          'app_id': ONESIGNAL_APP_ID,
          'include_aliases': {
            'external_id': [memberId],
          },
          'target_channel': 'push',
          'headings': {'en': groupName},
          'contents': {'en': body},
        }),
      );
    } catch (e) {
      debugPrint('Group notif error: $e');
    }
  }

  Future<void> _openLink(String url) async {
    try {
      String finalUrl = url;
      if (!finalUrl.startsWith('http://') &&
          !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      final Uri uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Link error: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchLinkPreview(String text) async {
    final urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final match = urlRegex.firstMatch(text);
    if (match == null) return null;

    String url = match.group(0)!;

    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String? videoId;
        if (url.contains('youtu.be/')) {
          videoId = url.split('youtu.be/').last.split('?').first;
        } else if (url.contains('v=')) {
          videoId = url.split('v=').last.split('&').first;
        } else if (url.contains('/shorts/')) {
          videoId = url.split('/shorts/').last.split('?').first;
        }

        if (videoId != null && videoId.isNotEmpty) {
          try {
            final response = await http.get(
              Uri.parse(
                  'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'),
            );
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              return {
                'linkUrl': url,
                'linkTitle': data['title'] ?? 'YouTube Video',
                'linkThumbnail':
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                'linkType': 'youtube',
              };
            }
          } catch (e) {
            debugPrint('YouTube oEmbed error: $e');
          }
          return {
            'linkUrl': url,
            'linkTitle': 'YouTube Video',
            'linkThumbnail':
                'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            'linkType': 'youtube',
          };
        }
      }

      if (url.contains('instagram.com')) {
        return {
          'linkUrl': url,
          'linkTitle': 'Instagram Post',
          'linkThumbnail': null,
          'linkType': 'instagram',
        };
      }

      return {
        'linkUrl': url,
        'linkTitle': url,
        'linkThumbnail': null,
        'linkType': 'other',
      };
    } catch (e) {
      return null;
    }
  }

  Widget _buildMessageWithLinks(String text, bool isMe) {
    final urlRegex = RegExp(
      r'(https?://[^\s]+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    }

    List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ));
      }

      final linkText = match.group(0)!;
      spans.add(TextSpan(
        text: linkText,
        style: TextStyle(
          color: isMe ? Colors.white : const Color(0xFF2196F3),
          decoration: TextDecoration.underline,
          decorationColor: isMe ? Colors.white : const Color(0xFF2196F3),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openLink(linkText),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildLinkPreview({
    required String url,
    required String title,
    String? thumbnail,
    required String type,
    required bool isMe,
  }) {
    return GestureDetector(
      onTap: () => _openLink(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color:
              isMe ? Colors.white.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMe
                ? Colors.white.withOpacity(0.2)
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null && thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  thumbnail,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      color: isMe
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          type == 'youtube'
                              ? Icons.play_circle_fill
                              : Icons.link,
                          color: type == 'youtube'
                              ? Colors.red
                              : Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    type == 'youtube'
                        ? Icons.play_circle_fill
                        : type == 'instagram'
                            ? Icons.camera_alt
                            : Icons.link,
                    color: type == 'youtube'
                        ? Colors.red
                        : type == 'instagram'
                            ? const Color(0xFFE1306C)
                            : (isMe
                                ? Colors.white70
                                : Colors.grey[600]),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'youtube'
                              ? 'YouTube'
                              : type == 'instagram'
                                  ? 'Instagram'
                                  : 'Link',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white70
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Future<void> _sendMessage({String? imageBase64}) async {
    if (_msgController.text.trim().isEmpty && imageBase64 == null) return;

    String messageText = _msgController.text.trim();

    Map<String, dynamic>? linkPreview;
    if (messageText.isNotEmpty &&
        (messageText.contains('http://') ||
            messageText.contains('https://'))) {
      linkPreview = await _fetchLinkPreview(messageText);
    }

    DateTime expiryTime = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('group_messages').add({
      'groupId': widget.groupId,
      'senderId': currentUserId,
      'message': messageText,
      'imageBase64': imageBase64,
      'linkUrl': linkPreview?['linkUrl'],
      'linkTitle': linkPreview?['linkTitle'],
      'linkThumbnail': linkPreview?['linkThumbnail'],
      'linkType': linkPreview?['linkType'],
      'replyTo': _groupReplyToData,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiryTime),
      'isEdited': false,
      'isDeleted': false,
    });

    // 👇 GROUP NOTIFICATION BHEJO
    try {
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupDoc.exists) {
        List<String> members =
            List<String>.from(groupDoc['members'] ?? []);
        String groupName = groupDoc['name'] ?? 'Group';

        DocumentSnapshot senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        String senderName = senderDoc.exists
            ? (senderDoc['username'] ?? 'User')
            : 'User';

        for (String memberId in members) {
          if (memberId == currentUserId) continue;

          try {
            DocumentSnapshot mutedDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(memberId)
                .collection('muted_groups')
                .doc(widget.groupId)
                .get();

            if (mutedDoc.exists) continue;

            await _sendGroupNotification(
              memberId: memberId,
              groupName: groupName,
              senderName: senderName,
              message: messageText,
              hasImage: imageBase64 != null,
            );
          } catch (e) {
            debugPrint('Error sending notif to $memberId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Group notification error: $e');
    }

    _msgController.clear();
    if (mounted) {
      setState(() => _groupReplyToData = null);
    }
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
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
              ),
            ).then((_) => _loadGroupPhoto());
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _groupPhoto == null
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF667EEA)
                          ],
                        )
                      : null,
                ),
                child: _groupPhoto != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_groupPhoto!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.groupName.isNotEmpty
                              ? widget.groupName[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.groupName,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
                  return const Center(
                      child: CircularProgressIndicator());
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

                for (var doc in docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  _loadSenderInfo(data['senderId']);
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data =
                        doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    String senderId = data['senderId'];
                    String? imageBase64 = data['imageBase64'];
                    Timestamp? msgTime = data['timestamp'];
                    String? linkUrl = data['linkUrl'];
                    bool isDeleted = data['isDeleted'] ?? false;
                    bool isEdited = data['isEdited'] ?? false;
                    Map<String, dynamic>? replyTo = data['replyTo'];

                    String senderName =
                        _senderNameCache[senderId] ?? 'User';
                    String? senderAvatar =
                        _senderAvatarCache[senderId];
                    Color senderColor = _senderColorCache[senderId] ??
                        const Color(0xFF667EEA);

                    return GestureDetector(
                      onLongPress: isDeleted
                          ? null
                          : () {
                              data['senderName'] = senderName;
                              _showGroupMessageOptions(
                                doc.id,
                                data['message'] ?? '',
                                isMe,
                                data,
                              );
                            },
                      child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserProfileScreen(
                                      userId: senderId,
                                      username: senderName,
                                    ),
                                  ),
                                );
                              },
                              child: AvatarWidget(
                                avatarUrl: senderAvatar,
                                username: senderName,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width *
                                        0.72,
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
                                color: isDeleted
                                    ? Colors.grey[200]
                                    : (isMe ? null : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft:
                                      Radius.circular(isMe ? 15 : 0),
                                  bottomRight:
                                      Radius.circular(isMe ? 0 : 15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && !isDeleted)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 4),
                                      child: Text(
                                        senderName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: senderColor,
                                        ),
                                      ),
                                    ),

                                  if (replyTo != null)
                                    Container(
                                      padding:
                                          const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(
                                          bottom: 5),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white
                                                .withOpacity(0.2)
                                            : Colors.grey[200],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border(
                                          left: BorderSide(
                                            color: isMe
                                                ? Colors.white
                                                : const Color(
                                                    0xFF667EEA),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            replyTo['senderName'] ??
                                                'User',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: isMe
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF667EEA),
                                            ),
                                          ),
                                          Text(
                                            replyTo['message'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow
                                                .ellipsis,
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

                                  if (linkUrl != null && !isDeleted)
                                    _buildLinkPreview(
                                      url: linkUrl,
                                      title:
                                          data['linkTitle'] ?? '',
                                      thumbnail:
                                          data['linkThumbnail'],
                                      type: data['linkType'] ??
                                          'other',
                                      isMe: isMe,
                                    ),

                                  if (imageBase64 != null &&
                                      !isDeleted)
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(imageBase64),
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context,
                                                error,
                                                stackTrace) =>
                                            const SizedBox(
                                          width: 200,
                                          height: 150,
                                          child: Center(
                                              child: Icon(
                                                  Icons.broken_image,
                                                  color:
                                                      Colors.grey)),
                                        ),
                                      ),
                                    ),

                                  if (data['message'] != null &&
                                      (data['message'] as String)
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5),
                                      child: _buildMessageWithLinks(
                                        data['message'],
                                        isMe,
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
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                      if (msgTime != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('hh:mm a')
                                              .format(msgTime.toDate()),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            AvatarWidget(
                              avatarUrl: null,
                              username: 'Me',
                              size: 32,
                            ),
                          ],
                        ],
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
                if (_groupReplyToData != null)
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _groupReplyToData!['senderName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              Text(
                                _groupReplyToData!['message'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _groupReplyToData = null);
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file,
                          color: Color(0xFF667EEA)),
                      onPressed:
                          _isUploading ? null : _showAttachmentOptions,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
