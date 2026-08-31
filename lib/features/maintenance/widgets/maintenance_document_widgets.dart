import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../models/maintenance_record.dart';

class MaintenanceDocumentList extends StatelessWidget {
  const MaintenanceDocumentList({
    super.key,
    required this.documents,
    this.onRemove,
    this.emptyText = 'Belge eklenmemiş.',
  });

  final List<MaintenanceDocument> documents;
  final ValueChanged<MaintenanceDocument>? onRemove;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          emptyText,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < documents.length; index++) ...[
          _MaintenanceDocumentCard(
            document: documents[index],
            onRemove: onRemove,
          ),
          if (index < documents.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MaintenanceDocumentCard extends StatelessWidget {
  const _MaintenanceDocumentCard({required this.document, this.onRemove});

  final MaintenanceDocument document;
  final ValueChanged<MaintenanceDocument>? onRemove;

  IconData get _icon {
    if (document.isPdf) return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  String get _extensionLabel {
    final extension = document.extension.trim();
    return extension.isEmpty ? 'DOSYA' : extension.toUpperCase();
  }

  Future<void> _openDocument(BuildContext context) async {
    final file = File(document.filePath);

    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya cihazda bulunamadı.')),
      );
      return;
    }

    final result = await OpenFilex.open(document.filePath);
    if (!context.mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Dosya açılamadı.' : result.message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDocument(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: document.isPdf
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _icon,
                  color: document.isPdf
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _extensionLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Aç',
                onPressed: () => _openDocument(context),
                icon: const Icon(Icons.open_in_new_rounded),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Kaldır',
                  onPressed: () => onRemove!(document),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
