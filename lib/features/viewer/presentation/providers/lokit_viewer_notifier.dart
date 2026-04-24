import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/services/lokit_service.dart';

class LOKitViewerState {
  final bool isInitialized;
  final bool isLoading;
  final bool isRendering;
  final String? error;
  final String? fileName;
  final int currentPart;
  final int totalParts;
  final int documentWidth;
  final int documentHeight;
  final int documentType;
  final String typeName;
  final Uint8List? currentPageImage;
  final int renderedPart;
  final double renderedZoom;
  final Map<int, Uint8List> preloadedPages;

  const LOKitViewerState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isRendering = false,
    this.error,
    this.fileName,
    this.currentPart = 0,
    this.totalParts = 0,
    this.documentWidth = 0,
    this.documentHeight = 0,
    this.documentType = -1,
    this.typeName = '',
    this.currentPageImage,
    this.renderedPart = -1,
    this.renderedZoom = 0,
    this.preloadedPages = const {},
  });

  LOKitViewerState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isRendering,
    String? error,
    String? fileName,
    int? currentPart,
    int? totalParts,
    int? documentWidth,
    int? documentHeight,
    int? documentType,
    String? typeName,
    Uint8List? currentPageImage,
    int? renderedPart,
    double? renderedZoom,
    Map<int, Uint8List>? preloadedPages,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return LOKitViewerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isRendering: isRendering ?? this.isRendering,
      error: clearError ? null : (error ?? this.error),
      fileName: fileName ?? this.fileName,
      currentPart: currentPart ?? this.currentPart,
      totalParts: totalParts ?? this.totalParts,
      documentWidth: documentWidth ?? this.documentWidth,
      documentHeight: documentHeight ?? this.documentHeight,
      documentType: documentType ?? this.documentType,
      typeName: typeName ?? this.typeName,
      currentPageImage: clearImage ? null : (currentPageImage ?? this.currentPageImage),
      renderedPart: renderedPart ?? this.renderedPart,
      renderedZoom: renderedZoom ?? this.renderedZoom,
      preloadedPages: preloadedPages ?? this.preloadedPages,
    );
  }
}

class LOKitViewerNotifier extends Notifier<LOKitViewerState> {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  static bool _globalInitialized = false;

  @override
  LOKitViewerState build() {
    ref.onDispose(() {
      _closeDocument();
    });
    return const LOKitViewerState();
  }

  Future<bool> initialize() async {
    if (_globalInitialized) {
      state = state.copyWith(isInitialized: true);
      return true;
    }
    try {
      final ok = await LOKitService.init();
      if (ok) {
        _globalInitialized = true;
        state = state.copyWith(isInitialized: true);
      }
      return ok;
    } catch (e) {
      _log.e('LOKit init failed', error: e);
      state = state.copyWith(error: 'Failed to initialize: $e');
      return false;
    }
  }

  Future<bool> loadDocument(String filePath, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true, fileName: name);
    try {
      if (!_globalInitialized) {
        final ok = await initialize();
        if (!ok) {
          state = state.copyWith(isLoading: false, error: 'Initialization failed');
          return false;
        }
      }
      final info = await LOKitService.loadDocument(filePath);
      if (info == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to load document');
        return false;
      }
      final parts = (info['parts'] as int?) ?? 1;
      final width = (info['width'] as int?) ?? 0;
      final height = (info['height'] as int?) ?? 0;
      final type = (info['type'] as int?) ?? 0;
      final tName = (info['typeName'] as String?) ?? LOKitService.getDocTypeName(type);
      state = state.copyWith(
        isLoading: false,
        totalParts: parts,
        documentWidth: width,
        documentHeight: height,
        documentType: type,
        typeName: tName,
        currentPart: 0,
      );
      return true;
    } catch (e) {
      _log.e('Load document failed', error: e);
      state = state.copyWith(isLoading: false, error: 'Failed to load: $e');
      return false;
    }
  }

  Future<void> renderCurrentPage({int maxWidth = 1080, int maxHeight = 1920}) async {
    if (state.isRendering) return;
    final part = state.currentPart;
    final preloaded = getPreloadedPage(part);
    if (preloaded != null) {
      state = state.copyWith(
        isRendering: false,
        currentPageImage: preloaded,
        renderedPart: part,
      );
      preloadAdjacentPages();
      return;
    }
    state = state.copyWith(isRendering: true);
    try {
      final pngBytes = await LOKitService.renderPageHighQuality(
        part: part,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        scale: 2.0,
      );
      if (pngBytes != null) {
        final pages = Map<int, Uint8List>.from(state.preloadedPages);
        pages[part] = pngBytes;
        state = state.copyWith(
          isRendering: false,
          currentPageImage: pngBytes,
          renderedPart: part,
          preloadedPages: pages,
        );
        preloadAdjacentPages();
      } else {
        state = state.copyWith(isRendering: false, error: 'Rendering returned null');
      }
    } catch (e) {
      _log.e('Render failed', error: e);
      state = state.copyWith(isRendering: false, error: 'Render failed: $e');
    }
  }

  Future<void> goToPart(int index) async {
    if (index < 0 || index >= state.totalParts || index == state.currentPart) return;
    final preloaded = getPreloadedPage(index);
    if (preloaded != null) {
      state = state.copyWith(
        currentPart: index,
        currentPageImage: preloaded,
        renderedPart: index,
        preloadedPages: state.preloadedPages,
      );
      preloadAdjacentPages();
      return;
    }
    state = state.copyWith(currentPart: index, clearImage: true);
    await renderCurrentPage();
  }

  Future<void> nextPage() async {
    if (state.currentPart < state.totalParts - 1) {
      await goToPart(state.currentPart + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.currentPart > 0) {
      await goToPart(state.currentPart - 1);
    }
  }

  Uint8List? getPreloadedPage(int part) {
    if (state.preloadedPages.containsKey(part)) {
      return state.preloadedPages[part];
    }
    return null;
  }

  Future<void> preloadAdjacentPages() async {
    final current = state.currentPart;
    final total = state.totalParts;
    final pages = Map<int, Uint8List>.from(state.preloadedPages);
    pages.removeWhere((k, _) => (k - current).abs() > 2);

    final toPreload = <int>[];
    if (current + 1 < total && !pages.containsKey(current + 1)) {
      toPreload.add(current + 1);
    }
    if (current - 1 >= 0 && !pages.containsKey(current - 1)) {
      toPreload.add(current - 1);
    }
    if (current + 2 < total && !pages.containsKey(current + 2)) {
      toPreload.add(current + 2);
    }

    for (final part in toPreload) {
      try {
        final pngBytes = await LOKitService.renderPageHighQuality(
          part: part,
          maxWidth: 1080,
          maxHeight: 1920,
          scale: 2.0,
        );
        if (pngBytes != null) {
          pages[part] = pngBytes;
          if (!state.isRendering) {
            state = state.copyWith(preloadedPages: pages);
          }
        }
      } catch (_) {}
    }
    state = state.copyWith(preloadedPages: pages);
  }

  Future<String> extractAllText() async {
    final total = state.totalParts;
    if (total <= 0) return '';
    if (total == 1) {
      return LOKitService.extractText();
    }
    final buffer = StringBuffer();
    for (int i = 0; i < total; i++) {
      final text = await LOKitService.extractPartText(part: i);
      if (text.isNotEmpty) {
        if (i > 0) buffer.writeln();
        buffer.writeln('--- Slide ${i + 1} ---');
        buffer.write(text);
      }
    }
    return buffer.toString();
  }

  void _closeDocument() {
    if (_globalInitialized) {
      LOKitService.closeDocument();
    }
  }

  static void destroyGlobal() {
    if (_globalInitialized) {
      LOKitService.destroy();
      _globalInitialized = false;
    }
  }
}

final lokitViewerProvider = NotifierProvider.autoDispose<LOKitViewerNotifier, LOKitViewerState>(
  LOKitViewerNotifier.new,
);
