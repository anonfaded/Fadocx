import 'package:flutter/material.dart';

class TextSearchResult {
  final int lineNumber;
  final String lineText;
  final int matchStart;
  final int matchLength;

  const TextSearchResult({
    required this.lineNumber,
    required this.lineText,
    required this.matchStart,
    required this.matchLength,
  });
}

class TextDocumentSearchDrawer extends StatelessWidget {
  final TextEditingController searchController;
  final List<TextSearchResult> results;
  final int activeResultIndex;
  final bool isSearching;
  final int linesChecked;
  final int totalLines;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onResultTap;
  final VoidCallback onNextResult;
  final VoidCallback onPreviousResult;
  final ScrollController? scrollController;

  const TextDocumentSearchDrawer({
    super.key,
    required this.searchController,
    required this.results,
    required this.activeResultIndex,
    required this.isSearching,
    required this.linesChecked,
    required this.totalLines,
    required this.onQueryChanged,
    required this.onResultTap,
    required this.onNextResult,
    required this.onPreviousResult,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search text...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.clear, size: 20),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (searchController.text.isNotEmpty)
                    Text(
                      isSearching
                          ? 'Searching $linesChecked/$totalLines'
                          : '${results.length} result${results.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  const Spacer(),
                  if (results.isNotEmpty) ...[
                    IconButton(
                      onPressed: onPreviousResult,
                      icon: const Icon(Icons.keyboard_arrow_up),
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Previous result',
                    ),
                    Text(
                      '${activeResultIndex + 1}/${results.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    IconButton(
                      onPressed: onNextResult,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Next result',
                    ),
                  ],
                ],
              ),
              if (isSearching) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalLines == 0 ? 0 : linesChecked / totalLines,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: searchController.text.isEmpty
              ? _buildPromptState(context)
              : results.isEmpty
                  ? _buildNoResultsState(context)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final isActive = index == activeResultIndex;
                        return _buildResultRow(
                          context,
                          result: result,
                          isActive: isActive,
                          onTap: () => onResultTap(index),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPromptState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Search in document',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context, {
    required TextSearchResult result,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Line ${result.lineNumber}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHighlightedSnippet(context, result),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedSnippet(
      BuildContext context, TextSearchResult result) {
    final lineText = result.lineText;
    final start = result.matchStart.clamp(0, lineText.length);
    final end =
        (result.matchStart + result.matchLength).clamp(0, lineText.length);

    final before = lineText.substring(0, start);
    final match = lineText.substring(start, end);
    final after = lineText.substring(end);

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                match,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
