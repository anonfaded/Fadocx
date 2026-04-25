import 'package:flutter/material.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';

/// Callbacks for file action bottom sheet. Null callbacks hide their row.
class FileActionCallbacks {
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onConvert;
  final VoidCallback? onUpload;
  final VoidCallback? onFileInfo;
  final VoidCallback? onDelete;

  const FileActionCallbacks({
    this.onRename,
    this.onDuplicate,
    this.onExport,
    this.onConvert,
    this.onUpload,
    this.onFileInfo,
    this.onDelete,
  });
}

/// Shows a styled file-action bottom sheet with the given callbacks.
/// Rows with null callbacks are automatically hidden.
void showFileActionBottomSheet({
  required BuildContext context,
  required RecentFile file,
  required FileActionCallbacks callbacks,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  Text(
                    file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'File actions and management',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Action rows
            if (callbacks.onRename != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.edit_outlined,
                title: 'Rename',
                iconColor: Theme.of(context).colorScheme.primary,
                subtitle: 'Change file name',
                onTap: callbacks.onRename!,
              ),
            if (callbacks.onDuplicate != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.content_copy,
                title: 'Duplicate',
                iconColor: Colors.blue,
                subtitle: 'Create a copy',
                onTap: callbacks.onDuplicate!,
              ),
            if (callbacks.onExport != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.save_alt,
                title: 'Export / Save As',
                iconColor: Colors.green,
                subtitle: 'Save a copy to Downloads',
                showChevron: true,
                onTap: callbacks.onExport!,
              ),
            if (callbacks.onConvert != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.transform,
                title: 'Convert',
                subtitle: 'Convert to another format',
                iconColor: Colors.purple,
                showComingSoonBadge: true,
                onTap: callbacks.onConvert!,
              ),
            if (callbacks.onUpload != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.cloud_upload_outlined,
                title: 'Upload to FadDrive',
                subtitle: 'Sync to cloud storage',
                iconColor: Colors.blue,
                showComingSoonBadge: true,
                onTap: callbacks.onUpload!,
              ),
            if (callbacks.onFileInfo != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.info_outline,
                title: 'File info',
                iconColor: Colors.grey,
                onTap: callbacks.onFileInfo!,
              ),
            // Divider before destructive action
            if (callbacks.onDelete != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                child: Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              ),
            if (callbacks.onDelete != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.delete_outline,
                title: 'Delete',
                iconColor: Colors.red,
                titleColor: Colors.red,
                onTap: callbacks.onDelete!,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

Widget _buildActionRow({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Color iconColor,
  String? subtitle,
  bool showChevron = false,
  bool showComingSoonBadge = false,
  Color? titleColor,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    )),
                    if (subtitle != null)
                      Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                  ],
                ),
              ),
              if (showComingSoonBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (showChevron)
                Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );
}
