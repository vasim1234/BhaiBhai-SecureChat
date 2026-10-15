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

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  bool _isSaving = false;
  late Uint8List _imageBytes;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImage();

    if (!widget.isMyMessage) {
      _saveLocallyAndDelete();
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _loadImage() {
    try {
      _imageBytes = base64Decode(widget.base64Image);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isLoading = false);
      });
    } catch (e) {
      debugPrint('Image decode error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLocallyAndDelete() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final file = File('${photoDir.path}/${widget.messageId}.jpg');
      await file.writeAsBytes(_imageBytes);

      String collection = widget.isGroup ? 'group_messages' : 'chats';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.messageId)
          .update({
        'imageBase64': null,
        'localPath': file.path,
        'isLocalOnly': true,
      });
    } catch (e) {
      debugPrint('Save & delete error: $e');
    }
  }

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
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download error: $e')),
        );
      }
    }
  }

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
    }
  }

  void _handleDoubleTap() {
    if (_transformController.value.getMaxScaleOnAxis() > 1.0) {
      _transformController.value = Matrix4.identity();
    } else {
      _transformController.value = Matrix4.identity()..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ============ FULL SCREEN IMAGE ============
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                        SizedBox(height: 20),
                        Text('Loading HD photo...',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Container(
                        width: size.width,
                        height: size.height,
                        color: Colors.black,
                        child: Image.memory(
                          _imageBytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white54, size: 60),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),

          // ============ TOP BAR ============
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  // HD Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hd, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('HD',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============ BOTTOM BUTTONS (FIXED) ============
          if (!_isLoading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Download button
                  GestureDetector(
                    onTap: _isSaving ? null : _downloadToGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF25D366).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSaving
                                ? Icons.hourglass_top
                                : Icons.download,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSaving ? 'Saving...' : 'Download',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Share button
                  GestureDetector(
                    onTap: _sharePhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Share',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
