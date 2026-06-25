import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class PhotoTile extends StatelessWidget {
  final FieldItem item;
  final double size;

  const PhotoTile({super.key, required this.item, this.size = double.infinity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/viewer/${item.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _buildImage(),
              // Bottom gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              // Tag label bottom-left
              if (item.lastTag.isNotEmpty)
                Positioned(
                  bottom: 5,
                  left: 6,
                  child: Text(
                    item.lastTag,
                    style: jakartaStyle(10.5, Colors.white,
                            weight: FontWeight.w700)
                        .copyWith(
                      shadows: [
                        const Shadow(
                            blurRadius: 4, color: Colors.black54)
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Video badge top-right
              if (item.type == ItemType.video)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              // Camera-roll dot top-left
              if (item.source == StorageSource.roll)
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.rollDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              // Obs-only pin placeholder
              if (item.isObsOnly)
                Container(
                  color: context.appSurface2,
                  child: Icon(Icons.location_pin,
                      color: context.appMuted, size: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.filePath == null || item.isObsOnly) {
      return Container(color: const Color(0xFFD0D4C0));
    }
    final file = File(item.filePath!);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(color: const Color(0xFFD0D4C0));
  }
}
