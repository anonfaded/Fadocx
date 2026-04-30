import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fadocx/core/presentation/constants.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static final releaseDate = DateTime(2026, 4, 30);

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Released today';
    } else if (diff.inDays == 1) {
      return 'Released yesterday';
    } else if (diff.inDays < 7) {
      return 'Released ${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return 'Released $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return 'Released $months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = diff.inDays ~/ 365;
      return 'Released $years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: GestureDetector(
          onTap: () {},
          child: Stack(
            children: [
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                height: 8,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surface.withValues(alpha: 0.95)
                          : theme.colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => context.pop(),
                                iconSize: 20,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              Expanded(
                                child: Text(
                                  "What's New",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildReleaseCard(context),
          const SizedBox(height: 24),
          Text(
            "What's Included",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            icon: Icons.picture_as_pdf,
            title: 'Documents & Spreadsheets',
            body:
                'PDFs render via the native pdfrx engine. Microsoft Office files (DOCX, DOC, '
                'XLSX, XLS, PPT, PPTX) and OpenDocument formats (ODT, ODS, ODP) along with '
                'RTF are powered by the embedded LibreOffice Kit for desktop-class rendering. '
                'CSV parsing uses native Android performance — all running offline with zero '
                'data leaving your device.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.document_scanner,
            title: 'Intelligent OCR & On-Device AI',
            body:
                'Built on Tesseract OCR with OpenCV preprocessing, the scanner detects and '
                'extracts English text from images with confidence scoring. Dual PSM modes and '
                'automatic rotation correction ensure accurate results. All AI processing — '
                'including OCR, image analysis, and text recognition — runs entirely on your '
                'device. No cloud, no uploads, complete privacy.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.highlight,
            title: 'Syntax Highlighting',
            body:
                'Code files (Java, Python, Shell, HTML, JSON, XML, Markdown, Log) are rendered '
                'with color-coded syntax highlighting. Adjustable font size, word wrap, and '
                'a dedicated reading mode make long files comfortable to browse.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.timer,
            title: 'Reading Stats Dashboard',
            body:
                'The home screen stats card tracks total documents, storage used, and cumulative '
                'reading time across all your files. When you open a document, a session timer '
                'starts automatically. When you leave the viewer, the elapsed time is calculated '
                'and added to that file\'s total — so you can see how much time you\'ve spent reading.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.folder,
            title: 'Library with Category Folders',
            body:
                'Imported files are automatically organized into category folders — PDF, Docs, '
                'Sheets, Slides, Code, Scans, and Other. Browse by category with chip filters, '
                'search by name or type, and sort by date or size. All files live in Fadocx\'s '
                'private storage, keeping your documents organized and separate from public folders.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.drive_file_move,
            title: 'File Management',
            body:
                'Import documents from your device into Fadocx\'s private storage with automatic '
                'category sorting. Rename files with extension preservation, create duplicates '
                'with auto-numbered names, or export copies to Downloads or a custom location. '
                'Long-press for multi-select mode and batch operations. A context menu on each '
                'file gives quick access to all actions.',
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.palette,
            title: 'Light & Dark Themes',
            body:
                'Fadocx adapts to your preference with fully designed light and dark color '
                'schemes. The entire UI — including PDF viewer, code renderer, and menus — '
                'respects your system theme or manual toggle.',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Planned',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUpcomingItem(
            context,
            icon: Icons.cloud_upload,
            title: 'FadDrive',
            description: 'End-to-end encrypted cloud sync for your documents across all devices.',
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.edit,
            title: 'Document Editing',
            description: 'Edit documents directly in the app with full formatting support.',
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.bookmark,
            title: 'Bookmarks & Annotations',
            description: 'Mark important pages and add notes for quick reference.',
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.swap_horiz,
            title: 'Document Conversion',
            description: 'Convert documents between formats (PDF to DOCX, DOCX to PDF, etc.).',
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.dark_mode,
            title: 'AMOLED Black Theme',
            description: 'Pure black theme for AMOLED screens with deeper contrast.',
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.translate,
            title: 'More OCR Languages',
            description: 'Multi-language OCR support beyond English.',
          ),
          const SizedBox(height: 28),
          _buildSupportCard(context),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        '${releaseDate.day} ${_monthName(releaseDate.month)} ${releaseDate.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.primary,
                ),
                child: Text(
                  'v1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _timeAgo(releaseDate),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'An offline-first document viewer built for privacy and performance. '
            'Open, read, and search your files — no internet required, no data ever leaves your device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  Widget _buildSupportCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            theme.colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            SimpleIcons.patreon,
            size: 36,
            color: const Color(0xFFD4A017),
          ),
          const SizedBox(height: 12),
          Text(
            'Thank You for Using Fadocx',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'If you find value in this app and want to give back, '
            'consider becoming a patron. You\'ll get premium benefits '
            'across all FadSec Lab apps.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPatreonSheet(context),
              icon: const Icon(SimpleIcons.patreon, size: 18),
              label: const Text('Become a Patron'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4A017),
                side: const BorderSide(color: Color(0xFFD4A017)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatreonSheet(BuildContext context) {
    const patreonUrl = 'https://patreon.com/c/fadedx';
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF2F2F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        padding: EdgeInsets.only(
          top: 6,
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Column(
                children: [
                  const Icon(SimpleIcons.patreon, size: 40, color: Color(0xFFD4A017)),
                  const SizedBox(height: 12),
                  Text(
                    'Support Development',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                patreonDescription,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _sheetActionButton(
              context,
              icon: SimpleIcons.patreon,
              label: 'Visit Patreon',
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(patreonUrl);
              },
            ),
            const SizedBox(height: 8),
            _sheetActionButton(
              context,
              icon: Icons.content_copy,
              label: 'Copy Link',
              onTap: () {
                Clipboard.setData(ClipboardData(text: patreonUrl));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : Colors.white;
    final textColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: bgColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
