import 'package:fadocx/l10n/app_localizations.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';

/// Callbacks for file action bottom sheet. Null callbacks hide their row.
class FileActionCallbacks {
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onConvert;
  final VoidCallback? onUpload;
  final VoidCallback? onFileInfo;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyText;

  const FileActionCallbacks({
    this.onRename,
    this.onDuplicate,
    this.onExport,
    this.onConvert,
    this.onUpload,
    this.onFileInfo,
    this.onDelete,
    this.onCopyText,
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
    isScrollControlled: true,
    enableDrag: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
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
                    AppLocalizations.of(context)!.fileActionSubtitle,
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
                title: AppLocalizations.of(ctx)!.fileActionRename,
                iconColor: Theme.of(context).colorScheme.primary,
                subtitle: AppLocalizations.of(ctx)!.fileActionRenameDesc,
                onTap: callbacks.onRename!,
              ),
            if (callbacks.onDuplicate != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.content_copy,
                title: AppLocalizations.of(ctx)!.fileActionDuplicate,
                iconColor: Colors.blue,
                subtitle: AppLocalizations.of(ctx)!.fileActionDuplicateDesc,
                onTap: callbacks.onDuplicate!,
              ),
            if (callbacks.onExport != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.save_alt,
                title: AppLocalizations.of(ctx)!.fileActionExport,
                iconColor: Colors.green,
                subtitle: AppLocalizations.of(ctx)!.fileActionExportDesc,
                showChevron: true,
                onTap: callbacks.onExport!,
              ),
            if (callbacks.onCopyText != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.content_paste,
                title: AppLocalizations.of(ctx)!.fileActionCopyText,
                iconColor: Colors.teal,
                subtitle: AppLocalizations.of(ctx)!.fileActionCopyTextDesc,
                onTap: callbacks.onCopyText!,
              ),
            if (callbacks.onConvert != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.transform,
                title: AppLocalizations.of(ctx)!.fileActionConvert,
                subtitle: AppLocalizations.of(ctx)!.fileActionConvertDesc,
                iconColor: Colors.purple,
                showComingSoonBadge: true,
                onTap: callbacks.onConvert!,
              ),
            if (callbacks.onUpload != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.cloud_upload_outlined,
                title: AppLocalizations.of(ctx)!.fileActionUpload,
                subtitle: AppLocalizations.of(ctx)!.fileActionUploadDesc,
                iconColor: Colors.blue,
                showComingSoonBadge: true,
                onTap: callbacks.onUpload!,
              ),
            if (callbacks.onFileInfo != null)
              _buildActionRow(
                context: ctx,
                icon: Icons.info_outline,
                title: AppLocalizations.of(ctx)!.fileActionFileInfo,
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
                    AppLocalizations.of(context)!.comingSoon,
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
