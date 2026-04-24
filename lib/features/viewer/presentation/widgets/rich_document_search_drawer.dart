import 'package:flutter/material.dart';

class RichDocumentSearchResult {
  final String targetId;
  final String label;
  final String snippet;
  final int matchStart;
  final int matchLength;

  const RichDocumentSearchResult({
    required this.targetId,
    required this.label,
    required this.snippet,
    required this.matchStart,
    required this.matchLength,
  });
}

class RichDocumentSearchDrawer extends StatelessWidget {
  final TextEditingController searchController;
  final List<RichDocumentSearchResult> results;
  final int activeResultIndex;
  final bool isSearching;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onResultTap;
  final VoidCallback onNextResult;
  final VoidCallback onPreviousResult;

  const RichDocumentSearchDrawer({
    super.key,
    required this.searchController,
    required this.results,
    required this.activeResultIndex,
    required this.isSearching,
    required this.onQueryChanged,
    required this.onResultTap,
    required this.onNextResult,
    required this.onPreviousResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  hintText: 'Search document...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: theme.colorScheme.primary,
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
                          ? 'Searching...'
                          : '${results.length} result${results.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
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
                    ),
                    Text(
                      '${activeResultIndex + 1}/${results.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: onNextResult,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: searchController.text.isEmpty
              ? _buildEmptyState(context, Icons.search, 'Search rich content')
              : results.isEmpty
                  ? _buildEmptyState(
                      context,
                      Icons.search_off,
                      isSearching ? 'Searching...' : 'No matches found',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final isActive = index == activeResultIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.15)
                                : theme.colorScheme.surface
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.3)
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onResultTap(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.label,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      result.snippet,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
