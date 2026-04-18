import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:fadocx/core/presentation/widgets/floating_dock_scaffold.dart';
import 'package:fadocx/config/routing/app_router.dart';
import 'package:fadocx/config/theme/app_theme.dart';
import 'package:fadocx/core/utils/logger.dart';
import 'package:fadocx/features/settings/presentation/providers/settings_providers.dart';
import 'package:fadocx/features/settings/domain/entities/app_settings.dart';

/// Browse screen - file system browser for importing documents
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late String _selectedCategory;
  final Set<String> _selectedFilePaths = {};
  bool _isMultiSelect = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'all';
  }

  @override
  Widget build(BuildContext context) {
    return FloatingDockScaffold(
      appBarContent: _buildAppBarContent(context),
      currentRoute: RouteNames.browse,
      body: _buildBody(),
      floatingActionButton: _selectedFilePaths.isNotEmpty
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.download),
              label: Text(
                  'Import ${_selectedFilePaths.length} File${_selectedFilePaths.length > 1 ? 's' : ''}'),
              onPressed: () => _importSelectedFiles(),
            )
          : null,
    );
  }

  Widget _buildAppBarContent(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Text(
          'Browse & Import',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top padding
          const SizedBox(height: 88),

          // Category tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(context, 'all', 'All Files', Icons.folder),
                _buildCategoryChip(
                    context, 'pdf', 'PDFs', Icons.picture_as_pdf),
                _buildCategoryChip(
                    context, 'documents', 'Docs', Icons.description),
                _buildCategoryChip(
                    context, 'spreadsheets', 'Sheets', Icons.table_chart),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Browse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Pick Files from Device'),
                  onPressed: () => _pickFiles(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    FilterChip(
                      label: const Text('Multi-select'),
                      selected: _isMultiSelect,
                      onSelected: (selected) {
                        setState(() => _isMultiSelect = selected);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selected files list
          if (_selectedFilePaths.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No files selected',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Pick Files" to select documents to import',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected: ${_selectedFilePaths.length} file${_selectedFilePaths.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedFilePaths.length,
                    itemBuilder: (context, index) {
                      final filePath = _selectedFilePaths.toList()[index];
                      final fileName = filePath.split('/').last;
                      final fileExtension = _getFileExtension(fileName);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: ListTile(
                            leading: _getFileIcon(fileExtension, size: 28),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(fileExtension.toUpperCase()),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedFilePaths.remove(filePath);
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Bottom padding
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      BuildContext context, String category, String label, IconData icon) {
    final isActive = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isActive,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
          // TODO: Filter selected files by category when implemented
        },
        backgroundColor: Colors.transparent,
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileType, {double size = 24}) {
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = AppColors.categoryPdf;
        break;
      case 'docx':
      case 'doc':
      case 'odt':
      case 'rtf':
      case 'txt':
        iconData = Icons.description;
        color = AppColors.categoryDoc;
        break;
      case 'xlsx':
      case 'xls':
      case 'ods':
      case 'csv':
        iconData = Icons.table_chart;
        color = AppColors.categorySheet;
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow;
        color = AppColors.categorySlide;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = AppColors.categoryDefault;
    }

    return Icon(iconData, color: color, size: size);
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'odt',
          'rtf',
          'txt',
          'xlsx',
          'xls',
          'ods',
          'csv',
          'ppt',
          'pptx',
          'odp',
        ],
        allowMultiple: _isMultiSelect,
        onFileLoading: (FilePickerStatus status) {
          log.d('File picker status: $status');
        },
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (_isMultiSelect) {
            for (final file in result.files) {
              _selectedFilePaths.add(file.path ?? '');
            }
          } else {
            _selectedFilePaths.clear();
            _selectedFilePaths.add(result.files.first.path ?? '');
          }
        });
        log.i('Selected ${_selectedFilePaths.length} files');
      }
    } catch (e) {
      log.e('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  Future<void> _importSelectedFiles() async {
    if (_selectedFilePaths.isEmpty) return;

    try {
      final mutator = ref.read(recentFilesMutatorProvider);
      final now = DateTime.now();

      for (final filePath in _selectedFilePaths) {
        final fileName = filePath.split('/').last;
        final fileExtension = _getFileExtension(fileName);

        // Calculate file size
        int fileSizeBytes = 0;
        try {
          final file = File(filePath);
          fileSizeBytes = await file.length();
        } catch (e) {
          log.w('Could not calculate file size for $filePath: $e');
        }

        // Create RecentFile entity with required parameters
        final recentFile = RecentFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              _selectedFilePaths.toList().indexOf(filePath).toString(),
          fileName: fileName,
          filePath: filePath,
          fileType: fileExtension,
          dateOpened: now,
          dateModified: now,
          pagePosition: 0,
          fileSizeBytes: fileSizeBytes,
          syncStatus: 'local',
        );

        await mutator.addRecentFile(recentFile);
      }

      if (mounted) {
        log.i('Imported ${_selectedFilePaths.length} files successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Imported ${_selectedFilePaths.length} file${_selectedFilePaths.length > 1 ? 's' : ''}')),
        );

        // Clear selection
        setState(() {
          _selectedFilePaths.clear();
        });

        // Navigate back to documents
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      log.e('Error importing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing files: $e')),
        );
      }
    }
  }
}
