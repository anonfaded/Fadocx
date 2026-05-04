import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fadocx/l10n/app_localizations.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static final releaseDate = DateTime(2026, 5, 4);

  String _timeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return l10n.timeAgoJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeAgoMinute(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeAgoHour(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeAgoDay(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.timeAgoWeek(weeks);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n.timeAgoMonth(months);
    } else {
      final years = (difference.inDays / 365).floor();
      return l10n.timeAgoYear(years);
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
                                  AppLocalizations.of(context)!.whatsNewTitle,
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
            AppLocalizations.of(context)!.whatsNewWhatsIncluded,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSection(
            context,
            icon: Icons.picture_as_pdf,
            title: AppLocalizations.of(context)!.whatsNewDocAndSheets,
            body: AppLocalizations.of(context)!.whatsNewDocAndSheetsDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.document_scanner,
            title: AppLocalizations.of(context)!.whatsNewOcrAi,
            body: AppLocalizations.of(context)!.whatsNewOcrAiDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.highlight,
            title: AppLocalizations.of(context)!.whatsNewSyntaxHighlighting,
            body: AppLocalizations.of(context)!.whatsNewSyntaxHighlightingDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.timer,
            title: AppLocalizations.of(context)!.whatsNewReadingStats,
            body: AppLocalizations.of(context)!.whatsNewReadingStatsDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.folder,
            title: AppLocalizations.of(context)!.whatsNewLibraryCategories,
            body: AppLocalizations.of(context)!.whatsNewLibraryCategoriesDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.drive_file_move,
            title: AppLocalizations.of(context)!.whatsNewFileManagement,
            body: AppLocalizations.of(context)!.whatsNewFileManagementDesc,
          ),
          const Divider(height: 32),
          _buildSection(
            context,
            icon: Icons.palette,
            title: AppLocalizations.of(context)!.whatsNewThemes,
            body: AppLocalizations.of(context)!.whatsNewThemesDesc,
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
                      AppLocalizations.of(context)!.whatsNewPlanned,
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
            title: AppLocalizations.of(context)!.whatsNewFadDrive,
            description: AppLocalizations.of(context)!.whatsNewFadDriveDesc,
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.edit,
            title: AppLocalizations.of(context)!.whatsNewEditing,
            description: AppLocalizations.of(context)!.whatsNewEditingDesc,
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.bookmark,
            title: AppLocalizations.of(context)!.whatsNewBookmarks,
            description: AppLocalizations.of(context)!.whatsNewBookmarksDesc,
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.swap_horiz,
            title: AppLocalizations.of(context)!.whatsNewConversion,
            description: AppLocalizations.of(context)!.whatsNewConversionDesc,
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.dark_mode,
            title: AppLocalizations.of(context)!.whatsNewAmoled,
            description: AppLocalizations.of(context)!.whatsNewAmoledDesc,
          ),
          const SizedBox(height: 10),
          _buildUpcomingItem(
            context,
            icon: Icons.translate,
            title: AppLocalizations.of(context)!.whatsNewMoreOcr,
            description: AppLocalizations.of(context)!.whatsNewMoreOcrDesc,
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
        '${releaseDate.day} ${_monthName(context, releaseDate.month)} ${releaseDate.year}';

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
                '$formattedDate · ${_timeAgo(context, releaseDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.whatsNewOfflineFirst,
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

  String _monthName(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context)!;
    switch (month) {
      case 1: return l10n.monthJan;
      case 2: return l10n.monthFeb;
      case 3: return l10n.monthMar;
      case 4: return l10n.monthApr;
      case 5: return l10n.monthMay;
      case 6: return l10n.monthJun;
      case 7: return l10n.monthJul;
      case 8: return l10n.monthAug;
      case 9: return l10n.monthSep;
      case 10: return l10n.monthOct;
      case 11: return l10n.monthNov;
      case 12: return l10n.monthDec;
      default: return '';
    }
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
            AppLocalizations.of(context)!.whatsNewThankYou,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.whatsNewThankYouDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _GoldPatreonButton(
            onTap: () => _showPatreonSheet(context),
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
                    AppLocalizations.of(context)!.supportDevelopment,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                AppLocalizations.of(context)!.patreonDescription,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _sheetActionButton(
              context,
              icon: SimpleIcons.patreon,
              label: AppLocalizations.of(context)!.visitPatreon,
              onTap: () {
                Navigator.pop(ctx);
                _openUrl(patreonUrl);
              },
            ),
            const SizedBox(height: 8),
            _sheetActionButton(
              context,
              icon: Icons.content_copy,
              label: AppLocalizations.of(context)!.copyLink,
              onTap: () {
                Clipboard.setData(ClipboardData(text: patreonUrl));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.copiedToClipboard)),
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

/// Patreon button with the same golden shimmer as the app bar icon.
/// Same 7-stop gold gradient sweep, but on a filled rounded container.
class _GoldPatreonButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GoldPatreonButton({required this.onTap});

  @override
  State<_GoldPatreonButton> createState() => _GoldPatreonButtonState();
}

class _GoldPatreonButtonState extends State<_GoldPatreonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 48,
                  color: const Color(0xFFD4A017),
                ),
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      const cycle = 300.0;
                      final offset = (_controller.value * cycle) % cycle;
                      return const LinearGradient(
                        tileMode: TileMode.repeated,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFC9A214),
                          Color(0xFFDAB125),
                          Color(0xFFF5D547),
                          Color(0xFFFFE873),
                          Color(0xFFF5D547),
                          Color(0xFFDAB125),
                          Color(0xFFC9A214),
                        ],
                        stops: [0.00, 0.18, 0.36, 0.50, 0.64, 0.82, 1.00],
                      ).createShader(Rect.fromLTWH(
                        bounds.left - offset,
                        bounds.top,
                        cycle,
                        bounds.height,
                      ));
                    },
                    blendMode: BlendMode.srcIn,
                    child: Container(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(SimpleIcons.patreon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.becomeAPatron,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
