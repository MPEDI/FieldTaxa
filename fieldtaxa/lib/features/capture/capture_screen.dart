import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';

const _uuid = Uuid();

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _isVideo = false;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder area (~70% height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.72,
            child: Container(
              color: const Color(0xFF0A0F07),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          // Top hint pill
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Tap to capture',
                    style: jakartaStyle(13, Colors.white,
                        weight: FontWeight.w600)),
              ),
            ),
          ),
          // Close button top-left
          Positioned(
            top: 54,
            left: 18,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo/Video toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModeBtn(
                          label: 'Photo',
                          active: !_isVideo,
                          onTap: () => setState(() => _isVideo = false),
                        ),
                        const SizedBox(width: 24),
                        _ModeBtn(
                          label: 'Video',
                          active: _isVideo,
                          onTap: () => setState(() => _isVideo = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Shutter row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Camera roll thumbnail
                        GestureDetector(
                          onTap: _importFromRoll,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white30, width: 1),
                            ),
                            child: const Icon(Icons.photo_library_outlined,
                                color: Colors.white60, size: 22),
                          ),
                        ),
                        // Shutter button
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isVideo
                                      ? const Color(0xFFC84040)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Import pill
                        GestureDetector(
                          onTap: _importFromRoll,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white30, width: 1),
                            ),
                            child: const Icon(Icons.upload_rounded,
                                color: Colors.white60, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Import from camera roll button
                    TextButton.icon(
                      onPressed: _importFromRoll,
                      icon: const Icon(Icons.photo_library_rounded,
                          color: Colors.white70, size: 16),
                      label: Text('Import from camera roll',
                          style: jakartaStyle(12, Colors.white70,
                              weight: FontWeight.w600)),
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

  Future<void> _capture() async {
    final source =
        _isVideo ? ImageSource.camera : ImageSource.camera;
    final XFile? file = _isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);
    if (file != null && mounted) {
      final draftId = _uuid.v4();
      context.push('/classify/$draftId', extra: {
        'filePath': file.path,
        'tags': <List<String>>[],
      });
    }
  }

  Future<void> _importFromRoll() async {
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isNotEmpty && mounted) {
      // Navigate to classify with first image
      final file = files.first;
      final draftId = _uuid.v4();
      context.push('/classify/$draftId', extra: {
        'filePath': file.path,
        'tags': <List<String>>[],
      });
    }
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: jakartaStyle(13, active ? Colors.white : Colors.white54,
            weight: active ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}
