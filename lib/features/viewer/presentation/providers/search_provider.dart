import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search state for document viewer
class SearchState {
  final String? query;
  final int totalMatches;
  final int currentIndex;
  final List<int> matchPositions;

  SearchState({
    this.query,
    this.totalMatches = 0,
    this.currentIndex = 0,
    this.matchPositions = const [],
  });

  SearchState copyWith({
    String? query,
    int? totalMatches,
    int? currentIndex,
    List<int>? matchPositions,
  }) {
    return SearchState(
      query: query ?? this.query,
      totalMatches: totalMatches ?? this.totalMatches,
      currentIndex: currentIndex ?? this.currentIndex,
      matchPositions: matchPositions ?? this.matchPositions,
    );
  }
}

/// Search state notifier
class SearchStateNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => SearchState();

  void search(String content, String query) {
    if (query.isEmpty) {
      state = SearchState();
      return;
    }

    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final matches = <int>[];
    int startIndex = 0;

    while (true) {
      final index = lowerContent.indexOf(lowerQuery, startIndex);
      if (index == -1) break;

      matches.add(index);
      startIndex = index + 1;
    }

    state = SearchState(
      query: query,
      totalMatches: matches.length,
      currentIndex: 0,
      matchPositions: matches,
    );
  }

  void nextMatch() {
    if (state.totalMatches == 0) return;
    final nextIndex = (state.currentIndex + 1) % state.totalMatches;
    state = state.copyWith(currentIndex: nextIndex);
  }

  void previousMatch() {
    if (state.totalMatches == 0) return;
    final prevIndex =
        (state.currentIndex - 1 + state.totalMatches) % state.totalMatches;
    state = state.copyWith(currentIndex: prevIndex);
  }

  void clearSearch() {
    state = SearchState();
  }
}

/// Search provider for document viewer
final searchProvider = NotifierProvider<SearchStateNotifier, SearchState>(() {
  return SearchStateNotifier();
});
