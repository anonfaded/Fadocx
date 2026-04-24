import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/lokit_service.dart';

class LOKitTestScreen extends StatefulWidget {
  const LOKitTestScreen({super.key});

  @override
  State<LOKitTestScreen> createState() => _LOKitTestScreenState();
}

class _LOKitTestScreenState extends State<LOKitTestScreen> {
  bool _initialized = false;
  bool _loading = false;
  String? _error;
  Uint8List? _renderedImage;
  Map<String, dynamic>? _docInfo;
  int _currentPart = 0;

  @override
  void dispose() {
    LOKitService.closeDocument();
    super.dispose();
  }

  Future<void> _initAndLoad(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _renderedImage = null;
      _docInfo = null;
    });

    try {
      if (!_initialized) {
        final ok = await LOKitService.init();
        if (!ok) {
          setState(() {
            _error = 'LibreOfficeKit init failed';
            _loading = false;
          });
          return;
        }
        _initialized = true;
      }

      final info = await LOKitService.loadDocument(path);
      if (info == null) {
        setState(() {
          _error = 'Failed to load document';
          _loading = false;
        });
        return;
      }

      _docInfo = info;
      _currentPart = 0;

      final image = await LOKitService.renderPageFit(
        part: _currentPart,
        maxWidth: 1080,
        maxHeight: 1920,
      );

      setState(() {
        _renderedImage = image;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'doc', 'odt', 'rtf', 'xlsx', 'xls', 'ods', 'pptx', 'ppt', 'odp'],
    );
    if (result != null && result.files.single.path != null) {
      _initAndLoad(result.files.single.path!);
    }
  }

  Future<void> _nextPart() async {
    final parts = _docInfo?['parts'] as int? ?? 1;
    if (_currentPart < parts - 1) {
      _currentPart++;
      _renderPart();
    }
  }

  Future<void> _prevPart() async {
    if (_currentPart > 0) {
      _currentPart--;
      _renderPart();
    }
  }

  Future<void> _renderPart() async {
    setState(() => _loading = true);
    try {
      final image = await LOKitService.renderPageFit(
        part: _currentPart,
        maxWidth: 1080,
        maxHeight: 1920,
      );
      setState(() {
        _renderedImage = image;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOKit Spike Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _loading ? null : _pickFile,
            tooltip: 'Open File',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _pickFile, child: const Text('Try Another File')),
            ],
          ),
        ),
      );
    }

    if (_renderedImage == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Tap the folder icon to open a document'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Document'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_docInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              '${_docInfo!['typeName']} | '
              '${_currentPart + 1}/${_docInfo!['parts']} | '
              '${_docInfo!['width']}x${_docInfo!['height']} twips',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.memory(
                _renderedImage!,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
        if ((_docInfo?['parts'] as int? ?? 1) > 1)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPart > 0 ? _prevPart : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_currentPart + 1} / ${_docInfo!['parts']}'),
                IconButton(
                  onPressed: _currentPart < (_docInfo!['parts'] as int) - 1 ? _nextPart : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
