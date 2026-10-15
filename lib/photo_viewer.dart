import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ============ PHOTO VIEWER SCREEN ============
class PhotoViewerScreen extends StatefulWidget {
  final String base64Image;
  final String messageId;
  final String chatId;
  final bool isGroup;
  final bool isMyMessage;

  const PhotoViewerScreen({
    super.key,
    required this.base64Image,
    required this.messageId,
    required this.chatId,
    this.isGroup = false,
    this.isMyMessage = false,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  bool _isSaving = false;
  late Uint8List _imageBytes;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _loadImage();

    // 👇 AUTO LOCAL SAVE + FIRESTORE DELETE (sirf receiver ke liye)
    // Sender ki photo delete NAHI hogi
    if (!widget.isMyMessage) {
      _saveLocallyAndDelete();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  // ============ IMAGE LOAD ============
  void _loadImage() {
    try {
      _imageBytes = base64Decode(widget.base64Image);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLoading = false);
          _fadeController.forward();
        }
      });
    } catch (e) {
      debugPrint('Image decode error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============ LOCAL SAVE + FIRESTORE DELETE (RECEIVER ONLY) ============
  Future<void> _saveLocallyAndDelete() async {
    try {
      // 1. Local save
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final file = File('${photoDir.path}/${widget.messageId}.jpg');
      await file.writeAsBytes(_imageBytes);

      // 2. Firestore se imageBase64 delete karo (local path save karo)
      String collection = widget.isGroup ? 'group_messages' : 'chats';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.messageId)
          .update({
        'imageBase64': null,
        'localPath': file.path,
        'isLocalOnly': true,
      });

      debugPrint('Photo saved locally + Firestore se deleted');
    } catch (e) {
      debugPrint('Save & delete error: $e');
    }
  }

  // ============ DOWNLOAD TO GALLERY ============
  Future<void> _downloadToGallery() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final result = await ImageGallerySaverPlus.saveImage(
        _imageBytes,
        quality: 100,
        name: 'BhaiBhai_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo gallery mein save ho gayi! ✅'),
              backgroundColor: Color(0xFF25D366),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save nahi ho payi')),
          );
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download error: $e')),
        );
      }
    }
  }

  // ============ SHARE ============
  Future<void> _sharePhoto() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bhai Bhai se photo',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
    }
  }

  // ============ DOUBLE TAP ZOOM ============
  void _handleDoubleTap() {
    if (_transformController.value.getMaxScaleOnAxis() > 1.0) {
      _transformController.value = Matrix4.identity();
    } else {
      _transformController.value = Matrix4.identity()..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ============ IMAGE AREA (FULL SCREEN) ============
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading HD photo...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Image.memory(
                            _imageBytes,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        color: Colors.white54, size: 60),
                                    SizedBox(height: 12),
                                    Text(
                                      'Photo load nahi ho payi',
                                      style:
                                          TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // ============ SWIPE DOWN TO CLOSE ============
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 80,
                color: Colors.transparent,
              ),
            ),
          ),

          // ============ TOP BAR ============
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hd, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'HD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ BOTTOM ACTION BAR ============
          if (!_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: _isSaving
                            ? Icons.hourglass_top
                            : Icons.download,
                        label: _isSaving ? 'Saving...' : 'Download',
                        onTap: _isSaving ? null : _downloadToGallery,
                        color: const Color(0xFF25D366),
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: _sharePhoto,
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
