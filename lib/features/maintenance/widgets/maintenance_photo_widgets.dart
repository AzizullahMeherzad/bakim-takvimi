import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/maintenance_record.dart';

class MaintenancePhotoGrid extends StatelessWidget {
  const MaintenancePhotoGrid({
    super.key,
    required this.photos,
    this.onRemove,
    this.emptyText,
  });

  final List<MaintenancePhoto> photos;
  final ValueChanged<MaintenancePhoto>? onRemove;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          emptyText ?? 'Henüz fotoğraf eklenmedi.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: photos
          .map(
            (photo) => _MaintenancePhotoCard(
              photo: photo,
              onRemove: onRemove == null ? null : () => onRemove!(photo),
            ),
          )
          .toList(),
    );
  }
}

class _MaintenancePhotoCard extends StatelessWidget {
  const _MaintenancePhotoCard({required this.photo, this.onRemove});

  final MaintenancePhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 138,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => MaintenancePhotoPreviewPage(photo: photo),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        tooltip: 'Fotoğrafı kaldır',
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  photo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaintenancePhotoPreviewPage extends StatelessWidget {
  const MaintenancePhotoPreviewPage({super.key, required this.photo});

  final MaintenancePhoto photo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(photo.name)),
      backgroundColor: colorScheme.surface,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.6,
          maxScale: 5,
          child: Image.file(
            File(photo.path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fotoğraf görüntülenemedi.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
