import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fadocx/l10n/app_localizations.dart';
import 'package:fadocx/core/presentation/widgets/connected_sheet_group.dart';

/// Settings tile for displaying a URL or email.
/// Shows the value and a chevron, tapping opens a bottom sheet
/// with **Copy** and **Open** actions.
class LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final LinkType type;

  const LinkTile.url({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  }) : type = LinkType.url;

  const LinkTile.email({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  }) : type = LinkType.email;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow
              .withValues(alpha: brightness == Brightness.dark ? 0.96 : 0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Value preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ConnectedSheetGroup(
              children: [
                ConnectedSheetRow(
                  leading: SheetIconChip.icon(
                    icon: Icons.content_copy,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: brightness == Brightness.dark ? 0.18 : 0.14,
                    ),
                  ),
                  title: AppLocalizations.of(context)!.linkTileCopy,
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .linkTileCopiedToClipboard)),
                    );
                  },
                ),
                ConnectedSheetRow(
                  leading: SheetIconChip.icon(
                    icon: type == LinkType.email
                        ? Icons.email_outlined
                        : Icons.open_in_browser,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: brightness == Brightness.dark ? 0.18 : 0.14,
                    ),
                  ),
                  title: type == LinkType.email
                      ? AppLocalizations.of(context)!.linkTileSendEmail
                      : AppLocalizations.of(context)!.linkTileOpenInBrowser,
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openLink(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    try {
      final uri = type == LinkType.email
          ? Uri.parse('mailto:$value?subject=Fadocx%20Query')
          : Uri.parse(value);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.linkTileCouldNotOpen(value))),
        );
      }
    }
  }
}

enum LinkType { url, email }
