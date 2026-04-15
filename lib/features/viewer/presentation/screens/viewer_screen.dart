import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:fadocx/core/utils/logger.dart';

/// Document Viewer Screen - displays PDF and text files
class ViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const ViewerScreen({
    required this.filePath,
    required this.fileName,
    super.key,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PdfController _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      log.i('Loading document: ${widget.fileName}');
      final file = File(widget.filePath);

      if (!await file.exists()) {
        setState(() {
          _error = 'File not found: ${widget.fileName}';
          _isLoading = false;
        });
        log.e('File not found: ${widget.filePath}');
        return;
      }

      final fileExtension = widget.filePath.toLowerCase().split('.').last;

      // Handle PDFs
      if (fileExtension == 'pdf') {
        _pdfController = PdfController(
          document: PdfDocument.openFile(widget.filePath),
        );

        // Get total pages
        final doc = await PdfDocument.openFile(widget.filePath);
        setState(() {
          _totalPages = doc.pagesCount;
          _isLoading = false;
        });
        log.i('PDF loaded: $_totalPages pages');
      } else {
        // For non-PDF files, just mark as loaded (will show message)
        setState(() {
          _isLoading = false;
        });
        log.i('File type: $fileExtension');
      }
    } catch (e, st) {
      log.e('Error loading document', e, st);
      setState(() {
        _error = 'Error loading file: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileExtension = widget.filePath.toLowerCase().split('.').last;
    final isPdf = fileExtension == 'pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : isPdf
                  ? _buildPdfViewer()
                  : _buildPlaceholder(),
      bottomNavigationBar: isPdf && !_isLoading && _error == null
          ? _buildPdfControls()
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return PdfView(
      controller: _pdfController,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
    );
  }

  Widget _buildPlaceholder() {
    final fileExtension = widget.filePath.toLowerCase().split('.').last;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(fileExtension),
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'File Type: ${fileExtension.toUpperCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview not yet supported',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with System App'),
            onPressed: () {
              log.i('TODO: Open with system app');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System app opening not yet implemented')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentPage > 1
                ? () => _pdfController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
          Text(
            'Page $_currentPage / $_totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'csv':
        return Icons.grid_on;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }
}
