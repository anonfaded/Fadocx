import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Industry-standard JSON viewer component
/// Features: Tree view, search, syntax highlighting, statistics, copy functionality
class JSONViewer extends StatefulWidget {
  final String jsonString;
  final String filePath;
  final bool expandAll;

  const JSONViewer({
    required this.jsonString,
    required this.filePath,
    this.expandAll = false,
    super.key,
  }) : super();

  @override
  State<JSONViewer> createState() => _JSONViewerState();
}

class _JSONViewerState extends State<JSONViewer> {
  late Map<String, dynamic> _parsedJson;
  String _searchQuery = '';
  bool _showStats = true;
  final Map<String, bool> _expandedNodes = {};
  List<String> _rawLines = [];

  @override
  void initState() {
    super.initState();
    try {
      _parsedJson = jsonDecode(widget.jsonString);
    } catch (e) {
      _parsedJson = {'error': 'Invalid JSON: $e'};
    }
    _computeRawLines();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('JSON: ${widget.filePath.split('/').last}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tree View'),
              Tab(text: 'Raw JSON'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTreeView(),
            _buildRawView(),
          ],
        ),
      ),
    );
  }

  /// Tree view with collapsible nodes, search, and statistics
  Widget _buildTreeView() {
    return Column(
      children: [
        // Search bar and stats
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search JSON keys...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      setState(() => _showStats = !_showStats);
                    },
                    tooltip: 'Toggle statistics',
                  ),
                ],
              ),
              if (_showStats)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildStatistics(),
                ),
            ],
          ),
        ),
        // Tree view
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildJsonTree(_parsedJson, 'root', 0),
            ),
          ),
        ),
      ],
    );
  }

  /// Recursive JSON tree builder
  Widget _buildJsonTree(
    dynamic value,
    String key,
    int depth, {
    bool isLast = true,
  }) {
    final nodeKey = '${List.filled(depth, ' ').join()}$key';
    final isExpanded = _expandedNodes[nodeKey] ?? widget.expandAll;

    // Filter by search query
    if (_searchQuery.isNotEmpty &&
        !key.toLowerCase().contains(_searchQuery) &&
        !_searchInValue(value, _searchQuery)) {
      return const SizedBox.shrink();
    }

    if (value is Map) {
      return _buildMapNode(
        value.cast<String, dynamic>(),
        key,
        depth,
        nodeKey,
        isExpanded,
        isLast,
      );
    } else if (value is List) {
      return _buildListNode(value, key, depth, nodeKey, isExpanded, isLast);
    } else {
      return _buildScalarNode(key, value, depth, isLast);
    }
  }

  /// Build Map/Object node
  Widget _buildMapNode(
    Map<String, dynamic> value,
    String key,
    int depth,
    String nodeKey,
    bool isExpanded,
    bool isLast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _expandedNodes[nodeKey] = !isExpanded);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  _buildTreeLine(depth, isLast),
                  Icon(
                    isExpanded
                        ? Icons.arrow_drop_down
                        : Icons.arrow_right,
                    size: 20,
                    color: Colors.blue,
                  ),
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '{${value.length} items}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const Spacer(),
                  _buildCopyButton(value),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 16.0 * (depth + 1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < value.length; i++)
                  _buildJsonTree(
                    value.values.elementAt(i),
                    value.keys.elementAt(i),
                    depth + 1,
                    isLast: i == value.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build Array/List node
  Widget _buildListNode(
    List<dynamic> value,
    String key,
    int depth,
    String nodeKey,
    bool isExpanded,
    bool isLast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _expandedNodes[nodeKey] = !isExpanded);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  _buildTreeLine(depth, isLast),
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 20,
                    color: Colors.orange,
                  ),
                  Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '[${value.length} items]',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const Spacer(),
                  _buildCopyButton(value),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 16.0 * (depth + 1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < value.length; i++)
                  _buildJsonTree(
                    value[i],
                    '[$i]',
                    depth + 1,
                    isLast: i == value.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build scalar value node
  Widget _buildScalarNode(String key, dynamic value, int depth, bool isLast) {
    final valueStr = value.toString();
    Color valueColor = Colors.grey;

    if (value is bool) valueColor = Colors.purple;
    if (value is num) valueColor = Colors.green;
    if (value is String) valueColor = Colors.red;
    if (value == null) valueColor = Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildTreeLine(depth, isLast),
          Text(
            '$key: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Courier',
              fontSize: 13,
            ),
          ),
          Expanded(
            child: SelectableText(
              value is String ? '"$valueStr"' : valueStr,
              style: TextStyle(
                color: valueColor,
                fontFamily: 'Courier',
                fontSize: 13,
              ),
            ),
          ),
          _buildCopyButton(value),
        ],
      ),
    );
  }

  /// Tree line connector
  Widget _buildTreeLine(int depth, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Text(
        isLast ? '└─ ' : '├─ ',
        style: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  /// Copy to clipboard button
  Widget _buildCopyButton(dynamic value) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 16),
      onPressed: () {
        final text = value is String ? value : jsonEncode(value);
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      },
      tooltip: 'Copy value',
      splashRadius: 16,
    );
  }

  /// Build statistics panel
  Widget _buildStatistics() {
    final stats = _calculateStats(_parsedJson);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Keys', '${stats['keys']}'),
          _statItem('Arrays', '${stats['arrays']}'),
          _statItem('Objects', '${stats['objects']}'),
          _statItem('Depth', '${stats['depth']}'),
          _statItem('Size', '${(widget.jsonString.length / 1024).toStringAsFixed(1)} KB'),
        ],
      ),
    );
  }

  /// Single stat item
  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Calculate JSON statistics
  Map<String, int> _calculateStats(dynamic value) {
    int keys = 0, arrays = 0, objects = 0, maxDepth = 0;

    void traverse(dynamic v, int depth) {
      maxDepth = (depth > maxDepth) ? depth : maxDepth;
      if (v is Map) {
        objects++;
        keys += v.length;
        v.forEach((k, val) => traverse(val, depth + 1));
      } else if (v is List) {
        arrays++;
        for (var item in v) {
          traverse(item, depth + 1);
        }
      }
    }

    traverse(value, 0);
    return {
      'keys': keys,
      'arrays': arrays,
      'objects': objects,
      'depth': maxDepth,
    };
  }

  /// Search in value recursively
  bool _searchInValue(dynamic value, String query) {
    if (value is String && value.toLowerCase().contains(query)) return true;
    if (value is Map) {
      return value.values.any((v) => _searchInValue(v, query));
    }
    if (value is List) {
      return value.any((v) => _searchInValue(v, query));
    }
    return false;
  }

  void _computeRawLines() {
    try {
      final formatted = const JsonEncoder.withIndent('  ').convert(_parsedJson);
      _rawLines = formatted.split('\n');
    } catch (e) {
      _rawLines = [_parsedJson.toString()];
    }
  }

  /// Raw JSON view — virtualized with ListView.builder for large files
  Widget _buildRawView() {
    if (_rawLines.isEmpty) {
      return const Center(child: Text('No content'));
    }
    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _rawLines.length,
        cacheExtent: 600,
        itemBuilder: (context, index) {
          return Text(
            _rawLines[index],
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              height: 1.4,
            ),
          );
        },
      ),
    );
  }
}
